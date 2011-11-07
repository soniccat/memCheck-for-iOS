//
//  NSMemCommandPrint.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import "NSMemCommandSaveGraph.h"
#import "NSArray+MemCheck.h"

@interface NSMemCommandSaveGraph()

@property(nonatomic,retain) NSString* path;

@end


@implementation NSMemCommandSaveGraph

@synthesize inputMemCheckObjects;
@synthesize path;

- (void)run
{
    [self.inputMemCheckObjects saveGraphWithPath:self.path];
}

- (BOOL)canParse:(NSArray*)strings
{
    if( [strings count] < 2 )
        return NO;
    
    if( [[strings objectAtIndex:0] isEqualToString:@"saveGraph"] )
        return YES;
    
    return NO;
}

- (NSInteger)parse:(NSArray*)strings
{
    NSAssert( [self canParse:strings], @"need call canParse before");
    self.path = [strings objectAtIndex:1];
    
    return 2;
}

- (void)dealloc
{
    self.path = nil;
    
    [super dealloc];
}

@end
