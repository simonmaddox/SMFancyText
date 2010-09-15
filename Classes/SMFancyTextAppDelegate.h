//
//  SMFancyTextAppDelegate.h
//  SMFancyText
//
//  Created by Simon Maddox on 15/09/2010.
//  Copyright 2010 Sensible Duck Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMFancyTextViewController;

@interface SMFancyTextAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SMFancyTextViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SMFancyTextViewController *viewController;

@end

