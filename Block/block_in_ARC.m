//
//  block_in_ARC.m
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "block_in_ARC.h"
#import <objc/runtime.h>

@implementation block_in_ARC

// @see https://developer.apple.com/library/mac/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html
// How do blocks work in ARC?

//  苹果文档提及，在ARC模式下，在栈间传递block时，不需要手动copy栈中的block，即可让block正常工作。主要原因是ARC对栈中的block自动执行了copy，将_NSConcreteStackBlock类型的block转换成了_NSConcreteMallocBlock的block。

+ (void)main
{
    int i = 10;
    void (^block)() = ^{i;};
    
    __weak void (^weakBlock)() = ^{i;};
    
    void (^stackBlock)() = ^{};
    
    // ARC情况下
    
    // 创建时，都会在栈中
    // <__NSStackBlock__: 0x7fff5fbff730>
    NSLog(@"%@", ^{i;});
    
    // 因为stackBlock为strong类型，且捕获了外部变量，所以赋值时，自动进行了copy
    // <__NSMallocBlock__: 0x100206920>
    NSLog(@"%@", block);
    
    // 如果是weak类型的block，依然不会自动进行copy
    // <__NSStackBlock__: 0x7fff5fbff728>
    NSLog(@"%@", weakBlock);
    
    // 如果block是strong类型，并且没有捕获外部变量，那么就会转换成__NSGlobalBlock__
    // <__NSGlobalBlock__: 0x100001110>
    NSLog(@"%@", stackBlock);
    
    // 在非ARC情况下，产生以下输出
    // <__NSStackBlock__: 0x7fff5fbff6d0>
    // <__NSStackBlock__: 0x7fff5fbff730>
    // <__NSStackBlock__: 0x7fff5fbff700>
    // <__NSGlobalBlock__: 0x1000010d0>
}

NSMutableArray *arrayM;

void myBlock()
{
    int a = 5;
    Block block = ^ {
        NSLog(@"%d", a);
    };
    
    [arrayM addObject:block];
    NSLog(@"%@", block);
}

+ (void)test
{
    arrayM = @[].mutableCopy;
    
    myBlock();
    
    Block block = [arrayM firstObject];
    // 非ARC这里崩溃
    block();
}

// ARC 中 `__block`会自动进行retain 实验
+ (void)test__Block
{
    // You can use CFGetRetainCount with Objective-C objects, even under ARC:
    NSObject *objc = [[NSObject alloc] init];
    NSLog(@"test__Block-- objc Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)objc));
    __block NSObject *objcNew = objc;
    NSLog(@"test__Block-- objc Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)objc));
}
// 输出
// test__Block-- objc Retain count is 1
// test__Block-- objc Retain count is 2

+(void)test_GCD__block
{
    dispatch_async(dispatch_queue_create("com.f.li.1", DISPATCH_QUEUE_SERIAL), ^{
        
        
        __block NSMutableArray * arrayListData = [self getArray];
        
        NSLog(@"f.li 1 Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)arrayListData));
        
        dispatch_async(dispatch_queue_create("com.f.li.2", DISPATCH_QUEUE_SERIAL), ^{
            
            [arrayListData addObject:@(2)];
//            NSLog(@"f.li %@",arrayListData);
            NSLog(@"f.li 3 Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)arrayListData));

        });
        
        NSLog(@"f.li 2 Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)arrayListData));
    });
}

+ (NSMutableArray *)getArray
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    [array addObject:@(1)];
    
    return array;
}

+ (void)test__weak
{
    NSObject *obj = [[NSObject alloc]init];
    
    NSLog(@"%@,%@",obj,NSStringFromSelector(_cmd));
    __weak NSObject *weakObj = obj;
    NSLog(@"%@,%@",weakObj,NSStringFromSelector(_cmd));
    
    void(^testBlock)() = ^(){
        NSLog(@"%@,%@",weakObj,NSStringFromSelector(_cmd));
    };
    testBlock();
    obj = nil;
    testBlock();
}

+ (void)blockType
{
    void (^block)(void) = ^(){};
    
    //所以说block也是一个NSObject对象
    Class cls = [(NSObject *)block class];
    NSLog(@"block class = %@ ,%@", cls,NSStringFromSelector(_cmd));
    
    Class objCls = [NSObject class];
    NSLog(@"NSObject class = %@ , %@", objCls,NSStringFromSelector(_cmd));
    
    NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>");
    
    while (class_getSuperclass(cls) != [NSObject class]) {
        NSLog(@"current class = %@ ,%@", cls,NSStringFromSelector(_cmd));
        cls = class_getSuperclass(cls);
        NSLog(@"super class = %@ , %@", cls,NSStringFromSelector(_cmd));
    }
}



@end
