//
//  NSMemFilterWithOwnersLessThan.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import "NSMemFilterWithout.h"
#import "NSArray+MemCheck.h"

@interface NSMemFilterWithout()

@property(nonatomic,retain) NSString* className;

@end


@implementation NSMemFilterWithout

@synthesize className;
@synthesize inputMemCheckObjects;

- (NSArray*)outputMemCheckObjects
{
    return [inputMemCheckObjects objectsWithoutClass:self.className];
}

- (BOOL)canParse:(NSArray*)strings
{
    if( [strings count] < 2 )
        return NO;
    
    if( [[strings objectAtIndex:0] isEqualToString:@"without"] )
    {
        return YES;
    }
    return NO;
}

- (NSInteger)parse:(NSArray*)strings
{
    NSAssert( [self canParse:strings], @"need call canParse before");
    
    self.className = [strings objectAtIndex:1];
    return 2;
}

- (void)dealloc
{
    self.className = nil;
    [super dealloc];
}

@end
