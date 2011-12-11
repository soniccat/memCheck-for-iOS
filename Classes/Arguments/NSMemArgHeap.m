//
//  NSMemArgAll.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON
#import "NSMemArgHeap.h"
#import "NSArray+MemCheck.h"

extern NSMutableArray* memData;

@implementation NSMemArgHeap

- (NSArray*)memCheckObjects
{
    return [memData objectsForHeap:heapNumber];
}

- (BOOL)canParse:(NSArray*)strings
{
    if( [strings count] < 2 )
        return NO;
    
    if( [[strings objectAtIndex:0] isEqualToString:@"heap"] )
    {
        return YES;
    }
    return NO;
}

- (NSInteger)parse:(NSArray*)strings
{
    NSAssert( [self canParse:strings], @"need call canParse before");
    
    heapNumber = [[strings objectAtIndex:1] integerValue];
    return 2;
}

@end
#endif