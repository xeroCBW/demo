//
//  AppDelegate.h
//  PushTest
//
//  Created by LiDong on 12-8-15.
//  Copyright (c) 2012年 HXHG. All rights reserved.
//

#import <UIKit/UIKit.h>
static NSString *appKey = @"d2bbcbc66a71f6bc259b04df";
static NSString *channel = @"Publish channel";
static BOOL isProduction = FALSE;

@interface AppDelegate : NSObject<UIApplicationDelegate> {
  UILabel *_infoLabel;
  UILabel *_tokenLabel;
  UILabel *_udidLabel;
}
@property(strong, nonatomic) IBOutlet UITabBarController *rootController;
@property(retain, nonatomic) UIWindow *window;

@end
