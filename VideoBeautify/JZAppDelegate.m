//
//  JZAppDelegate.m
//  VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 8/4/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "JZAppDelegate.h"

@implementation JZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if ([[[UIDevice currentDevice] systemVersion]floatValue] >= 7.0)
    {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }
    else
    {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    }
    
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    _rootController = [[JZViewController alloc] init];
    _navigationController = [[UINavigationController alloc] initWithRootViewController:self.rootController];
    self.window.rootViewController = self.navigationController;
    [self.window addSubview:self.navigationController.view];
    [self.window makeKeyAndVisible];
    
    [_rootController release];
    [_navigationController release];
    
    // Register Weixi
    [WXApi registerApp:kAppWeixiKey withDescription:@"Video Beaufity"];
    
    // Override point for customization after application launch.
    return YES;
}

- (void)dealloc
{
    [_window release];
    
    [super dealloc];
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Weixi Delegate
-(void) onReq:(BaseReq*)req
{
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
        NSString *strTitle = [NSString stringWithFormat:@"微信请求App提供内容"];
        NSString *strMsg = @"微信请求App提供内容，App要调用sendResp:GetMessageFromWXResp返回给微信";
        
        NSLog(@"%@ %@",strTitle, strMsg);
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
        WXMediaMessage *msg = temp.message;
        
        // 显示微信传过来的内容
        WXAppExtendObject *obj = msg.mediaObject;
        
        NSString *strTitle = [NSString stringWithFormat:@"Content by Weixi request"];
        NSString *strMsg = [NSString stringWithFormat:@"Title：%@ \nContent：%@ \nAttach Info：%@ \nThumbnail:%u bytes\n\n", msg.title, msg.description, obj.extInfo, msg.thumbData.length];
        
        NSLog(@"%@ %@",strTitle, strMsg);
    }
    else if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        // 从微信启动App
        NSString *strTitle = [NSString stringWithFormat:@"Launch from Weixi"];
        NSString *strMsg = @"Message from Weixi";
        
        NSLog(@"%@ %@",strTitle, strMsg);
    }
}

-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        NSString *strTitle = [NSString stringWithFormat:@"Send result:"];
        NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
        
        NSLog(@"%@ %@",strTitle, strMsg);
    }
}

#pragma mark - OpenURL
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    BOOL isSuc = NO;
    if ([url.scheme isEqualToString:kAppWeixiKey])
    {
        isSuc = [WXApi handleOpenURL:url delegate:self];
        NSLog(@"WeixiUrl %@ isSuc %d",url,isSuc == YES ? 1 : 0);
    }
    else
    {
//        isSuc = [WeiboSDK handleOpenURL:url delegate:self];
//        NSLog(@"WeiboUrl %@ isSuc %d",url,isSuc == YES ? 1 : 0);
    }
    
    return isSuc;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL isSuc = NO;
    if ([url.scheme isEqualToString:kAppWeixiKey])
    {
        isSuc = [WXApi handleOpenURL:url delegate:self];
        NSLog(@"WeixiUrl %@ isSuc %d",url,isSuc == YES ? 1 : 0);
    }
    else
    {
//        isSuc = [WeiboSDK handleOpenURL:url delegate:self];
//        NSLog(@"WeiboUrl %@ isSuc %d",url,isSuc == YES ? 1 : 0);
    }
    
    return isSuc;
}

@end
