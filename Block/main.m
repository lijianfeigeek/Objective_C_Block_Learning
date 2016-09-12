//
//  main.m
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "block_in_ARC.h"
#import "block_in_MRC.h"



int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        [block_in_ARC main];
        
        [block_in_ARC test];
        
        [block_in_ARC test__Block];
        
        [block_in_ARC test_GCD__block];
        
        [block_in_ARC test__weak];
        
        [block_in_ARC blockType];
        
        [block_in_MRC main];
        
        [block_in_MRC test];
        
        [block_in_MRC test__Block];
        
        block_in_MRC* obj = [[block_in_MRC alloc] init];
        [obj test];
        
    }
    return 0;
}
