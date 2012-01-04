//
//  NSMemCommandPrint.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON
#import "NSMemCommandShowHeaps.h"
#import "NSArray+MemCheck.h"
#import "NSMemCheckHeap.h"

extern NSMutableArray* memData;

@implementation NSMemCommandShowHeaps

@synthesize inputMemCheckObjects;

- (void)run
{
    NSLog( @"%@", [memData showHeaps] );
}

- (BOOL)canParse:(NSArray*)strings
{
    if( ![strings count] )
    return NO;

    if( [[strings objectAtIndex:0] isEqualToString:@"showHeaps"] )
        return YES;

    return NO;
}

- (NSInteger)parse:(NSArray*)strings
{
    NSAssert( [self canParse:strings], @"need call canParse before");
    return 1;
}


@end
#endif