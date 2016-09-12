//
//  capture_local_var_effect_block.c
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#include <stdio.h>

// 局部静态变量


int capture_local_var_effect_block()
{
    static int a;
    // 静态局部变量是存储在静态数据存储区域的，也就是和程序拥有一样的生命周期，也就是说在程序运行时，都能够保证block访问到一个有效的变量。但是其作用范围还是局限于定义它的函数中，所以只能在block通过静态局部变量的地址来进行访问。
    ^{
        a = 10;
    }();
    
    return 0;
}