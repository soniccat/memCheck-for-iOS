//
//  NSAddObject.h
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import <Foundation/Foundation.h>

@interface NSMemCheckRetainReleaseInfo : NSObject
{
	NSDate* date;
	NSArray* callStack;
}

@property(nonatomic,retain) NSDate* date;
@property(nonatomic,retain) NSArray* callStack;

@end


@interface NSMemCheckObject : NSObject 
{
	id pointerValue;
	NSString* className;
	
	NSDate* allocDate;
	NSArray* allocCallStack;
	NSMutableArray* retainCallStackArray;	//contains NSMemCheckRetainReleaseInfo
	NSMutableArray* releaseCallStackArray;	//contains NSMemCheckRetainReleaseInfo
}

@property(nonatomic,assign) id pointerValue;
@property(nonatomic,retain) NSString* className;
@property(nonatomic,retain) NSDate* allocDate;
@property(nonatomic,retain) NSArray* allocCallStack;
@property(nonatomic,retain) NSMutableArray* retainCallStackArray;
@property(nonatomic,retain) NSMutableArray* releaseCallStackArray;

- (id)initWithPointer:(id)obj;
- (NSString*) retains;
- (NSString*) releases;
- (NSString*) history;

@end

#endif


