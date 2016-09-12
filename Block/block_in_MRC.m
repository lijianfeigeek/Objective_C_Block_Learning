//
//  block_in_MRC.m
//  Block
//
//  Created by f.li on 16/7/21.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "block_in_MRC.h"


@interface block_in_MRC ()
{
    NSObject* _instanceObj;
}
@property (nonatomic, copy) void(^myBlock)(void);


@end

typedef long (^BlkSum)(int, int);
NSObject* __globalObj = nil;


@implementation block_in_MRC
+ (void)main
{
    BlkSum blk1 = ^ long (int a, int b) {
        return a + b;
    };
    NSLog(@"blk1 = %@", blk1);// blk1 = <__NSGlobalBlock__: 0x47d0>
    
    
    int base = 100;
    BlkSum blk2 = ^ long (int a, int b) {
        return base + a + b;
    };
    NSLog(@"blk2 = %@", blk2); // blk2 = <__NSStackBlock__: 0xbfffddf8>
    
    BlkSum blk3 = [[blk2 copy] autorelease];
    NSLog(@"blk3 = %@", blk3); // blk3 = <__NSMallocBlock__: 0x902fda0>
}

+ (void)test
{
    int base = 100;
    BlkSum blk2 = ^ long (int a, int b) {
        return base + a + b;
    };
    NSLog(@"blk2 = %@", blk2); // blk2 = <__NSStackBlock__: 0xbfffddf8>
    
    BlkSum blk3 = [[[[[blk2 copy] copy] copy] copy] copy];
    NSLog(@"blk3 = %@", blk3); // blk3 = <__NSMallocBlock__: 0x902fda0>
    NSLog(@"blk3 retainCount = %@", @([blk3 retainCount]));// blk3 retainCount = 1

    
    BlkSum blk4 = [blk2 copy];
    [blk4 retain];
    NSLog(@"blk4 retainCount = %@", @([blk4 retainCount]));// blk4 retainCount = 1
    [blk4 release];
    NSLog(@"blk4 retainCount = %@", @([blk4 retainCount]));// blk4 retainCount = 1
}


- (id) init {
    if (self = [super init]) {
        _instanceObj = [[NSObject alloc] init];
    }
    return self;
}

- (void) test {
    static NSObject* __staticObj = nil;
    __globalObj = [[NSObject alloc] init];
    __staticObj = [[NSObject alloc] init];
    
    NSObject* localObj = [[NSObject alloc] init];
    __block NSObject* blockObj = [[NSObject alloc] init];
    
    typedef void (^MyBlock)(void) ;
    MyBlock aBlock = ^{
        NSLog(@"%@", __globalObj);
        NSLog(@"%@", __staticObj);
        NSLog(@"%@", _instanceObj);
        NSLog(@"%@", localObj);
        NSLog(@"%@", blockObj);
    };
    aBlock = [[aBlock copy] autorelease];
    aBlock();
    
    NSLog(@"%ld", [__globalObj retainCount]);
    NSLog(@"%ld", [__staticObj retainCount]);
    NSLog(@"%ld", [_instanceObj retainCount]);
    NSLog(@"%ld", [localObj retainCount]);
    NSLog(@"%ld", [blockObj retainCount]);
    
    block_in_MRC* obj = [[[block_in_MRC alloc] init] autorelease];
    self.myBlock = ^ {
        //  obj doSomething
        [obj test];
    };
    
    
}

// 在MRC中 __block不会自动进行retain
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
// test__Block-- objc Retain count is 1



@end
