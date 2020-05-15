//
//  AppDelegate.m
//  WebRTCiOS
//
//  Created by zhangguangpeng on 2020/5/14.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    HomeViewController *con = [[HomeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:con];
    [self.window setRootViewController:nav];
    [self.window makeKeyAndVisible];
    
    return YES;
}





@end
