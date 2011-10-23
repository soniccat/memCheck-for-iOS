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

- (void)appendToArray:(NSMutableArray*)array datesFromObject:(NSMemCheckObject*)memObj
{
    if( ![array containsObject:memObj.allocDate] )
        [array addObject:memObj.allocDate];
    
    if( memObj.deadDate )
    if( ![array containsObject:memObj.deadDate] )
    {
        [array addObject:memObj.deadDate];
    }
    
    for( NSMemCheckOwnerInfo* ownerInfo in memObj.owners )
    {
        [self appendToArray:array datesFromObject:ownerInfo.object];
    }
}

- (void)appendToArray:(NSMutableArray*)array objectWithOwners:(NSMemCheckObject*)memObj
{
    if( ![array containsObject:memObj] )
        [array addObject:memObj];
    
    for( NSMemCheckOwnerInfo* ownerInfo in memObj.owners )
        [self appendToArray:array objectWithOwners:ownerInfo.object];
}

- (void)appendToString:(NSMutableString*)string ownerRelationshipForObject:(NSMemCheckObject*)memObj visitedObjects:(NSMutableArray*)visitedObjects
{   
    if( [visitedObjects containsObject:memObj] )
        return;
    [visitedObjects addObject:memObj];
    
    for( NSMemCheckOwnerInfo* ownerInfo in memObj.owners )
    {
        if(ownerInfo.object.isDead)
            [string appendFormat:@"%@ [style=filled,color=\"gray\"];\n", [NSMemCheckDotSupport variableNameFromMemCheckObject:ownerInfo.object]];
     
        [string appendFormat:@"%@ -> %@;\n", [NSMemCheckDotSupport variableNameFromMemCheckObject: ownerInfo.object], [NSMemCheckDotSupport variableNameFromMemCheckObject:memObj] ];
    }
    
    for( NSMemCheckOwnerInfo* ownerInfo in memObj.owners )
        [self appendToString:string ownerRelationshipForObject:ownerInfo.object visitedObjects:visitedObjects];
}

- (void) saveGraph
{
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
    
        NSMutableArray* allObjects = [NSMutableArray arrayWithArray:self];//[self arrayByAddingObjectsFromArray:removedMemData];
        NSMutableArray* allDates = [NSMutableArray array];
        
        for(NSMemCheckObject* obj in self)
        {
            [self appendToArray:allDates datesFromObject:obj];
            [self appendToArray:allObjects objectWithOwners:obj];
        }
        
        [allDates sortWithOptions:NSSortConcurrent usingComparator:^( NSDate* a, NSDate* b )
         {
             return [a compare:b];
         }];
        
        [allObjects sortWithOptions:NSSortConcurrent usingComparator:^( NSMemCheckObject* a, NSMemCheckObject* b )
         {
             if( [a.owners count] && [b.owners count] )
                 return NSOrderedSame;
             
             if([a.owners count] && ![b.owners count])
                 return NSOrderedAscending;
             
             return NSOrderedDescending;
         }];
        
        //remove doubles
        for( int i=0; i<[allDates count]; ++i )
        {
            NSDate* date = (NSDate*)[allDates objectAtIndex:i];
            for( int a=i+1; a<[allDates count]; ++a )
            {
                NSDate* subDate = [allDates objectAtIndex:a];
                if( [[NSMemCheckDotSupport variableNameFromDate:date] isEqualToString: [NSMemCheckDotSupport variableNameFromDate:subDate]] )
                {
                    [allDates removeObjectAtIndex:a];
                    --a;
                    
                }else
                    break;
            }
        }
        
        NSMutableString* outString = [NSMutableString string];
        [outString appendString:@"digraph asde91 {\n"];
        
        [outString appendString:@"ranksep=.75;\n"];
        [outString appendString:@"node [shape=box];\n"];
        
        //timeline 
        [outString appendString:@"{\n\
         node [shape=plaintext, fontsize=16];\n"];
        
        NSInteger currentChunk = 0;
        NSInteger sizeOfChunk = 50;
        
        //divide dates on chunks to prevent "memory exhausted" in dot
        while(currentChunk*sizeOfChunk < [allDates count] /*&& currentChunk != 5*/)
        {
            NSMutableArray* chunkDates = [[NSMutableArray alloc] init];
            if( currentChunk*sizeOfChunk + sizeOfChunk < [allDates count] )
                [chunkDates addObjectsFromArray: [allDates subarrayWithRange:NSMakeRange(currentChunk*sizeOfChunk, sizeOfChunk)] ];
            else
                [chunkDates addObjectsFromArray: [allDates subarrayWithRange:NSMakeRange(currentChunk*sizeOfChunk, [allDates count] - currentChunk*sizeOfChunk)] ];
            
            if(currentChunk!=0)
                [chunkDates insertObject:[allDates objectAtIndex:currentChunk*sizeOfChunk-1] atIndex:0];
        
            NSInteger i = 0;
            for( NSDate* date in chunkDates )
            {
                if(i !=0)
                {
                    [outString appendString:@" -> "];
                    
                }else
                    ++i;
                
                [outString appendString: [NSMemCheckDotSupport variableNameFromDate:date] ];
            }
            
            [outString appendString:@";\n"];
            ++currentChunk;
            
            [chunkDates release];
        }
        [outString appendString:@"\n}\n"];
        
        //ranks
        for( NSDate* date in allDates )
        {
            //NSInteger itemCount = 0;
            NSString* dateName = [NSMemCheckDotSupport variableNameFromDate:date];
            
            [outString appendFormat:@"{ rank = same; %@;", dateName];
            
            for( NSMemCheckObject* obj in allObjects )
            {
                if( [[NSMemCheckDotSupport variableNameFromDate:obj.allocDate] isEqualToString:dateName] )
                {
                    [outString appendString:@" "];
                    [outString appendString: [NSMemCheckDotSupport variableNameFromMemCheckObject:obj] ];
                    [outString appendString:@";"];
                    
                    //++itemCount;
                    //if(itemCount > 10)
                    //    break;
                }else if( obj.isDead && [[NSMemCheckDotSupport variableNameFromDate:obj.deadDate] isEqualToString:dateName] )
                {
                    [outString appendString:@" "];
                    [outString appendString: [NSMemCheckDotSupport variableDeadNameFromMemCheckObject:obj] ];
                    [outString appendString:@";"];
                }
            }
            
            [outString appendString:@"}\n"];
        }
        
        //edges
        NSMutableArray* visitedObjects = [[NSMutableArray alloc] init];
        for( NSMemCheckObject* obj in allObjects )
        {
            [self appendToString:outString ownerRelationshipForObject:obj visitedObjects:visitedObjects];
            
            if( obj.isDead )
            {
                [outString appendFormat:@"%@ [style=filled,color=\"gray\"];\n", [NSMemCheckDotSupport variableDeadNameFromMemCheckObject:obj]];
                [outString appendFormat:@"%@ -> %@ [style=dotted];", [NSMemCheckDotSupport variableNameFromMemCheckObject:obj], [NSMemCheckDotSupport variableDeadNameFromMemCheckObject:obj]];
            }
        }
        [visitedObjects release];
        
        [outString appendString:@"}\n"];
        [outString writeToFile:@"/Users/alexeyglushkov/Documents/dot/mem.txt" atomically:NO encoding:NSUTF8StringEncoding error:nil];
            
        NSLog(@"graph was exported");
        [NSObject turnMemCheckOn];
    }
}

@end

#endif
