//
//  GauchoMobileAppDelegate.m
//  Manages launch and termination of GauchoMobile
//  Created by Group J5 for CS48
//


#import "GauchoMobileAppDelegate.h"

@implementation GauchoMobileAppDelegate

@synthesize window;
@synthesize masterPopoverController;
@synthesize detail;
@synthesize courseController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Create the course view controller and set it as the root view controller
    self.courseController = [[[CourseViewController alloc] initWithNibName:@"CourseViewController" bundle:[NSBundle mainBundle]] autorelease];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UINavigationController *navController = [[UINavigationController alloc] init];
        self.window.rootViewController = navController;
    
        [navController pushViewController:courseController animated:NO];
        [navController release];
    } else {
        UISplitViewController *splitViewController = [[GMSplitViewController alloc] init];
        
        self.detail = [[[MainTabBarViewController alloc] init] autorelease];
        UINavigationController *rootNav = [[UINavigationController alloc] initWithRootViewController:self.courseController];
        UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:self.detail];
        
        detailNav.navigationBar.tintColor = [UIColor colorWithRed:24/255.0 green:69/255.0 blue:135/255.0 alpha:1.0];
        
        splitViewController.viewControllers = [NSArray arrayWithObjects:rootNav, detailNav, nil];
        splitViewController.delegate = self;
        
        self.window.rootViewController = splitViewController;
        
        [splitViewController release];
        [rootNav release];
        [detailNav release];
    }
    
    [self.window makeKeyAndVisible];
    
    //Create and display the login view controller
    LoginViewController *login = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:[NSBundle mainBundle]];
    [self.window.rootViewController presentModalViewController:login animated:NO];
    [login release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissMasterPopover) name:@"GMLogoutNotification" object:nil];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSDate *lastActiveDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastActiveDate"];
    BOOL loginScreenVisible = [[[NSUserDefaults standardUserDefaults] objectForKey:@"loginScreenVisible"] boolValue];
    if (lastActiveDate != nil && [[NSDate date] timeIntervalSinceDate:lastActiveDate] > 900 && !loginScreenVisible) {
        sourceFetcher = [[GMSourceFetcher alloc] init];
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"com.stuffediggy.gauchomobile" accessGroup:nil];
        NSString *username = [keychain objectForKey:(id)kSecAttrAccount];
        NSString *password = [keychain objectForKey:(id)kSecValueData];
        [keychain release];
        [sourceFetcher loginWithUsername:username password:password delegate:self];
        waitMessage = [[[UIAlertView alloc] initWithTitle:@"Welcome Back!" message:@"Hang on for a sec while we log you back in to GauchoSpace..." delegate:self cancelButtonTitle:nil otherButtonTitles: nil] autorelease];
        waitMessage.delegate = self;
        [waitMessage show];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSDate *date = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"lastActiveDate"];
    //Cache data when we go into the background
    [[GMDataSource sharedDataSource] archiveData];
    
    if (waitMessage != nil) {
        [waitMessage dismissWithClickedButtonIndex:0 animated:NO];
        waitMessage = nil;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[GMDataSource sharedDataSource] archiveData];
}

- (void)sourceFetchDidFailWithError:(NSError *)error {
    [indicator removeFromSuperview];
    indicator = nil;
    [waitMessage dismissWithClickedButtonIndex:0 animated:YES];
    waitMessage = nil;
    LoginViewController *login = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:[NSBundle mainBundle]];
    [self.window.rootViewController presentModalViewController:login animated:NO];
    [login release];
    
    UIAlertView *loginFailedAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:[NSString stringWithFormat:@"Logging in failed with the following error: %@", [error description]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [loginFailedAlert show];
    [loginFailedAlert release];
    [sourceFetcher release];
}

- (void)sourceFetchSucceededWithPageSource:(NSString *)source {
    [indicator removeFromSuperview];
    indicator = nil;
    [waitMessage dismissWithClickedButtonIndex:0 animated:YES];
    waitMessage = nil;
    if ([source rangeOfString:@"You are logged in as"].location != NSNotFound) {
        
        //Snag our session key
        source = [source substringFromIndex:[source rangeOfString:@"sesskey="].location + 8];
        NSString *sessionKey = [source substringToIndex:[source rangeOfString:@"&"].location];
        [[NSUserDefaults standardUserDefaults] setObject:sessionKey forKey:@"sessionkey"];
        
    }
    else {
        LoginViewController *login = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:[NSBundle mainBundle]];
        [self.window.rootViewController presentModalViewController:login animated:NO];
        [login release];
        
        UIAlertView *loginFailedAlert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:[NSString stringWithFormat:@"GauchoMobile was unable to log in. Check your username and password and try again."] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [loginFailedAlert show];
        [loginFailedAlert release];
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Adjust the indicator so it is up a few pixels from the bottom of the alert
    indicator.center = CGPointMake(alertView.bounds.size.width / 2, alertView.bounds.size.height - 50);
    [indicator startAnimating];
    [alertView addSubview:indicator];
    [indicator release];
}

- (void)dismissMasterPopover {
    [self.masterPopoverController dismissPopoverAnimated:YES];
    self.masterPopoverController = nil;
}


- (void)splitViewController:(UISplitViewController*)svc
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem*)barButtonItem 
       forPopoverController:(UIPopoverController*)pc
{
    [barButtonItem setTitle:@"Courses"];
    ((GMSplitViewController *)svc).barButtonItem = barButtonItem;
    self.masterPopoverController = pc;
}


- (void)splitViewController:(UISplitViewController*)svc
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    ((GMSplitViewController *)svc).barButtonItem = nil;
    self.masterPopoverController = nil;
}



- (void)dealloc {
    [window release];
    self.detail = nil;
    self.courseController = nil;
    self.masterPopoverController = nil;
    [super dealloc];
}

@end
