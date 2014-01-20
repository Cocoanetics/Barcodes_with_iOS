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
{
	UIAlertView *alert;
}

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

- (void)_reportValidTicketDate:(NSDate *)date seat:(NSString *)seat
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	
	NSString *msgDate = [formatter stringFromDate:date];
	NSString *msg = [NSString stringWithFormat:@"Seat %@\n%@", seat, msgDate];
	
	alert = [[UIAlertView alloc] initWithTitle:@"Ticket Ok"
																	message:msg
																  delegate:self
													  cancelButtonTitle:@"Ok"
													  otherButtonTitles:nil];
	[alert show];
}

- (void)_reportInvalidTicket:(NSString *)msg
{
	alert = [[UIAlertView alloc] initWithTitle:@"Invalid Ticket"
																	message:msg
																  delegate:self
													  cancelButtonTitle:@"Ok"
													  otherButtonTitles:nil];
	[alert show];
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
	// don't handle if alert showing
	if ([alert isVisible])
	{
		return;
	}
	
	// check for ticket
	if (![code hasPrefix:@"TICKET:"])
	{
		return;
	}
	
	// split off signature
	NSArray *components = [code componentsSeparatedByString:@"|"];
	
	// ignore ticket without signature
	if ([components count] != 2)
	{
		NSLog(@"Ticket without Signature ignored");
		return;
	}
	
	// server-less verification
	NSString *salt = @"EXTRA SECRET SAUCE";
	NSString *details = components[0];
	NSString *saltedDetails = [details stringByAppendingString:salt];
	NSString *signature = components[1];
	NSString *verify = [self _MD5ForString:saltedDetails];
	
	if (![signature isEqualToString:verify])
	{
		[self _reportInvalidTicket:@"Ticket has invalid signature"];

		return;
	}
	
	// skip prefix
	NSString *ticket = [details substringFromIndex:7];
	NSArray *comps = [ticket componentsSeparatedByString:@","];
	
	NSString *dateStr = comps[0];
	NSString *seat = comps[1];
	//	NSString *serial = comps[2];
	
	NSDateFormatter *parser = [[NSDateFormatter alloc] init];
	parser.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZ";
	NSDate *date = [parser dateFromString:dateStr];
	
	// check if event date no futher than 1 hour away
	NSTimeInterval intervalToNow = [date timeIntervalSinceNow];
	
	if (intervalToNow < 3600)
	{
		[self _reportInvalidTicket:@"Event on this ticket is more than 60 mins in the past"];
		
		return;
	}

	if (intervalToNow > 3600)
	{
		[self _reportInvalidTicket:@"Event on this ticket is more than 60 mins in the future"];
		
		return;
	}
	
	// ticket is valid, so let's report that
	[self _reportValidTicketDate:date seat:seat];
}

@end
