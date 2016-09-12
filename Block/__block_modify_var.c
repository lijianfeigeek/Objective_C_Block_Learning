//
//  __block_modify_var.c
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#include <stdio.h>

int __block_modify_var()
{
    __block int a;
    
    ^{
        a = 10;
    }();
    
    return 0;
}