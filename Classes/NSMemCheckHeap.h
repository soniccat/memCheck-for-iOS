//
//  NSMemCheckHeap.h
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 29.10.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMemCheckHeap : NSObject
{
    NSDate* date;
    NSString* name;
}

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *name;

- (id)initWithDate:(NSDate*)aDate name:(NSString*)aName;

+ (void) markHeapWithName:(NSString*)heapName;
+ (void) markHeap;

@end
