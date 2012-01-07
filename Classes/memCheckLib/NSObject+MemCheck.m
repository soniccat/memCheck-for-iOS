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
#import "NSArray+MemCheck.h"
#import "NSMemCheckParser.h"
#import "NSMemCheckHeap.h"

NSMutableArray* memData;    //list of allocated objects
NSMutableArray* removedMemData; //list of removed objects from the memData
NSMutableArray* suggestedLeaks; 

NSSet* classesToFilter; //set of the classes which should be missed
#define CLASSES_TO_FILTER @"UITouch"

#define TOLL_FREE_BRIDGE_CLASSES @"NSArray",\
@"NSAttributedString",\
@"NSCalendar",\
@"NSCharacterSet",\
@"NSData",\
@"NSDate",\
@"NSDictionary",\
@"NSError",\
@"NSLocale",\
@"NSMutableArray",\
@"NSMutableAttributedString",\
@"NSMutableCharacterSet",\
@"NSMutableData",\
@"NSMutableDictionary",\
@"NSMutableSet",\
@"NSMutableString",\
@"NSNumber",\
@"NSInputStream",\
@"NSTimer",\
@"NSSet",\
@"NSString",\
@"NSTimeZone",\
@"NSURL",\
@"NSOutputStream"

extern NSMutableArray* heaps;
extern NSMemCheckParser* parser;

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

//alloc
#define ALLOC_METHOD_EXCHANGE method_exchangeImplementations(classAllocMethod, classMyAllocMethod)

#define ALLOC_METHOD_EXCHANGE_TO_NEW if( method_getImplementation(classAllocMethod) == classAllocImp )\
ALLOC_METHOD_EXCHANGE

#define ALLOC_METHOD_EXCHANGE_TO_OLD if( method_getImplementation(classAllocMethod) == classMyAllocImp )\
ALLOC_METHOD_EXCHANGE

//dealloc
#define DEALLOC_METHOD_EXCHANGE method_exchangeImplementations(classDeallocMethod, classMyDeallocMethod)

#define DEALLOC_METHOD_EXCHANGE_TO_NEW if( method_getImplementation(classDeallocMethod) == classDeallocImp )\
DEALLOC_METHOD_EXCHANGE

#define DEALLOC_METHOD_EXCHANGE_TO_OLD if( method_getImplementation(classDeallocMethod) == classMyDeallocImp )\
DEALLOC_METHOD_EXCHANGE

//retain
#define RETAIN_METHOD_EXCHANGE method_exchangeImplementations(classRetainMethod, classMyRetainMethod)

#define RETAIN_METHOD_EXCHANGE_TO_NEW if( method_getImplementation(classRetainMethod) == classRetainImp )\
RETAIN_METHOD_EXCHANGE

#define RETAIN_METHOD_EXCHANGE_TO_OLD if( method_getImplementation(classRetainMethod) == classMyRetainImp )\
RETAIN_METHOD_EXCHANGE

//release

#define RELEASE_METHOD_EXCHANGE method_exchangeImplementations(classReleaseMethod, classMyReleaseMethod)

#define RELEASE_METHOD_EXCHANGE_TO_NEW if( method_getImplementation(classReleaseMethod) == classReleaseImp )\
RELEASE_METHOD_EXCHANGE

#define RELEASE_METHOD_EXCHANGE_TO_OLD if( method_getImplementation(classReleaseMethod) == classMyReleaseImp )\
RELEASE_METHOD_EXCHANGE



#ifdef DISABLE_CATCH_AUTORELEASE

    #define AUTORELEASE_METHOD_EXCHANGE ;
    #define AUTORELEASE_METHOD_EXCHANGE_ON_OLD ;
    #define AUTORELEASE_METHOD_EXCHANGE_ON_NEW ;

#else

    #define AUTORELEASE_METHOD_EXCHANGE method_exchangeImplementations(classAutoreleaseMethod, classMyAutoreleaseMethod)

    #define AUTORELEASE_METHOD_EXCHANGE_ON_OLD BOOL needAutoreleaseExchange = ( method_getImplementation(classAutoreleaseMethod) == classMyAutoreleaseImp );\
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
    {
		heaps = [[NSMutableArray allocWithZone:nil] init];
        [NSMemCheckHeap markHeapWithName:@"startHeap"];
    }
	
    if( suggestedLeaks == nil )
        suggestedLeaks = [[NSMutableArray allocWithZone:nil] init];
    
    if( removedMemData == nil )
        removedMemData = [[NSMutableArray allocWithZone:nil] init];
    
    if( parser == nil )
        parser = [[NSMemCheckParser alloc] init];
    
    if( classesToFilter == nil )
    {
        classesToFilter = [[NSSet alloc] initWithArray:[NSArray arrayWithObjects: CLASSES_TO_FILTER, nil]];
    }
    
	//alloc
    if(!classAllocMethod)
        classAllocMethod = class_getClassMethod([NSObject class], @selector(alloc) );
    
    if(!classAllocImp)
        classAllocImp = method_getImplementation(classAllocMethod);
	
    if(!classMyAllocMethod)
        classMyAllocMethod = class_getClassMethod([NSObject class], @selector(myAllocFunc) );
    
    if(!classMyAllocImp)
        classMyAllocImp = method_getImplementation(classMyAllocMethod);
	
	//dealloc
    if(!classDeallocMethod)
        classDeallocMethod = class_getInstanceMethod([NSObject class], @selector(dealloc) );
    
    if(!classDeallocImp)
        classDeallocImp = method_getImplementation(classDeallocMethod);
	
    if(!classMyDeallocMethod)
        classMyDeallocMethod = class_getInstanceMethod([NSObject class], @selector(myDeallocFunc) );
    
    if(!classMyDeallocImp)
        classMyDeallocImp = method_getImplementation(classMyDeallocMethod);
	
	//retain
    if(!classRetainMethod)
        classRetainMethod = class_getInstanceMethod([NSObject class], @selector(retain) );
    
    if(!classRetainImp)
        classRetainImp = method_getImplementation(classRetainMethod);
	
    if(!classMyRetainMethod)
        classMyRetainMethod = class_getInstanceMethod([NSObject class], @selector(myRetainFunc) );
    
    if(!classMyRetainImp)
        classMyRetainImp = method_getImplementation(classMyRetainMethod);
	
	//release
    if(!classReleaseMethod)
        classReleaseMethod = class_getInstanceMethod([NSObject class], @selector(release) );
	
    if(!classReleaseImp)
         classReleaseImp = method_getImplementation(classReleaseMethod);
	
    if(!classMyReleaseMethod)
        classMyReleaseMethod = class_getInstanceMethod([NSObject class], @selector(myReleaseFunc) );
	
    if(!classMyReleaseImp)
        classMyReleaseImp = method_getImplementation(classMyReleaseMethod);
	
    //autorelease
    if(!classAutoreleaseMethod)
        classAutoreleaseMethod = class_getInstanceMethod([NSObject class], @selector(autorelease) );
    
    if(!classAutoreleaseImp)
        classAutoreleaseImp  = method_getImplementation(classAutoreleaseMethod);;
    
    if(!classMyAutoreleaseMethod)
        classMyAutoreleaseMethod = class_getInstanceMethod([NSObject class], @selector(myAutoreleaseFunc) );
    
    if(!classMyAutoreleaseImp)
        classMyAutoreleaseImp = method_getImplementation(classMyAutoreleaseMethod);
    
	ALLOC_METHOD_EXCHANGE_TO_NEW;
	DEALLOC_METHOD_EXCHANGE_TO_NEW;
	RETAIN_METHOD_EXCHANGE_TO_NEW;
	RELEASE_METHOD_EXCHANGE_TO_NEW;
    AUTORELEASE_METHOD_EXCHANGE;
	
	//[memData markHeap];
}

+ (void)turnMemCheckOff
{
    ALLOC_METHOD_EXCHANGE_TO_OLD;
	DEALLOC_METHOD_EXCHANGE_TO_OLD;
	RETAIN_METHOD_EXCHANGE_TO_OLD;
	RELEASE_METHOD_EXCHANGE_TO_OLD;
    AUTORELEASE_METHOD_EXCHANGE;
}

+ (id) myAllocFunc
{
	//call base implementation
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classAllocImp;
	id newPt = f(self,@selector(myAllocFunc));
	
	@synchronized( [NSObject class] )
	{	
        BOOL found = [memData memCheckObjectByPointer:newPt] != nil;
		
        [NSObject turnMemCheckOff];
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        
		if( !found && ![classesToFilter containsObject: NSStringFromClass([newPt class]) ] )
		{
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
		}
        
        [pool release];
        [NSObject turnMemCheckOn];
	}
	
	return newPt;
}

- (void)scanPropertiesForObject:(id)obj
{
    NSMemCheckObject* memObj = [memData memCheckObjectByPointer:obj];
    
    unsigned int propCount = 0;
    objc_property_t* poperties = class_copyPropertyList( NSClassFromString( memObj.className ), &propCount );
    
    
    if( ![NSStringFromClass( [self class] ) isEqualToString:@"DelegatesContainer"]  )
    if( ![NSStringFromClass( [self class] ) isEqualToString:@"UIGestureDelayedTouch"]  )
    for (int a=0; a<propCount; a++) 
    {
        objc_property_t *thisProperty = poperties + a;
        const char* propertyName = property_getName(*thisProperty);
        const char* propertyAttributes = property_getAttributes(*thisProperty);
        
        NSString *key = [[[NSString alloc] initWithFormat:@"%s", propertyName] autorelease];
        //NSString *keyAttributes = [[[NSString alloc] initWithFormat:@"%s", propertyAttributes] autorelease];
        
        //NSLog(key);
        //NSLog(keyAttributes);
        
        NSInteger len = strlen(propertyAttributes);
        if( strlen(propertyAttributes) < 2 || propertyAttributes[1]!= '@' )
        {
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
            
            @try 
            {
                [invocation invoke];
                [invocation getReturnValue:(void **)&returnObj];
            }
            @catch (NSException *exception) 
            {
                printf("invoke exception");
                continue;
            }
            
            
            if( returnObj != nil )
            {
                //look in memory
                NSMemCheckObject* propertyMemObj = [memData memCheckObjectByPointer:returnObj];
                
                if( ![classesToFilter containsObject: propertyMemObj.className ] && !propertyMemObj.isDead )
                {
                    if( propertyMemObj)
                    {
                        //add relation
                        if( ![propertyMemObj.owners containsObject:memObj] )
                        {  
                            [propertyMemObj addOwner: [NSMemCheckOwnerInfo memCheckOwnerInfoWithPropertyName:key object:memObj]];
                        }
                        
                        if( [self retainCount] == 1 )
                        { 
                            //suggest a leak
                            if(![suggestedLeaks containsObject:propertyMemObj])
                                [suggestedLeaks addObject:propertyMemObj];
                        }
                    }else
                    {
                        NSSet* tollFreeBridgeSet = [NSSet setWithArray:[NSArray arrayWithObjects:TOLL_FREE_BRIDGE_CLASSES, nil]];
                        
                        if( ![tollFreeBridgeSet containsObject: NSStringFromClass( [returnObj class] ) ] )
                        {
                            //add missed object in memData
                            NSMemCheckObject* obj = [[[NSMemCheckObject alloc] initWithPointer:returnObj] autorelease];
                            [memData addObject:obj];
                            [obj addOwner:[NSMemCheckOwnerInfo memCheckOwnerInfoWithPropertyName:key object:memObj]];
                            
                            if( [self retainCount] == 1 )
                            {
                                //suggest a leak
                                if(![suggestedLeaks containsObject:obj])
                                    [suggestedLeaks addObject:obj];
                            }
                        }
                    }
                }
            }
            
        }
    }
}

- (void)myDeallocFunc
{	
	@synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        //printf("myDeallocFunc %p\n", self);
        
		int i = 0;
        //NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
             
        for(NSMemCheckObject* memObj in memData)
		{
			if( memObj.pointerValue == self )
			{
                memObj.isDead = YES;
                memObj.deadDate = [NSDate date];
                
                [removedMemData addObject:memObj];
                [memData removeObjectAtIndex:i];
				break;
			}
			
			++i;
		}
        
        
        NSInteger suggestIndex = 0;
        for(NSMemCheckObject* s in suggestedLeaks)
        {
            if( s.pointerValue == self )
            {
                [suggestedLeaks removeObjectAtIndex:suggestIndex];
                break;
            }
            
            ++suggestIndex;
        }
        
        //[pool release];
        
        [NSObject turnMemCheckOn];
	}
	
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classDeallocImp;
	f(self,@selector(myDeallocFunc));
}

- (id)myRetainFunc
{
	@synchronized( [NSObject class] )
	{
		[NSObject turnMemCheckOff];

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
		
        [NSObject turnMemCheckOn];
		
	}
	 
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classRetainImp;
	return f(self,@selector(myRetainFunc));
}

- (void)myReleaseFunc
{	
	@synchronized( [NSObject class] )
	{
		[NSObject turnMemCheckOff];
		
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
        
        [NSObject turnMemCheckOn];
	}
	
	//call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classReleaseImp;
	f(self,@selector(myReleaseFunc));
}

- (void)myAutoreleaseFunc
{
    @synchronized( [NSObject class] )
	{
        [NSObject turnMemCheckOff];
        
        NSMemCheckObject* addObj = [memData memCheckObjectByPointer:self];
        if(addObj)
            addObj.autoreleaseCallCount ++;
        
        [NSObject turnMemCheckOn];
    }
    
    
    //call base implement
	OverrideMemCheckPrototipe f = (OverrideMemCheckPrototipe)classAutoreleaseImp;
	f(self,@selector(myAutoreleaseFunc));
}

@end


#endif