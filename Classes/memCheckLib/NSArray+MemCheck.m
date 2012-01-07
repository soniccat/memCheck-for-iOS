//
//  NSArray+MemCheck.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#ifdef MEMTEST_ON

#import "NSArray+MemCheck.h"
#import "NSObject+MemCheck.h"
#import "NSMemCheckObject.h"
#import "NSMemCheckHeap.h"
#import "NSMemCheckDotSupport.h"

extern NSMutableArray* heaps;

typedef BOOL (^MemCheckArrayFilterBlock)(NSMemCheckObject* obj);


@interface NSArray()

- (NSArray*) filterMemObjArray:(MemCheckArrayFilterBlock) filter;

@end


@implementation NSArray(MemCheck)

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

- (NSString*) stringWithMemCheckObjects
{
    NSMutableString* resultString = nil;
    
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        resultString = [NSMutableString string];
        
        @try
        {
            for( NSMemCheckObject* obj in self )
                [resultString appendFormat:@"%@\n",[obj description]];
            
        }
        @catch (NSException* e) {
            NSLog(@"Exception: %@", [e description]);
        }
        
        [NSObject turnMemCheckOn];
    }
    
    return resultString;
}

- (NSArray*) objectsForHeap:(NSInteger)index
{
    NSMutableArray* returnArray = nil;
    
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        if( index < 0 || index >= [heaps count] )
        {
            NSLog(@"Wrong heap index, now have %d heaps", [heaps count]);
            return nil;
        }
        
        returnArray = [NSMutableArray array];
        
        @try
        {
            NSMemCheckHeap* currentHeap = [heaps objectAtIndex:index];
            NSMemCheckHeap* nextHeap = nil;
            if( index+1 < [heaps count] )
                nextHeap = [heaps objectAtIndex:index+1];
            
            for( NSMemCheckObject* item in self )
            {
                if( [currentHeap.date compare:item.allocDate] != NSOrderedDescending && 
                   (nextHeap == nil || [nextHeap.date compare:item.allocDate] != NSOrderedAscending) )
                {
                    [returnArray addObject:item];
                }
            }
        }
        @catch (NSException* e) 
        {
            NSLog(@"Exception: %@", [e description]);
        }
        
        [NSObject turnMemCheckOn];
	}
	
	return returnArray;
}

- (NSArray*) filterMemObjArray:(MemCheckArrayFilterBlock) filter
{
    NSMutableArray* resultArray = nil;
    
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        resultArray = [NSMutableArray array];
        
        @try
        {
            for( NSMemCheckObject* obj in self )
            {
                if( filter(obj) )
                    [resultArray addObject:obj];
            }
        }
        @catch (NSException* e) 
        {
            NSLog(@"Exception: %@", [e description]);
        }
        
        [NSObject turnMemCheckOn];
    }
    
    return resultArray;
}

- (NSArray*) objectsWithOwnersLessThan:(NSInteger)value
{    
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
            {
                return (BOOL)([obj.owners count] < value);
            }];
}

- (NSArray*) objectsWithLiveOwner
{    
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
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
                
                return haveLiveOwner;
            }];
}

- (NSArray*) objectsWithoutLiveOwner
{
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
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
                
                return (BOOL)(!haveLiveOwner);
            }];
}

- (NSArray*) objectsWithOwners
{   
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
            {
                return (BOOL)[obj.owners count];
            }];
}

- (NSArray*) objectsWithoutOwners
{
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
            {
                return (BOOL)![obj.owners count];
            }];
}

- (NSArray*) objectsWithoutClass:(NSString*)className
{
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
            {
                return (BOOL)![obj.className isEqualToString:className];
            }];
}

- (NSArray*) objectsWithClassFromSet:(NSSet*)classSet
{
    return [self filterMemObjArray:^(NSMemCheckObject* obj)
            {
                return (BOOL)[classSet containsObject:obj.className];
            }];
}

#pragma mark - Save Graph


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

- (void) saveGraphWithPath:(NSString*)path
{
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        @try
        {
            NSMutableArray* allObjects = [NSMutableArray arrayWithArray:self];//[self arrayByAddingObjectsFromArray:removedMemData];
            NSMutableArray* allDates = [NSMutableArray array];
            
            for(NSMemCheckObject* obj in self)
            {
                [self appendToArray:allDates datesFromObject:obj];
                [self appendToArray:allObjects objectWithOwners:obj];
            }
            
            for( NSMemCheckHeap* heap in heaps )
                [allDates addObject: heap.date];
            
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
            while(currentChunk*sizeOfChunk < [allDates count] )
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
            
            //heap's ranks
            for( NSMemCheckHeap* heap in heaps )
            {
                NSString* dateName = [NSMemCheckDotSupport variableNameFromDate:heap.date];
                [outString appendFormat:@"{ rank = same; %@; %@; }\n", dateName, [NSMemCheckDotSupport variableNameFromMemCheckHeap:heap]];
            }
            
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
            
            //select heaps
            for( NSMemCheckHeap* heap in heaps )
            {
                [outString appendFormat:@"%@ [style=filled,shape=hexagon,color=\"pink\"];\n", [NSMemCheckDotSupport variableNameFromMemCheckHeap:heap] ];
            }
            
            [visitedObjects release];
            
            [outString appendString:@"}\n"];
            
            NSError* err = nil;
            [outString writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&err];
            
            if(err)
                NSLog(@"error %@: %@",path, [err description]);
            else
                NSLog(@"graph was exported");
        }
        @catch (NSException* e) 
        {
            NSLog(@"Exception: %@", [e description]);
        }
        
        [NSObject turnMemCheckOn];
    }
}

/*
- (void)saveGraphInHomeWithName:(NSString*)name
{
    [self saveGraphInFolder:@"~/" withName:name];
}
*/

- (NSString*) showHeaps
{
	if( ![heaps count] )
		return @"No heaps, print \"po [heaps markHeap]\" to create one";
	
	NSMutableString* returnString = [NSMutableString string];
    [returnString appendString:@"\n"];
	
	NSArray* objects;
	for( int i=0; i<[heaps count]; ++i)
	{
        NSMemCheckHeap* heap = (NSMemCheckHeap*)[heaps objectAtIndex:i];
		objects = [self objectsForHeap:i];
		
		[returnString appendString:[NSString stringWithFormat:@"%d: %@: %d objects\n", i, [heap description], [objects count]]];
	}
	
	return returnString;
}

@end

#endif