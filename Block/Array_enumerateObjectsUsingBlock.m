//
//  Array_enumerateObjectsUsingBlock.m
//  Block
//
//  Created by f.li on 16/7/18.
//  Copyright © 2016年 lijianfei. All rights reserved.
//

#import "Array_enumerateObjectsUsingBlock.h"

@implementation Array_enumerateObjectsUsingBlock

- (void)main
{
    // NSArray * array = @[@1,@2,@3];
    _array = @[@1,@2,@3];
    
    [_array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (idx == 1)
        {
            _number = obj;
        }
        
    }];
}

@end
