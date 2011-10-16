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
	return [NSString stringWithFormat:@"%@\n%@\n", [self.date description], [self.callStack description]];
}

- (void)dealloc
{
	self.date = nil;
	self.callStack = nil;
	
	[super dealloc];
}

@end



@implementation NSMemCheckOwnerInfo : NSObject 

@synthesize propertyName;
@synthesize object;

- (id)initWithPropertyName:(NSString*)aPropertyName object:(NSMemCheckObject*)anObject 
{
    self = [super init];
    if (self) {
        self.propertyName = aPropertyName;
        self.object = anObject;
    }
    return self;
}

+ (id)memCheckOwnerInfoWithPropertyName:(NSString*)aPropertyName object:(NSMemCheckObject*)anObject  
{
    id result = [[[self class] alloc] initWithPropertyName:aPropertyName object:anObject];
    
    return [result autorelease];
}


- (NSString*)description
{    
    return [NSString stringWithFormat:@"(%@ %@)", self.propertyName, self.object];
}


- (void)dealloc
{
    self.propertyName = nil;
    self.object = nil;
    
    [super dealloc];
}

@end


@implementation NSMemCheckObject

@synthesize pointerValue;
@synthesize className;
@synthesize owners;
@synthesize allocDate;
@synthesize allocCallStack;
@synthesize retainCallStackArray;
@synthesize releaseCallStackArray;
@synthesize autoreleaseCallCount;
@synthesize isDead;

- (id)initWithPointer:(id)obj
{
	if( (self = [super init]) )
	{
		self.pointerValue = obj;
		self.className = [[obj class] description];
		self.allocDate = [NSDate date];
		self.retainCallStackArray = [NSMutableArray array];
		self.releaseCallStackArray = [NSMutableArray array];
        self.owners = [NSMutableArray array];
	}
	
	return self;
}

- (NSString*)description
{
    NSString* ownerClassNameString = nil;
    if([self.owners count])
    {
        if([self.owners count] == 1)
            ownerClassNameString = [NSString stringWithFormat:@"\n\towner %@\n", [self.owners objectAtIndex:0]];
        else
            ownerClassNameString = [NSString stringWithFormat:@"owner %d", [self.owners count]];
    }else
        ownerClassNameString = @"";
    
    NSString* autoreleasesCountString = nil;
    if(self.autoreleaseCallCount)
        autoreleasesCountString = [NSString stringWithFormat:@"autoreleases %d", self.autoreleaseCallCount];
    else
        autoreleasesCountString = @"";
    
    NSString* isDeadString = nil;
    if( self.isDead )
        isDeadString = @"DEAD";
    else
        isDeadString = [NSString stringWithFormat:@"(%d,%d)",[self.retainCallStackArray count], [self.releaseCallStackArray count]];
    
    /*
    NSString* isDeadString = nil;
    if([self.retainCallStackArray count] < [self.releaseCallStackArray count])
        isDeadString = @"(DEAD)";
    else
        isDeadString = [NSString stringWithFormat:@"(%d,%d)",[self.retainCallStackArray count], [self.releaseCallStackArray count]];
    */
    
    return [NSString stringWithFormat:@"%@ memCheckObject %p object %p stack %p %@ %@ %@ %@", self.allocDate, self, self.pointerValue, self.allocCallStack, isDeadString, self.className, autoreleasesCountString, ownerClassNameString /*, isDeadString*/ ];
}

- (void)dealloc
{
	self.pointerValue = nil;
	self.className = nil;
	self.retainCallStackArray = nil;
	self.releaseCallStackArray = nil;
	self.allocDate = nil;
	self.allocCallStack = nil;
    self.owners = nil;
	
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
	
	while (retainIndex < retainCount || releaseIndex < releaseCount) 
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

- (void)addOwner:(NSMemCheckOwnerInfo*)ownerInfo
{
    for( NSMemCheckOwnerInfo* memInfo in self.owners )
        if( memInfo.object.pointerValue == ownerInfo.object.pointerValue )
            return;

    [self.owners addObject:ownerInfo];
}

/*
- (void)removeOwnerByObjData:(NSMemCheckObject*)objInfo
{
    for( NSMemCheckOwnerInfo* memInfo in self.owners )
    {
        if( memInfo.object == objInfo )
            memInfo.isDead = YES;
    }
}

- (void)removeOwnerByPtr:(id)obj
{
    for( NSMemCheckOwnerInfo* memInfo in self.owners )
    {
        if( memInfo.object.pointerValue == obj )
            memInfo.isDead = YES;
    }
}
*/

@end

#endif


