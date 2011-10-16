//
//  inFoundationAppDelegate.m
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#import "memCheckAppDelegate.h"
#import "memCheckViewController.h"

#import <Foundation/Foundation.h> 

#import "NSMemCheckObject.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <objc/objc.h>

@interface TestClass: NSObject
{
    id str;
}

@property(nonatomic,retain) id str;

@end

@implementation TestClass

@synthesize str;

- (void)dealloc
{
    [super dealloc];
}

@end


@implementation inFoundationAppDelegate

@synthesize window;
@synthesize viewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
	
#ifdef MEMTEST_ON
	[NSObject turnMemCheckOn];
#endif	

	//For test
	NSObject* obj = [[NSObject alloc] init];
	NSArray* arr = [NSArray arrayWithObject:obj];
	
	NSLog(@"test %p", arr);
	
	[obj retain];
	
	[arr retainCount];
	id oo = [arr objectAtIndex:0];
	
	[oo release];
	

	NSArray* arr2 = [NSArray arrayWithObject:obj];
	
	NSLog(@"test2 %p", arr2);
	
	NSMutableArray* arr3 = [NSMutableArray arrayWithObject:obj];
	NSLog(@"test3 %p", arr3);
	
	NSMutableArray* arr4 = [NSMutableArray arrayWithObject:obj];
	
    TestClass* testObj = [[TestClass alloc] init];
    
    NSObject* strObj = nil;
    testObj.str = [[[NSObject alloc] init] autorelease];
    strObj = testObj.str;
    
    [testObj release];
    
    //[strObj release];
    
    // Add the view controller's view to the window and display.
    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];
	
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
