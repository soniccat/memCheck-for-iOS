//
//  NSObject+memCheck.h
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import <Foundation/Foundation.h>

@interface NSObject (memCheck) 

+ (void) turnMemCheckOn;
+ (void) turnMemCheckOff;

+ (id) myAllocFunc;
- (void) myDeallocFunc;

@end

#endif