//
//  myArray.m
//  Block
//
//  Created by f.li on 16/7/21.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "myArray.h"

@implementation myArray
- (void)myTest
{

    // @[]转为 NSArray 的 arrayWithObjects:count: 类方法
    
    //    id numbers[1];
    //    for (int x = 0; x < 1; ++x)
    //        numbers[x] = [NSNumber numberWithInt:0];
    //    NSArray *a = [NSArray arrayWithObjects:numbers count:1];
    
    NSArray *a = @[@"ddd"];
    NSLog(@"Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)a));
}

@end
