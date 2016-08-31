//	            __    __                ________
//	| |    | |  \ \  / /  | |    | |   / _______|
//	| |____| |   \ \/ /   | |____| |  / /
//	| |____| |    \  /    | |____| |  | |   _____
//	| |    | |    /  \    | |    | |  | |  |____ |
//  | |    | |   / /\ \   | |    | |  \ \______| |
//  | |    | |  /_/  \_\  | |    | |   \_________|
//
//	Copyright (c) 2012年 HXHG. All rights reserved.
//	http://www.jpush.cn
//  Created by Zhanghao
//

#import "AppDelegate.h"
#import "JPUSHService.h"
#import "RootViewController.h"
#import <AdSupport/AdSupport.h>
@implementation AppDelegate {
  RootViewController *rootViewController;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  // Override point for customization after application launch.
    
    //接收自定义的通知--非 APNs
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(obserNotification:) name:kJPFNetworkDidReceiveMessageNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkDidLogin:)
                                                 name:kJPFNetworkDidLoginNotification
                                               object:nil];
    //自定义通知
    [self initAPNsWithLaunchOptions:launchOptions];
    

    [[NSBundle mainBundle] loadNibNamed:@"JpushTabBarViewController"
                                  owner:self
                                options:nil];
    self.window.rootViewController = self.rootController;
    [self.window makeKeyAndVisible];
    rootViewController = (RootViewController *)
    [self.rootController.viewControllers objectAtIndex:0];
    
    return YES;
}



#pragma mark - 注册 APNs 通知
- (void)initAPNsWithLaunchOptions:(NSDictionary *)launchOptions{

    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
    }
    
    //如不需要使用IDFA，advertisingIdentifier 可为nil
//        NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    [JPUSHService setupWithOption:launchOptions appKey:appKey
                          channel:channel
                 apsForProduction:isProduction
            advertisingIdentifier:nil];
}


#pragma mark - 接收本地的通知
- (void)application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification {
    
    [JPUSHService showLocalNotificationAtFront:notification identifierKey:nil];
    
}


- (void)applicationDidEnterBackground:(UIApplication *)application {

  [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
  [application setApplicationIconBadgeNumber:0];
  [application cancelAllLocalNotifications];
}

#pragma mark - 确定在 APP进行注册成功了

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
  rootViewController.deviceTokenValueLabel.text =
      [NSString stringWithFormat:@"%@", deviceToken];
  rootViewController.deviceTokenValueLabel.textColor =
      [UIColor colorWithRed:0.0 / 255
                      green:122.0 / 255
                       blue:255.0 / 255
                      alpha:1];
  NSLog(@"%@", [NSString stringWithFormat:@"Device Token: %@", deviceToken]);
  [JPUSHService registerDeviceToken:deviceToken];
    
    
}


#pragma mark - 在 APP 注册失败了

- (void)application:(UIApplication *)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1

//这几个基本没有用到
- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:
        (UIUserNotificationSettings *)notificationSettings {
}


- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
          forLocalNotification:(UILocalNotification *)notification
             completionHandler:(void (^)())completionHandler {
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)())completionHandler {
}
#endif

#pragma mark - 确定接收到了通知,原来有另外一个方法的通知(没有 handle),在 ios7之后已经过时了

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:
(void (^)(UIBackgroundFetchResult))completionHandler {
    
     //接收到通知后的处理--点开通知的那个栏才会来调用这里
    
    // IOS 7 Support Required
    [self handleWtihNotification:userInfo];
    
    completionHandler(UIBackgroundFetchResultNewData);
    
    
    
}

- (void)handleWtihNotification:(NSDictionary *)userInfo{
    
    [JPUSHService handleRemoteNotification:userInfo];
    
    NSLog(@"收到通知:%@", [self logDic:userInfo]);
    NSLog(@"%@",userInfo);
    
    [rootViewController addNotificationCount];
}


// log NSSet with UTF8
// if not ,log will be \Uxxx
- (NSString *)logDic:(NSDictionary *)dic {
  if (![dic count]) {
    return nil;
  }
  NSString *tempStr1 =
      [[dic description] stringByReplacingOccurrencesOfString:@"\\u"
                                                   withString:@"\\U"];
  NSString *tempStr2 =
      [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *tempStr3 =
      [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
  NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
  NSString *str =
      [NSPropertyListSerialization propertyListFromData:tempData
                                       mutabilityOption:NSPropertyListImmutable
                                                 format:NULL
                                       errorDescription:NULL];
  return str;
}
#pragma mark - 监听通知

//接收到自定义的通知,非 APNs

- (void)obserNotification:(NSNotification *)notification{
    
     NSLog(@"%s",__func__);
    NSLog(@"%@",notification.userInfo);
}


//监听已经登入获取registrationID
- (void)networkDidLogin:(NSNotification *)notification {
   
   // [JPUSHService registrationID];--获取registrationID
    
    NSLog(@"%@", [JPUSHService registrationID]);

}

@end
