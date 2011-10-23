//
//  NSMemCheckDotSupport.h
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 23.10.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMemCheckObject;

@interface NSMemCheckDotSupport : NSObject
{
    
}

+ (NSString*)variableNameFromDate:(NSDate*)date;
+ (NSString*)variableNameFromMemCheckObject:(NSMemCheckObject*)obj;
+ (NSString*)variableDeadNameFromMemCheckObject:(NSMemCheckObject*)obj;

@end
