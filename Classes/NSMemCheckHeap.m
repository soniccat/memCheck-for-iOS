//
//  NSMemCheckHeap.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 29.10.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON
#import "NSMemCheckHeap.h"
#import "NSObject+MemCheck.h"

NSMutableArray* heaps;


@implementation NSMemCheckHeap

@synthesize date;
@synthesize name;

- (id)initWithDate:(NSDate*)aDate name:(NSString*)aName 
{
    self = [super init];
    if (self) {
        self.date = aDate;
        self.name = aName;
    }
    return self;
}

- (void)dealloc
{
    [date release];
    date = nil;
    [name release];
    name = nil;
    
    [super dealloc];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"Heap %@ %@", self.name, self.date];
}

+ (void) markHeapWithName:(NSString*)heapName
{
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        @try
        {
            NSMemCheckHeap* heap = [[[NSMemCheckHeap alloc] initWithDate:[NSDate date] name:heapName] autorelease];
            [heaps addObject: heap];
        }
        @catch (NSException* e) 
        {
            NSLog(@"Exception: %@", [e description]);
        }
        
        [NSObject turnMemCheckOn];
	}
}

+ (void) markHeap
{
    [self markHeapWithName:[NSString stringWithFormat:@"%d", [heaps count]]];
}

@end
#endif