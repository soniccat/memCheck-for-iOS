//
//  NSMemFilterWithOwnersLessThan.h
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 06.11.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSMemCheckParser.h"

@interface NSMemFilterWithLiveOwners : NSObject <NSMemCheckParseFilter>
{
    NSArray* inputMemCheckObject;
}

@property(nonatomic,retain) NSArray* inputMemCheckObjects;

@end
