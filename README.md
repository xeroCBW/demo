
JPush 集成过程中遇到了很多坑,目前总结如下:

###经验总结

1. 证书一定要用开发者的
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
8. 旺钱包-获取或刷新消息列表/旺钱包-获取或刷新最新消息—这个是我们请求数据等到的

服务器端—http://docs.jiguang.cn/server/csharp_sdk/#_1

1.可以设置多个参数—确定是用别名发的/还是用registrationId发的?

public static Audience s_alias(params string[] values) //推送给多个别名，参数为："xxxxx1","xxxxxx2","xxxxxx3"
2.服务器增加的字段—平台

￼
3.使用Push-API-v3发送推送信息

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

2. didRegisterForRemoteNotificationsWithDeviceToken在 APPLe注册成功后,注册 JPush

	```
	[JPUSHService registerDeviceToken:deviceToken];
	```
3. didFailToRegisterForRemoteNotificationsWithError,失败回调可以用来提醒
4. didReceiveRemoteNotification接收到通知后进行处理

```
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
	
	[demo 地址](https://github.com/xeroxmx/demo.git)
