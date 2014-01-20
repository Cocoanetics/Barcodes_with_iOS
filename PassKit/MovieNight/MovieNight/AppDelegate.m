//
//  AppDelegate.m
//  MovieNight
//
//  Created by Oliver Drobnik on 17.01.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "AppDelegate.h"
#import "DTCameraPreviewController.h"
#import <CommonCrypto/CommonCrypto.h>

// Private interface tagged with promise to implement protocol
@interface AppDelegate () <DTCameraPreviewControllerDelegate>
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Scanner view controller is root VC of window
	DTCameraPreviewController *previewController =
	(DTCameraPreviewController *)self.window.rootViewController;
	
	// Set delegate to self
	previewController.delegate = self;
	
    // Override point for customization after application launch.
    return YES;
}
							
#pragma mark - DTCameraPreviewControllerDelegate

- (NSString *)_MD5ForString:(NSString *)string
{
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t digest[CC_MD5_DIGEST_LENGTH];
	
	CC_MD5(data.bytes, (CC_LONG)data.length, digest);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	{
		[output appendFormat:@"%02x", digest[i]];
	}
	
	return output;
}

- (void)previewController:(DTCameraPreviewController *)previewController
              didScanCode:(NSString *)code
                   ofType:(NSString *)type
{
	// check for ticket
	if (![code hasPrefix:@"TICKET:"])
	{
		return;
	}
	
	// split off signature
	NSArray *components = [code componentsSeparatedByString:@"|"];
	
	// ignore ticket without signature
	if (![components count] == 2)
	{
		NSLog(@"Ticket without Signature ignored");
		return;
	}
	
	NSString *salt = @"EXTRA SECRET SAUCE";
	NSString *saltedDetails = [components[0] stringByAppendingString:salt];
	NSString *signature = components[1];
	
	NSString *verify = [self _MD5ForString:saltedDetails];
	
	if (![signature isEqualToString:verify])
	{
		NSLog(@"Ticket has invalid signature");
		return;
	}
	
	NSLog(@"Bingo!");
}

@end
