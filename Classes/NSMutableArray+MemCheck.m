//
//  NSMutableArray+MemCheck.m
//  inFoundation
//
//  Created by Alexey Glushkov on 20.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import "NSMutableArray+MemCheck.h"

extern NSMutableArray* heaps;

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

- (NSString*) top:(NSInteger)top
{
	NSInteger count = top;
	if( count > [self count] )
		count = [self count];
	
	NSMutableString* outString = [NSMutableString stringWithFormat:@"%d items\n",[self count]];
	for (int i=0;i<count;++i) 
		[outString appendFormat:@"%@\n",[[self objectAtIndex:i] description]];
	
	return outString;
}

- (void) markHeap
{
	@synchronized( [NSObject class] )
	{
		[heaps addObject:[NSDate date]];
	}
}

- (NSArray*) objectsForHeap:(NSInteger)index
{
	if( index < 0 || index >= [heaps count] )
		return [NSString stringWithFormat: @"Wrong heap index, now have %d heaps", [heaps count]];
	
	NSMutableArray* returnArray = [NSMutableArray array];
	
	NSDate* currentDate = [heaps objectAtIndex:index];
	NSDate* nextDate = nil;
	if( index+1 < [heaps count] )
		nextDate = [heaps objectAtIndex:index+1];
	
	for( NSMemCheckObject* item in self )
	{
		if( [currentDate compare:item.allocDate] != NSOrderedDescending && 
		    (nextDate == nil || [nextDate compare:item.allocDate] != NSOrderedAscending) )
		{
			[returnArray addObject:item];
		}
	}
	
	return returnArray;
}

- (NSString*) showHeaps
{
	if( ![heaps count] )
		return @"No heaps, print \"po [heaps markHeap]\" to create one";
	
	NSMutableString* returnString = [NSMutableString string];
	
	NSArray* objects;
	for( int i=0; i<[heaps count]; ++i)
	{
		objects = [self objectsForHeap:i];
		
		[returnString appendString:[NSString stringWithFormat:@"%d: %d objects\n",i,[objects count]]];
	}
	
	return returnString;
}

- (NSArray*) objectsWithLiveOwner
{
    NSMutableArray* result = [NSMutableArray array];
    
    for( NSMemCheckObject* obj in self )
    {
        BOOL haveLiveOwner = NO;
        for( NSMemCheckOwnerInfo* owner in obj.owners )
        {
            if( !owner.object.isDead )
            {
                haveLiveOwner = YES;
                break;
            }
        }
        
        if(haveLiveOwner)
            [result addObject:obj];
    }
    
    return result;
}

- (NSArray*) objectsWithoutLiveOwner
{
    NSMutableArray* result = [NSMutableArray array];
    
    for( NSMemCheckObject* obj in self )
    {
        BOOL haveLiveOwner = NO;
        for( NSMemCheckOwnerInfo* owner in obj.owners )
        {
            if( !owner.object.isDead )
            {
                haveLiveOwner = YES;
                break;
            }
        }
        
        if(!haveLiveOwner)
            [result addObject:obj];
    }
    
    return result;
}

@end

#endif
