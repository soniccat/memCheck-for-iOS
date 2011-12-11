//
//  NSMemCommandPrint.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON
#import "NSMemCommandPrint.h"
#import "NSArray+MemCheck.h"

@implementation NSMemCommandPrint

@synthesize inputMemCheckObjects;

- (void)run
{
    NSLog( @"%@", [self.inputMemCheckObjects stringWithMemCheckObjects] );
}

- (BOOL)canParse:(NSArray*)strings
{
    if( ![strings count] )
    return NO;

    if( [[strings objectAtIndex:0] isEqualToString:@"print"] )
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