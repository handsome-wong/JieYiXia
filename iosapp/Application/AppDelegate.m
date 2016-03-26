//
//  AppDelegate.m
//  iosapp
//
//  Created by chenhaoxiang on 14-10-13.
//  Copyright (c) 2014年 oschina. All rights reserved.
//

#import "AppDelegate.h"
#import "OSCThread.h"
#import "Config.h"
#import "UIView+Util.h"
#import "UIColor+Util.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "OSCAPI.h"
#import "OSCUser.h"

#import "UMSocial.h"
#import "UMSocialWechatHandler.h"
#import "UMSocialQQHandler.h"
#import "UMSocialSinaHandler.h"

#import <Ono.h>
#import <AFOnoResponseSerializer.h>
#import "AVOSCloud/AVOSCloud.h"


@interface AppDelegate () <UIApplicationDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    _inNightMode = [Config getMode];
    
    [self loadCookies];
    
    /************ 控件外观设置 **************/
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    NSDictionary *navbarTitleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    [[UITabBar appearance] setTintColor:[UIColor colorWithHex:0x8bcf32]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithHex:0x8bcf32]} forState:UIControlStateSelected];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor navigationbarColor]];
    [[UITabBar appearance] setBarTintColor:[UIColor titleBarColor]];
    
    [UISearchBar appearance].tintColor = [UIColor colorWithHex:0x8bcf32];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setCornerRadius:14.0];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setAlpha:0.6];
    
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor colorWithHex:0xDCDCDC];
    pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
    
    [[UITextField appearance] setTintColor:[UIColor nameColor]];
    [[UITextView appearance]  setTintColor:[UIColor nameColor]];
    
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    
    [menuController setMenuVisible:YES animated:YES];
    [menuController setMenuItems:@[
                                   [[UIMenuItem alloc] initWithTitle:@"复制" action:NSSelectorFromString(@"copyText:")],
                                   [[UIMenuItem alloc] initWithTitle:@"删除" action:NSSelectorFromString(@"deleteObject:")]
                                   ]];
    
    /************ 检测通知 **************/
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    
    /*if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 &&
        [[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
    }*/
    if ([Config getOwnID] != 0) {[OSCThread startPollingNotice];}
    
    
    /************ 友盟分享组件 **************/
    
    [UMSocialData setAppKey:@"54c9a412fd98c5779c000752"];
    [UMSocialWechatHandler setWXAppId:@"wxa8213dc827399101" appSecret:@"5c716417ce72ff69d8cf0c43572c9284" url:@"http://www.umeng.com/social"];
    [UMSocialQQHandler setQQWithAppId:@"100942993" appKey:@"8edd3cc7ca8dcc15082d6fe75969601b" url:@"http://www.umeng.com/social"];
    [UMSocialSinaHandler openSSOWithRedirectURL:@"http://sns.whalecloud.com/sina2/callback"];
    
    
    /************ 第三方登录设置 *************/
    
    [WeiboSDK enableDebugMode:YES];
    [WeiboSDK registerApp:@"3616966952"];
    
    /************ leancloud数据库 *************/
    //leancloud.cn数据库访问applicationId 即 App Id，clientKey 是 App Key
    [AVOSCloud setApplicationId:@"voi8VkO6QeGAehq9pxSxD7XE"
                      clientKey:@"oPMmr6iJLgoY6oisWpPbJgna"];
    //leancloud跟踪统计应用的打开情况
    [AVAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    
    
    return YES;
}

- (void)loadCookies{
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"sessionCookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in cookies){
        [cookieStorage setCookie: cookie];
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
 
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
   
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [UMSocialSnsService handleOpenURL:url]             ||
           [WXApi handleOpenURL:url delegate:_loginDelegate]  ||
           [TencentOAuth HandleOpenURL:url]                   ||
           [WeiboSDK handleOpenURL:url delegate:_loginDelegate];
    
//    return [UMSocialSnsService handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [UMSocialSnsService handleOpenURL:url]             ||
           [WXApi handleOpenURL:url delegate:_loginDelegate]  ||
           [TencentOAuth HandleOpenURL:url]                   ||
           [WeiboSDK handleOpenURL:url delegate:_loginDelegate];
    
//    return [UMSocialSnsService handleOpenURL:url];
}

@end
