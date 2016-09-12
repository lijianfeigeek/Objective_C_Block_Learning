//
//  no__block_modify_var.m
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "no__block_modify_var.h"

@implementation no__block_modify_var

typedef void(^Block)();

- (void)test
{
    NSObject *a = [[NSObject alloc] init];
    Block block = ^ {
        a;
    };
}

@end
