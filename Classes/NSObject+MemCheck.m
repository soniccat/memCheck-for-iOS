//
//  NSObject+memCheck.m
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import "NSObject+memCheck.h"
#import <Foundation/Foundation.h> 
#import <objc/runtime.h>
#import <objc/message.h>
#import <objc/objc.h>
#import "NSMemCheckObject.h"
#import "NSMutableArray+MemCheck.h"

NSMutableArray* memData;

Method classAllocMethod;
IMP classAllocImp;

Method classMyAllocMethod;
IMP classMyAllocImp;

Method classDeallocMethod;
IMP classDeallocImp;

Method classMyDeallocMethod;
IMP classMyDeallocImp;

Method classRetainMethod;
IMP classRetainImp;

Method classMyRetainMethod;
IMP classMyRetainImp;

Method classReleaseMethod;
IMP classReleaseImp;

Method classMyReleaseMethod;
IMP classMyReleaseImp;


typedef id (*OverrideMemCheckPrototipe)(id,SEL);

#define ALLOC_METHOD_EXCHANGE method_exchangeImplementations(classAllocMethod, classMyAllocMethod)
#define RETAIN_METHOD_EXCHANGE method_exchangeImplementations(classRetainMethod, classMyRetainMethod)


@implementation NSObject (memCheck)

+ (void)turnMemCheckOn
{
	if( memData == nil  )
		memData = [[NSMutableArray allocWithZone:nil] init];
	
	//alloc
	classAllocMethod = class_getClassMethod([NSObject class], @selector(alloc) );
	classAllocImp = method_getImplementation(classAllocMethod);
	
	classMyAllocMethod = class_getClassMethod([NSObject class], @selector(myAllocFunc) );
	classMyAllocImp = method_getImplementation(classMyAllocMethod);
	
	//dealloc
	classDeallocMethod = class_getInstanceMethod([NSObject class], @selector(dealloc) );
	classDeallocImp = method_getImplementation(classDeallocMethod);
	
	classMyDeallocMethod = class_getInstanceMethod([NSObject class], @selector(myDeallocFunc) );
	classMyDeallocImp = method_getImplementation(classMyDeallocMethod);
	
	//retain
	classRetainMethod = class_getInstanceMethod([NSObject class], @selector(retain) );
	classRetainImp = method_getImplementation(classRetainMethod);
	
	classMyRetainMethod = class_getInstanceMethod([NSObject class], @selector(myRetainFunc) );
	classMyRetainImp = method_getImplementation(classMyRetainMethod);
	
	//release
	classReleaseMethod = class_getInstanceMethod([NSObject class], @selector(release) );
	classReleaseImp = method_getImplementation(classReleaseMethod);
	
	classMyReleaseMethod = class_getInstanceMethod([NSObject class], @selector(myReleaseFunc) );
	classMyReleaseImp = method_getImplementation(classMyReleaseMethod);
	
	ALLOC_METHOD_EXCHANGE;
	method_exchangeImplementations(classDeallocMethod, classMyDeallocMethod);
	RETAIN_METHOD_EXCHANGE;
	method_exchangeImplementations(classReleaseMethod, classMyReleaseMethod);
}

+ (id) myAllocFunc
{
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classAllocImp;
	id newPt = f(self,@selector(myAllocFunc));
	
	@synchronized( [NSObject class] )
	{		
		BOOL found = NO;
		for( NSMemCheckObject* obj in memData )
			if( obj.pointerValue == newPt )
			{
				found = YES;
				break;
			}
		
		if( !found )
		{
			ALLOC_METHOD_EXCHANGE;
			NSMemCheckObject* addObj = [[[NSMemCheckObject alloc] initWithPointer:newPt] autorelease];
			[memData insertObject:addObj atIndex:0];
			
			//hack to get call stack
			@try 
			{
				@throw [NSException exceptionWithName:@"memTestException" 
											   reason:@"get call stack" 
											 userInfo:nil];
			}
			@catch (NSException * e) 
			{
				addObj.callStack = [e callStackSymbols];
			}
			ALLOC_METHOD_EXCHANGE;
		}
	}
	
	return newPt;
}

- (void)myDeallocFunc
{	
	@synchronized( [NSObject class] )
	{	
		int i = [memData count]-1;
		while( i>=0 )
		{		
			if( ((NSMemCheckObject*)[memData objectAtIndex:i]).pointerValue == self )
			{
				[memData removeObjectAtIndex:i];
				break;
			}
			
			--i;
		}
	}
	
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classDeallocImp;
	f(self,@selector(myDeallocFunc));
}

- (id)myRetainFunc
{
	@synchronized( [NSObject class] )
	{
		BOOL needAllocExchange = ( method_getImplementation(classAllocMethod) == classMyAllocImp );

		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
		
		RETAIN_METHOD_EXCHANGE;

		NSMemCheckObject* addObj = [memData memCheckObjectByPointer:self];
		
		//hack to get call stack
		if( addObj )
		{
			@try 
			{
				@throw [NSException exceptionWithName:@"memTestException" 
											   reason:@"get call stack" 
											 userInfo:nil];
			}
			@catch (NSException * e) 
			{
				NSMemCheckRetainReleaseInfo* info = [[NSMemCheckRetainReleaseInfo alloc] init];
				info.date = [NSDate date];
				info.callStack = [e callStackSymbols];
				
				[addObj.retainCallStackArray addObject:info];
				
				[info release];
			}
		}
		
		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
		
		RETAIN_METHOD_EXCHANGE;
	}
	 
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classRetainImp;
	return f(self,@selector(myRetainFunc));
}

- (void)myReleaseFunc
{	
	@synchronized( [NSObject class] )
	{
		BOOL needAllocExchange = ( method_getImplementation(classAllocMethod) == classMyAllocImp );
		
		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
		
		NSMemCheckObject* addObj = [memData memCheckObjectByPointer:self];
		
		//hack to get call stack
		if( addObj )
		{
			@try 
			{
				@throw [NSException exceptionWithName:@"memTestException" 
											   reason:@"get call stack" 
											 userInfo:nil];
			}
			@catch (NSException * e) 
			{
				NSMemCheckRetainReleaseInfo* info = [[NSMemCheckRetainReleaseInfo alloc] init];
				info.date = [NSDate date];
				info.callStack = [e callStackSymbols];
				
				[addObj.releaseCallStackArray addObject:info];
				
				[info release];
			}
		}
		
		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
	}
	
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classReleaseImp;
	f(self,@selector(myReleaseFunc));
}

@end


#endif