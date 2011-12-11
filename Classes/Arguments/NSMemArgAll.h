//
//  NSMemArgAll.h
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON
#import <Foundation/Foundation.h>
#import "NSMemCheckParser.h"

@interface NSMemArgAll : NSObject <NSMemCheckParseArgument>
{
    
}

@end
#endif