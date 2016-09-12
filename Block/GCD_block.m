//
//  GCD_block.m
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "GCD_block.h"

@implementation GCD_block

- (void)myTest
{
    _number = @666;
    
    dispatch_queue_t queue = dispatch_queue_create("com.f.li", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        _number = @888;
    });
}

@end
