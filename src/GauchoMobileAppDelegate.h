//
//  GauchoMobileAppDelegate.h
//  Manages launch and termination of GauchoMobile
//  Created by Group J5 for CS48
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "CourseViewController.h"
#import "GMSourceFetcher.h"
#import "KeychainItemWrapper.h"

@interface GauchoMobileAppDelegate : NSObject <UIApplicationDelegate, UISplitViewControllerDelegate, GMSourceFetcherDelegate> {
@private
    GMSourceFetcher *sourceFetcher;
    GMOMainTabBarViewController *detail;
    CourseViewController *courseController;
    UIPopoverController *masterPopoverController;
    UIAlertView *waitMessage;
    UIActivityIndicatorView *indicator;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (retain) UIPopoverController *masterPopoverController;
@property (retain) GMOMainTabBarViewController *detail;
@property (retain) CourseViewController *courseController;

@end
