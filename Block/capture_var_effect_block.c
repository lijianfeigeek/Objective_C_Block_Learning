//
//  capture_var_effect_block.c
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#include <stdio.h>

// 局部变量

int capture_var_effect_block_Main()
{
    
    int a;
    ^{a;};
    
    // 报错  var is not assignable(missing __block type specifier)
//    ^{a = 10;};
    
    return 0;
}

//int test()
//{
//    int a = 0;
//    // 利用指针p存储a的地址
//    int *p = &a;
//    
//    ^{
//        // 通过a的地址设置a的值
//        *p = 10;
//    }();
//    
//    // 变量a的生命周期是和方法test的栈相关联的，当test运行结束，栈随之销毁，那么变量a就会被销毁，p也就成为了野指针。如果block是作为参数或者返回值，这些类型都是跨栈的，也就是说再次调用会造成野指针错误。
//    
//    
//    
//    return 0;
//}
