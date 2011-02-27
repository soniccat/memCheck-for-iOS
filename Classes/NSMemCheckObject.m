//
//  NSAddObject
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import <Foundation/Foundation.h> 
#import <objc/runtime.h>
#import <objc/message.h>
#import <objc/objc.h>

#import "NSMemCheckObject.h"


@implementation NSMemCheckRetainReleaseInfo

@synthesize date;
@synthesize callStack;

- (NSString*)description
{
	//return @"abc";
	return [NSString stringWithFormat:@"%@\n%@\n", [self.date description], [self.callStack description]];
}

- (void)dealloc
{
	self.date = nil;
	self.callStack = nil;
	
	[super dealloc];
}

@end




@implementation NSMemCheckObject

@synthesize pointerValue;
@synthesize className;
@synthesize allocDate;
@synthesize allocCallStack;
@synthesize retainCallStackArray;
@synthesize releaseCallStackArray;

- (id)initWithPointer:(id)obj
{
	if( self = [super init] )
	{
		self.pointerValue = obj;
		self.className = [[obj class] description];
		self.allocDate = [NSDate date];
		self.retainCallStackArray = [NSMutableArray array];
		self.releaseCallStackArray = [NSMutableArray array];
	}
	
	return self;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"%@ memCheckObject %p object %p stack %p %@", self.allocDate, self, self.pointerValue, self.allocCallStack, self.className];
}

- (void)dealloc
{
	self.pointerValue = nil;
	self.className = nil;
	self.retainCallStackArray = nil;
	self.releaseCallStackArray = nil;
	self.allocDate = nil;
	self.allocCallStack = nil;
	
	[super dealloc];
}

- (NSString*) retains
{
	NSInteger count = [self.retainCallStackArray count];
	//if( count > [self.retainCallStackArray count] )
	//	count = [self.retainCallStackArray count];
	
	NSMutableString* outString = [NSMutableString stringWithFormat:@"%d retain calls\n",count];
	for (int i=0;i<count;++i) 
		[outString appendFormat:@"%@\n",[[self.retainCallStackArray objectAtIndex:i] description]];
	
	return outString;
}

- (NSString*) releases
{
	NSInteger count = [self.releaseCallStackArray count];
	//if( count > [self.retainCallStackArray count] )
	//	count = [self.retainCallStackArray count];
	
	NSMutableString* outString = [NSMutableString stringWithFormat:@"%d release calls\n",count];
	for (int i=0;i<count;++i) 
		[outString appendFormat:@"%@\n",[[self.releaseCallStackArray objectAtIndex:i] description]];
	
	return outString;
}

- (NSString*) history
{
	NSMutableString* outString = [NSMutableString stringWithFormat:@"ALLOC:\n%@\n",self.allocDate];
	[outString appendFormat:@"%@\n",self.allocCallStack];
	
	int retainCount = [self.retainCallStackArray count];
	int releaseCount = [self.releaseCallStackArray count];
	
	int retainIndex = 0;
	int releaseIndex = 0;
	
	NSMemCheckRetainReleaseInfo* releaseInfo;
	NSMemCheckRetainReleaseInfo* retainInfo;
	
	while (retainIndex < retainCount && releaseIndex < retainCount) 
	{
		if( releaseIndex < releaseCount )
			releaseInfo = [self.releaseCallStackArray objectAtIndex:releaseIndex];
		else
			releaseInfo = nil;
		
		if( retainIndex < retainCount )
			retainInfo = [self.retainCallStackArray objectAtIndex:retainIndex];
		else
			retainInfo = nil;
		
		if( releaseInfo != nil && retainInfo == nil || [releaseInfo.date compare:retainInfo.date] == NSOrderedAscending )
		{
			[outString appendFormat:@"RELEASE:\n%@\n", [releaseInfo description]];
			++releaseIndex;

		}else if( retainInfo )
		{
			[outString appendFormat:@"RETAIN:\n%@\n", [retainInfo description]];
			++retainIndex;
		}
	}
	
	return outString;
}

@end

#endif


