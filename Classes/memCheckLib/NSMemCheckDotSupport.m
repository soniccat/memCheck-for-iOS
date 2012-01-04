//
//  NSMemCheckDotSupport.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 23.10.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#ifdef MEMTEST_ON

#import "NSMemCheckDotSupport.h"
#import "NSMemCheckObject.h"
#import "NSMemCheckHeap.h"

@implementation NSMemCheckDotSupport

+ (NSString*)variableNameFromDate:(NSDate*)date
{
    NSString* returnString = nil;
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"\"HH:mm:ss.S\""];
    
    returnString = [[[dateFormatter stringFromDate:date] retain] autorelease];
    
    [dateFormatter release];
    
    return returnString;
}

+ (NSString*)variableNameFromMemCheckObject:(NSMemCheckObject*)obj
{
    return [NSString stringWithFormat:@"\"%@\\n%p\\n%p\"",obj.className,obj,obj.pointerValue];
}

+ (NSString*)variableDeadNameFromMemCheckObject:(NSMemCheckObject*)obj
{
    NSAssert(obj.isDead, @"variableDeadNameFromMemCheckObject was called for living object");
    
    return [NSString stringWithFormat:@"\"%@ DEAD\\n%p\\n%p\"",obj.className,obj,obj.pointerValue];
}

+ (NSString*)variableNameFromMemCheckHeap:(NSMemCheckHeap*)heap
{
    return [NSString stringWithFormat:@"\"Heap %@\"", heap.name];
}

@end

#endif
