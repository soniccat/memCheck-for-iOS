//
//  NSObject+memCheck.m
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#define DISABLE_CATCH_AUTORELEASE

#import "NSObject+memCheck.h"
#import <Foundation/Foundation.h> 
#import <objc/runtime.h>
#import <objc/message.h>
#import <objc/objc.h>
#import "NSMemCheckObject.h"
#import "NSMutableArray+MemCheck.h"

NSMutableArray* memData;
NSMutableArray* suggestedLeaks;
NSMutableArray* heaps;

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

Method classAutoreleaseMethod;
IMP classAutoreleaseImp;

Method classMyAutoreleaseMethod;
IMP classMyAutoreleaseImp;


typedef id (*OverrideMemCheckPrototipe)(id,SEL);

#define ALLOC_METHOD_EXCHANGE method_exchangeImplementations(classAllocMethod, classMyAllocMethod)
#define RETAIN_METHOD_EXCHANGE method_exchangeImplementations(classRetainMethod, classMyRetainMethod)

#ifdef DISABLE_CATCH_AUTORELEASE

    #define AUTORELEASE_METHOD_EXCHANGE ;
    #define AUTORELEASE_METHOD_EXCHANGE_ON_OLD ;
    #define AUTORELEASE_METHOD_EXCHANGE_ON_NEW ;

#else

    #define AUTORELEASE_METHOD_EXCHANGE method_exchangeImplementations(classAutoreleaseMethod, classMyAutoreleaseMethod)

    #define AUTORELEASE_METHOD_EXCHANGE_ON_OLD BOOL needAutoreleaseExchange = ( method_getImplementation(classAllocMethod) == classMyAllocImp );\
    if( needAutoreleaseExchange )\
    AUTORELEASE_METHOD_EXCHANGE;

    #define AUTORELEASE_METHOD_EXCHANGE_ON_NEW if(needAutoreleaseExchange)\
    AUTORELEASE_METHOD_EXCHANGE;

#endif //DISABLE_CATCH_AUTORELEASE

@interface NSObject ()

- (void)scanPropertiesForObject:(id)obj;

@end


@implementation NSObject (memCheck)

+ (void)turnMemCheckOn
{
	if( memData == nil  )
		memData = [[NSMutableArray allocWithZone:nil] init];
	
	if( heaps == nil )
		heaps = [[NSMutableArray allocWithZone:nil] init];
	
    if( suggestedLeaks == nil )
        suggestedLeaks = [[NSMutableArray allocWithZone:nil] init];
    
    //InstallUncaughtExceptionHandler();
    
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
	
    //autorelease
    classAutoreleaseMethod = class_getInstanceMethod([NSObject class], @selector(autorelease) );
    classAutoreleaseImp  = method_getImplementation(classAutoreleaseMethod);;
    
    classMyAutoreleaseMethod = class_getInstanceMethod([NSObject class], @selector(myAutoreleaseFunc) );
    classMyAutoreleaseImp = method_getImplementation(classMyAutoreleaseMethod);
    
	ALLOC_METHOD_EXCHANGE;
	method_exchangeImplementations(classDeallocMethod, classMyDeallocMethod);
	RETAIN_METHOD_EXCHANGE;
	method_exchangeImplementations(classReleaseMethod, classMyReleaseMethod);
    AUTORELEASE_METHOD_EXCHANGE;
	
	[memData markHeap];
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
            AUTORELEASE_METHOD_EXCHANGE_ON_OLD;
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
            //printf("insert %p\n", newPt);
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
				addObj.allocCallStack = [e callStackSymbols];
			}
			
			[pool release];
            AUTORELEASE_METHOD_EXCHANGE_ON_NEW;
			ALLOC_METHOD_EXCHANGE;
		}
	}
	
	return newPt;
}

- (void)scanPropertiesForObject:(id)obj
{
    NSMemCheckObject* memObj = [memData memCheckObjectByPointer:obj];
    
    unsigned int propCount = 0;
    objc_property_t* poperties = class_copyPropertyList( NSClassFromString( memObj.className ), &propCount );
    
    
    //if( ![NSStringFromClass( [self class] ) isEqualToString:@"SBJsonStreamParserAccumulator"]  )
    if( ![NSStringFromClass( [self class] ) isEqualToString:@"DelegatesContainer"]  )
    if( ![NSStringFromClass( [self class] ) isEqualToString:@"UIGestureDelayedTouch"]  )
    //if( ![NSStringFromClass( [self class] ) isEqualToString:@"UITapGestureRecognizer"]  )
            
    for (int a=0; a<propCount; a++) 
    {
        objc_property_t *thisProperty = poperties + a;
        const char* propertyName = property_getName(*thisProperty);
        const char* propertyAttributes = property_getAttributes(*thisProperty);
        
        NSString *key = [[[NSString alloc] initWithFormat:@"%s", propertyName] autorelease];
        //NSString *keyAttributes = [[NSString alloc] initWithFormat:@"%s", propertyAttributes];
        
        //NSLog(key);
        //NSLog(keyAttributes);
        
        NSInteger len = strlen(propertyAttributes);
        if( strlen(propertyAttributes) < 2 || propertyAttributes[1]!= '@' )
        {
            //[key release];
            //[keyAttributes release];
            continue;
        }
        
        BOOL foundIsRetain = NO;
        for( int sCheck = 0; sCheck<len; ++sCheck)
            if( propertyAttributes[sCheck] == '&' )
            {
                foundIsRetain = YES;
                break;
                
            }
        
        if(!foundIsRetain)
            continue;
        
        SEL selector = NSSelectorFromString(key);
        if ([self respondsToSelector:selector]) 
        {
            NSMethodSignature *sig = [self methodSignatureForSelector:selector];
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setSelector:selector];
            [invocation setTarget:self];
            
            id returnObj = nil;
            
            @try {
                [invocation invoke];
                [invocation getReturnValue:(void **)&returnObj];
            }
            @catch (NSException *exception) {
                printf("invoke exception");
                //NSLog(@"DumpCommand.mapObjectToPropertiesDictionary caught %@: %@", [exception name], [exception reason]);
                continue;
            }
            
            
            if( returnObj != nil )
            {
                //look in memory
                //BOOL found = NO;
                for(NSMemCheckObject* memObj2 in memData)
                    if( memObj2.pointerValue == returnObj && [memObj2.retainCallStackArray count] >= [memObj2.releaseCallStackArray count])
                    {               
                        [memObj2 addOwner: [NSMemCheckOwnerInfo memCheckOwnerInfoWithPropertyName:key object:memObj]];
                        //[memObj2.owners addObject:[NSString stringWithFormat:@"[%@ %p %@]",memObj.className, self, key]];
                        
                        if( [self retainCount] == 1 )
                        {
                            //search other owner
                            
                            if(![suggestedLeaks containsObject:memObj2])
                                [suggestedLeaks addObject:memObj2];
                        }
                        
                        break;
                    }
                
                //if(found)
                //if( [returnObj isKindOfClass:[NSObject class]] )
                //    printf( "%p", returnObj );
            }
        }
        
        
        //[key release];
        //[keyAttributes release];
    }
}

- (void)myDeallocFunc
{	
	@synchronized( [NSObject class] )
	{
        BOOL needAllocExchange = ( method_getImplementation(classAllocMethod) == classMyAllocImp );
        
		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
        
        RETAIN_METHOD_EXCHANGE;
        AUTORELEASE_METHOD_EXCHANGE_ON_OLD;
        
        //printf("myDeallocFunc %p\n", self);
        
		int i = [memData count]-1;
        //NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        
        /*
        if( [self isKindOfClass:NSClassFromString(@"CategoryPresentViewController")] )
        {
            printf(":)");
        }
        */
        
		while( i>=0 )
		{	
            //[(NSMemCheckObject*)[memData objectAtIndex:i] removeOwnerByPtr:self];
 
			if( ((NSMemCheckObject*)[memData objectAtIndex:i]).pointerValue == self )
			{
                //property check
                NSMemCheckObject* memObj = (NSMemCheckObject*)[memData objectAtIndex:i];
                
                //printf("remove %p\n", memObj.pointerValue);
                
                BOOL needLookInSuggestedLeaks = [memObj retainCount] > 1;
                
                if(needLookInSuggestedLeaks)
                {
                    NSInteger suggestIndex = 0;
                    for( int s=0; s<[suggestedLeaks count]; ++s )
                    {
                        if( ((NSMemCheckObject*)[suggestedLeaks objectAtIndex:s]).pointerValue == self )
                        {
                            [suggestedLeaks removeObjectAtIndex:suggestIndex];
                            break;
                        }
                        
                        ++suggestIndex;
                    }
                }
                
                /*
                for( NSMemCheckObject* memObj2 in memData )
                {
                    [memObj2 removeOwnerByObjData:memObj];
                }*/
                
                memObj.isDead = YES;
                [memData removeObjectAtIndex:i];
                
				break;
			}
			
			--i;
		}
        
        
        //[pool release];
        
        AUTORELEASE_METHOD_EXCHANGE_ON_NEW;
        RETAIN_METHOD_EXCHANGE;
        
        if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
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
        AUTORELEASE_METHOD_EXCHANGE_ON_OLD;

		NSMemCheckObject* addObj = [memData memCheckObjectByPointer:self];
		
		//hack to get call stack
		if( addObj )
		{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
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
			
			[pool release];
		}
		
        AUTORELEASE_METHOD_EXCHANGE_ON_NEW;
		RETAIN_METHOD_EXCHANGE;
        
		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
		
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
        
        AUTORELEASE_METHOD_EXCHANGE_ON_OLD;
		
		NSMemCheckObject* addObj = [memData memCheckObjectByPointer:self];
		
		//hack to get call stack
		if( addObj )
		{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
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
                
#ifndef DISABLE_CATCH_AUTORELEASE
                //check on CFAutoreleasePoolPop
                NSInteger recordIndex = 0;
                for(NSString* record in info.callStack)
                {
                    if( [record rangeOfString:@"myReleaseFunc"].location != NSNotFound )
                    {
                        if( [info.callStack count] > recordIndex+1 && [[info.callStack objectAtIndex:recordIndex+2] rangeOfString:@"CFAutoreleasePoolPop"].location != NSNotFound )
                        {
                            addObj.autoreleaseCallCount--;
                            
                            if(addObj.autoreleaseCallCount < 0)
                            {
                                printf(":(\n");
                            }
                            
                            break;
                            
                        }else
                            break;
                    }
                    
                    ++recordIndex;
                }
#endif //DISABLE_CATCH_AUTORELEASE
				
				[info release];
			}
            
            [self scanPropertiesForObject:self];
			
			[pool release];
		}
        
        AUTORELEASE_METHOD_EXCHANGE_ON_NEW;
		
		if( needAllocExchange )
			ALLOC_METHOD_EXCHANGE;
	}
	
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classReleaseImp;
	f(self,@selector(myReleaseFunc));
}

- (void)myAutoreleaseFunc
{
    @synchronized( [NSObject class] )
	{
        AUTORELEASE_METHOD_EXCHANGE_ON_OLD;
        
        //new logic
        NSMemCheckObject* addObj = [memData memCheckObjectByPointer:self];
        if(addObj)
            addObj.autoreleaseCallCount ++;
        
        AUTORELEASE_METHOD_EXCHANGE_ON_NEW;
    }
    
    
    //call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classAutoreleaseImp;
	f(self,@selector(myAutoreleaseFunc));
}

@end


#endif