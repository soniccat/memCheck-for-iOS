//
//  NSMutableArray+MemCheck.m
//  inFoundation
//
//  Created by Alexey Glushkov on 20.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import "NSMutableArray+MemCheck.h"
#import "NSMemCheckDotSupport.h"
#import "NSObject+MemCheck.h"
#import "NSMemCheckHeap.h"
#import "NSArray+MemCheck.h"

extern NSMutableArray* heaps;

#warning need remove that
extern NSMutableArray* memData;
extern NSMutableArray* removedMemData;

@implementation NSMutableArray(MemCheck)

- (NSMemCheckObject*) memCheckObjectByPointer:(id)obj
{
	for(NSMemCheckObject* item in self)
		if( item.pointerValue == obj )
			return item;
	
	return nil;
}

- (NSString*) allMem
{
	return [NSString stringWithFormat:@"%d items\n%@", [self count], [self description]];
}

- (NSArray*) top:(NSInteger)top
{
	NSInteger count = top;
	if( count > [self count] )
		count = [self count];
	
    return [[self subarrayWithRange:NSMakeRange(0, count)] mutableCopy];
}

/*
- (void)saveGraphAfterDelayInFolder:(NSString*)folderPath withName:(NSString*)name
{
    NSInvocation* invoke = [[[NSInvocation alloc] init] autorelease];
    [invoke setTarget:self];
    [invoke setSelector:@selector(saveGraphInFolder: withName:)];
    [invoke setArgument:folderPath atIndex:0];
    [invoke setArgument:name atIndex:1];
    
    [NSTimer scheduledTimerWithTimeInterval:1 invocation:invoke repeats:NO];
}

- (void)runCommandAfterDelay:(NSString*) command
{
    @synchronized([NSObject class])
    {
        [NSObject turnMemCheckOff];
    
        [[[memData objectsWithOwners] objectsWithOwnersLessThan:5] saveGraphInFolder:@"/Users/alexeyglushkov/Documents/dot" withName:@"mem.txt"];
        
        [NSObject turnMemCheckOn];
    }
}

- (void)run:(NSString*)command
{
    [self performSelector:@selector(runCommandAfterDelay:) withObject:command afterDelay:1];
}
*/

@end

#endif
