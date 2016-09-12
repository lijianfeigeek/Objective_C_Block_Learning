//
//  block_in_ARC.h
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Block)();

@interface block_in_ARC : NSObject

/** 假如有栈block赋给以下两个属性 **/

// 这里因为ARC，当栈block中会捕获外部变量时，这个block会被copy进堆中
// 如果没有捕获外部变量，这个block会变为全局类型
// 不管怎么样，它都脱离了栈生命周期的约束

@property (strong, nonatomic) Block strongBlock;

// 这里都会被copy进堆中
@property (copy, nonatomic) Block copyBlock;

+ (void)main;

+ (void)test;

+ (void)test__Block;

+(void)test_GCD__block;

+ (void)test__weak;

+ (void)blockType;

@end
