//
//  NSAddObject.h
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import <Foundation/Foundation.h>

@class NSMemCheckObject;

@interface NSMemCheckRetainReleaseInfo : NSObject
{
@public
	NSDate* date;
	NSArray* callStack;
}

@property(nonatomic,retain) NSDate* date;
@property(nonatomic,retain) NSArray* callStack;

@end

@interface NSMemCheckOwnerInfo : NSObject 
{
@public
    NSString* propertyName;
    NSMemCheckObject* object;
}

@property (nonatomic, retain) NSString *propertyName;
@property (nonatomic, retain) NSMemCheckObject *object;

- (id)initWithPropertyName:(NSString*)aPropertyName object:(NSMemCheckObject*)anObject;
+ (id)memCheckOwnerInfoWithPropertyName:(NSString*)aPropertyName object:(NSMemCheckObject*)anObject;

@end


@interface NSMemCheckObject : NSObject 
{
@public
	id pointerValue;
	NSString* className;
    NSMutableArray* owners;
	
	NSDate* allocDate;
	NSArray* allocCallStack;
	NSMutableArray* retainCallStackArray;	//contains NSMemCheckRetainReleaseInfo
	NSMutableArray* releaseCallStackArray;	//contains NSMemCheckRetainReleaseInfo
    
    NSInteger autoreleaseCallCount;
    BOOL isDead;
}

@property(nonatomic,assign) id pointerValue;
@property(nonatomic,retain) NSString* className;
@property(nonatomic,retain) NSMutableArray* owners;
@property(nonatomic,retain) NSDate* allocDate;
@property(nonatomic,retain) NSArray* allocCallStack;
@property(nonatomic,retain) NSMutableArray* retainCallStackArray;
@property(nonatomic,retain) NSMutableArray* releaseCallStackArray;
@property(nonatomic,assign) NSInteger autoreleaseCallCount;
@property (nonatomic, assign) BOOL isDead;

- (id)initWithPointer:(id)obj;
- (NSString*) retains;
- (NSString*) releases;
- (NSString*) history;

- (void)addOwner:(NSMemCheckOwnerInfo*)ownerInfo;
//- (void)removeOwnerByPtr:(id)obj;
//- (void)removeOwnerByObjData:(NSMemCheckObject*)objInfo;

@end

#endif


