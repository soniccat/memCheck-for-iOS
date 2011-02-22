//
//  inFoundationAppDelegate.h
//  inFoundation
//
//  Created by Alexey Glushkov on 18.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#import <UIKit/UIKit.h>

@class memCheckViewController;

@interface inFoundationAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    memCheckViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet memCheckViewController *viewController;

@end

