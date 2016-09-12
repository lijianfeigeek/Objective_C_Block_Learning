//
//  capture_global_var_effect_block.c
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#include <stdio.h>

// 全局变量

// 全局静态
static int a;
// 全局
int b;

int capture_global_var_effect_block()
{
    ^{
        a = 10;
        b = 10;
    }();
    
    return 0;
}