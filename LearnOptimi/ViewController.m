//
//  ViewController.m
//  LearnOptimi
//
//  Created by MacW on 2020/11/23.
//

#import "ViewController.h"
#include <stdint.h>
#include <stdio.h>
#include <sanitizer/coverage_interface.h>
#import <libkern/OSAtomic.h>
#import "LearnOptimi-Swift.h"
#import <dlfcn.h>
@interface ViewController ()

@end

@implementation ViewController
//定义原子队列
static OSQueueHead symbolList = OS_ATOMIC_QUEUE_INIT;
+(void)load {
//    NSLog(@"123");
    [TestSwift testSwift];
}
//定义符号结构体
typedef struct{
    void *pc;
    void *next;
} SYNode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
void testMethod(){
    NSLog(@"123");
}
void (^Block)(void) = ^{
    
};
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //定义数组
    NSMutableArray<NSString *> * symbolNames = [NSMutableArray array];
    
    while (YES) {//一次循环!也会被HOOK一次!!
       SYNode * node = OSAtomicDequeue(&symbolList, offsetof(SYNode, next));
        
        if (node == NULL) {
            break;
        }
        Dl_info info = {0};
        dladdr(node->pc, &info);
//        printf("%s \n",info.dli_sname);
        NSString * name = @(info.dli_sname);
        free(node);
        BOOL isObjc = [name hasPrefix:@"+["]||[name hasPrefix:@"-["];
        NSString * symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
        //是否去重??
        [symbolNames addObject:symbolName];

    }
    NSEnumerator * enumerator = [symbolNames reverseObjectEnumerator];
    
    //创建一个新数组
    NSMutableArray * funcs = [NSMutableArray arrayWithCapacity:symbolNames.count];
    NSString * name;
    //去重!
    while (name = [enumerator nextObject]) {
        if (![funcs containsObject:name]) {//数组中不包含name
            [funcs addObject:name];
        }
    }
    [funcs removeObject:[NSString stringWithFormat:@"%s",__FUNCTION__]];
    //数组转成字符串
    NSString * funcStr = [funcs componentsJoinedByString:@"\n"];
    //字符串写入文件
    //文件路径
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"myself.order"];
    //文件内容
    NSData * fileContents = [funcStr dataUsingEncoding:NSUTF8StringEncoding];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];

}
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                                   uint32_t *stop) {
 static uint64_t N;  // Counter for the guards.
 if (start == stop || *start) return;  // Initialize only once.
 printf("INIT: %p %p\n", start, stop);
 for (uint32_t *x = start; x < stop; x++)
   *x = ++N;  // Guards should start from 1.
}
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
//  if (!*guard) return;  // Duplicate the guard check.
  // If you set *guard to 0 this code will not be called again for this edge.
  // Now you can get the PC and do whatever you want:
  //   store it somewhere or symbolize it and print right away.
  // The values of `*guard` are as you set them in
  // __sanitizer_cov_trace_pc_guard_init and so you can make them consecutive
  // and use them to dereference an array or a bit vector.
  void *PC = __builtin_return_address(0);
    SYNode * node = malloc(sizeof(SYNode));
     *node = (SYNode){PC,NULL};
     
     //加入结构!
  OSAtomicEnqueue(&symbolList, node, offsetof(SYNode, next));
}

@end
