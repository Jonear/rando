//
//  RDAppDelegate.m
//  Rando
//
//  Created by Jonear on 14-3-8.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDAppDelegate.h"
#import "RDTabBarViewController.h"
#import "RDRandoViewController.h"
#import "RDMyRandoViewController.h"
#import "BaiduMobStat.h"

@implementation RDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    RDTabBarViewController *mainViewController = [[RDTabBarViewController alloc] init];
    
    RDRandoViewController *rando = [[RDRandoViewController alloc] init];
    RDMyRandoViewController *myRando = [[RDMyRandoViewController alloc] init];
    
    [mainViewController setViewControllers:rando, myRando, nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    
    rando.navController = navController;
    myRando.navController = navController;
    
    self.window.rootViewController = navController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [self startBaiduMob];
    return YES;
}

- (void)startBaiduMob
{
    //百度统计
    BaiduMobStat* statTracker = [BaiduMobStat defaultStat];
    statTracker.enableExceptionLog = NO;
    //statTracker.channelId = @"login";
    statTracker.logStrategy = BaiduMobStatLogStrategyCustom;
    statTracker.logSendInterval = 1;
    statTracker.logSendWifiOnly = YES;
    statTracker.sessionResumeInterval = 60;
    statTracker.enableExceptionLog = NO;
    [statTracker startWithAppId:@"a4d3959e5a"];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSNotificationCenter defaultCenter] postNotificationName:noti_APPEnterBackground object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:noti_APPEnterForeground object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
