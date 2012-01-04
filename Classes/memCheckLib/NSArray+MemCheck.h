//
//  NSArray+MemCheck.h
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//
#ifdef MEMTEST_ON

#import <Foundation/Foundation.h>

@class NSMemCheckObject;

@interface NSArray(MemCheck)
{
    
}

- (NSMemCheckObject*) memCheckObjectByPointer:(id)obj;

- (NSArray*) objectsWithOwnersLessThan:(NSInteger)value;
- (NSString*) stringWithMemCheckObjects;
- (NSArray*) objectsForHeap:(NSInteger)index;

- (NSArray*) objectsWithLiveOwner;
- (NSArray*) objectsWithoutLiveOwner;
- (NSArray*) objectsWithOwners;
- (NSArray*) objectsWithoutOwners;
- (NSArray*) objectsWithoutClass:(NSString*)className;
- (NSArray*) objectsWithClassFromSet:(NSSet*)classSet;

- (void) saveGraphWithPath:(NSString*)path;
- (NSString*) showHeaps;

@end

#endif