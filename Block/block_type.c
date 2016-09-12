//
//  block_type.c
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#include <stdio.h>

/*
 block中的isa指向的是该block的Class。在block runtime中，定义了6种类：
 
 _NSConcreteStackBlock     栈上创建的block
 _NSConcreteMallocBlock    堆上创建的block  @see http://opensource.apple.com/source/libclosure/libclosure-63/runtime.c 中 Block_copy_internal 方法 函数通过memmove将栈中的block的内容拷贝到了堆中，并使isa指向了_NSConcreteMallocBlock。
 _NSConcreteGlobalBlock   作为全局变量的block
 
 
 _NSConcreteWeakBlockVariable
 _NSConcreteAutoBlock
 _NSConcreteFinalizingBlock
 
 其中我们能接触到的主要是前3种，后三种用于GC不再讨论..
 */

void (^globalBlock)() = ^{
    
};


int block_type_Main()
{
    void (^stackBlock1)() = ^{
        
    };
    
    stackBlock1();
    globalBlock();
    
    return 0;
}