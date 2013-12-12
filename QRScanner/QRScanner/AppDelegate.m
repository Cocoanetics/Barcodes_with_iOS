//
//  AppDelegate.m
//  QRScanner
//
//  Created by Oliver Drobnik on 10/12/13.
//  Copyright (c) 2013 Oliver Drobnik. All rights reserved.
//

#import "AppDelegate.h"
#import "DTCameraPreviewController.h"


@interface AppDelegate () <DTCameraPreviewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
	DTCameraPreviewController *previewController = (DTCameraPreviewController *)self.window.rootViewController;
	
	previewController.delegate = self;
	
	
    return YES;
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

#pragma mark - DTCameraPreviewControllerDelegate

- (void)previewController:(DTCameraPreviewController *)previewController didScanCode:(NSString *)code ofType:(NSString *)type
{
	NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:NULL];
	
	NSRange entireString = NSMakeRange(0, [code length]);
	NSArray *matches = [detector matchesInString:code options:0 range:entireString];
	
	for (NSTextCheckingResult *match in matches)
	{
		if ([[UIApplication sharedApplication] canOpenURL:match.URL])
		{
			NSLog(@"Opening URL '%@' in external browser", [match.URL absoluteString]);
			[[UIApplication sharedApplication] openURL:match.URL];
			
			// prevent additional URLs from opening
			break;
		}
		else
		{
			// some URL schemes cannot be opened
			NSLog(@"Device cannot open URL '%@'", [match.URL absoluteString]);
		}
	}
}


@end
