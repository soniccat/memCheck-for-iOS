//
//  NSMemFilterWithOwnersLessThan.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import "NSMemFilterWithOwnersLessThan.h"
#import "NSArray+MemCheck.h"

@implementation NSMemFilterWithOwnersLessThan

@synthesize inputMemCheckObjects;

- (NSArray*)outputMemCheckObjects
{
    return [inputMemCheckObjects objectsWithOwnersLessThan:compareValue];
}

- (BOOL)canParse:(NSArray*)strings
{
    if( [strings count] < 2 )
        return NO;
    
    if( [[strings objectAtIndex:0] isEqualToString:@"withOwnersLessThan"] )
    {
        if( [[strings objectAtIndex:1] integerValue] != 0 )
        {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)parse:(NSArray*)strings
{
    NSAssert( [self canParse:strings], @"need call canParse before");
    compareValue = [[strings objectAtIndex:1] integerValue];
    
    return 2;
}

@end
