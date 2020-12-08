//
//  AppDelegate.m
//  hpple解析html
//
//  Created by 许明洋 on 2020/8/20.
//  Copyright © 2020 许明洋. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "TestViewController.h"
#import "IPAddressViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
//    ViewController *vc = [[ViewController alloc] init];
//    TestViewController *vc = [[TestViewController alloc] init];
    IPAddressViewController *vc = [[IPAddressViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nav;
    return YES;
}

@end
