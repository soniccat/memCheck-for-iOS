//
//  NSMemCommandPrint.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON
#import "NSMemCommandMarkHeapWithName.h"
#import "NSArray+MemCheck.h"
#import "NSMemCheckHeap.h"

@interface NSMemCommandMarkHeapWithName()

@property(nonatomic,retain) NSString* heapName; 

@end

@implementation NSMemCommandMarkHeapWithName

@synthesize inputMemCheckObjects;
@synthesize heapName;

- (void)run
{
    [NSMemCheckHeap markHeapWithName:heapName];
    NSLog(@"Heap is created");
}

- (BOOL)canParse:(NSArray*)strings
{
    if( [strings count] < 2 )
    return NO;

    if( [[strings objectAtIndex:0] isEqualToString:@"markHeapWithName"] )
        return YES;

    return NO;
}

- (NSInteger)parse:(NSArray*)strings
{
    NSAssert( [self canParse:strings], @"need call canParse before");
    self.heapName = [strings objectAtIndex:1];
    
    return 2;
}

- (void)dealloc
{
    self.heapName = nil;
    
    [super dealloc];
}

@end
#endif