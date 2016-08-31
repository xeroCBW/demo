
JPush 集成过程中遇到了很多坑,目前总结如下:

###经验总结

1. 制作证书一定要用有推送功能的账号

	![制作 cer](http://upload-images.jianshu.io/upload_images/874748-29d9a52d0eb494fe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/400)

2. 一定要使用真机
3. jpush 定义的那个通知kJPFNetworkDidReceiveMessageNotification;是用于自定义的通知使用,不是 apps
4. 可以不用 plist 文件,老的方法需要使用 plist
 
	 ```
	  //Required
	  // 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
	  [JPUSHService setupWithOption:launchOptions appKey:appKey
	                        channel:channel
	               apsForProduction:isProduction
	          advertisingIdentifier:advertisingId];
	
	  return YES;
	  
	  ```
老的方法
		
	```
	// 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
	````

5. 看别人的 sdk, 一定要看 demo;先下 demo 再去看文档
6. JPush 开始先注册,以后每次是app 一启动进行登陆;
7. app 完全退出后,还可以接收到通知
9. 除此之外，应用已经在前台时，远程推送是无法直接显示的，要先捕获到远程来的通知，然后再发起一个本地通知才能完成现实。
10. 在发起一个远程通知,也不可以实现下拉的样式,只能自己设置代码,例如 alertView 等样式

###实际操作

1. 配置证书--按照 JPush 给的文档进行配置(一定要用开发者账号去导出 csr, 不能想当然是用自己 iclound账号)

	
	1. [iOS 证书 设置指南](http://docs.jiguang.cn/client/ios_tutorials/#ios_1)
	2. [iOS SDK 集成指南](http://docs.jiguang.cn/guideline/ios_guide/#sdk)

2. 下载 demo, 修改成自己申请的appkey, 配置好证书--provision 
3. 运行既可以

###代码梳理

1. 在didFinishLaunchingWithOptions初始化 JPush

	1.使用 infoplist 就要是用老的方法
	

	```
[JPUSHService setupWithOption:launchOptions];//JPush 2.1.0 版本已过期
```
	
	2.advertisingIdentifier设置成 nil 就可以,因为一般不要IFDA
	
	```
	 // 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
		    [JPUSHService setupWithOption:launchOptions appKey:appKey
		                          channel:channel
		                 apsForProduction:isProduction
		            advertisingIdentifier:nil];
```

2. didRegisterForRemoteNotificationsWithDeviceToken在 APPLe注册成功后会返回一个 DeviceToken,我们使用这个 DeviceToken注册 JPush

	1. 苹果APNs的编码技术和deviceToken的独特作用保证了他的唯一性。唯一性并不是说一台设备上的一个应用程序永远只有一个deviceToken，当用户升级系统的时候deviceToken是会变化的。
	2. JPush 帮我们同时注册了本地和远程的通知:原因,apple 注册通知只有一个方法,包括远程和本地

	```
	[JPUSHService registerDeviceToken:deviceToken];
	```
3. didFailToRegisterForRemoteNotificationsWithError,失败回调可以用来提醒


4. 处理接收到远程通知消息（会回调以下方法中的某一个）

	1.application: didFinishLaunchingWithOptions:此方法在程序第一次启动是调用，也就是说App从Terminate状态进入Foreground状态的时候，根据方法内代码判断是否有推送消息。


	```
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	    //  userInfo为收到远程通知的内容
	    NSDictionary *userInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
	    if (userInfo) {
	         // 有推送的消息，处理推送的消息
	    }
	    return YES；
	}
	application: didReceiveRemoteNotification:
	
	```

	2.如果App处于Background状态时，只用用户点击了通知消息时才会调用该方法；如果App处于Foreground状态，会直接调用该方法。



	```
		- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {}
		
	
	//先执行 JPush 的一些方法
	 [JPUSHService handleRemoteNotification:userInfo];
	 completionHandler(UIBackgroundFetchResultNewData);
	 
	 //添加自己的方法--后台可以在推送的时候增加字段,这个时候就可以自己处理啦
	 
	```


5.定点发送通知--特定设备(registrationID)

1. didFinishLaunchingWithOptions注册通知`kJPFNetworkDidLoginNotification`

	```
	 [[NSNotificationCenter defaultCenter] addObserver:self
	                      selector:@selector(networkDidLogin:)
	                          name:kJPFNetworkDidLoginNotification
	                        object:nil];
	```
2. 将registrationID打印出来,我们就可以对特定设备发通知了

	```
	//监听已经登入获取registrationID
	- (void)networkDidLogin:(NSNotification *)notification {
	   
	   // [JPUSHService registrationID];--获取registrationID
	    
	    NSLog(@"%@", [JPUSHService registrationID]);
	
	}
	```
3. kJPFNetworkDidLoginNotification对于一次安装只会调用一次;didFinishLaunchingWithOptions每次登入都会调用

6.非 APNs 处理

1. 在didFinishLaunchingWithOptions注册通知,kJPFNetworkDidReceiveMessageNotification--偏 message 的功能

	
	```
	
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(obserNotification:) name:kJPFNetworkDidReceiveMessageNotification object:nil];
	```

2. 对数据进行解析

	```
	
	- (void)obserNotification:(NSNotification *)notification{
	    
	     NSLog(@"%s",__func__);
	    NSLog(@"%@",notification.userInfo);
	}
	
	
	```
	
###参考资料

[iOS推送之远程推送（iOS Notification Of Remote Notification）](http://www.jianshu.com/p/4b947569a548)

[iOS推送之本地推送（iOS Notification Of Local Notification）](http://www.jianshu.com/p/77ee3b98c132)
	
[demo 地址](https://github.com/xeroxmx/demo.git)
