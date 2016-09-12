//
//  self_hidden_retain_cycle.m
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "self_hidden_retain_cycle.h"

@implementation self_hidden_retain_cycle

{
    int _a;
    void (^_block)();
}
- (void)test
{
    void (^_block)() = ^{
        _a = 10;
    };
}

@end
