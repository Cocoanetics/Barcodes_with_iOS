//
//  AppDelegate.m
//  QRScanner
//
//  Created by Oliver Drobnik on 10/12/13.
//  Copyright (c) 2013 Oliver Drobnik. All rights reserved.
//

#import "AppDelegate.h"
#import "DTCameraPreviewController.h"

// private interface taggs with promise to implement protocol
@interface AppDelegate () <DTCameraPreviewControllerDelegate>
@end

@implementation AppDelegate
{
   // detector for URLs in strings
   NSDataDetector *_urlDetector;
}

- (BOOL)application:(UIApplication *)application
             didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// preview VC is root VC of window
	DTCameraPreviewController *previewController =
            (DTCameraPreviewController *)self.window.rootViewController;
	
	// set delegate to self
	previewController.delegate = self;

   // configure URL detector
	_urlDetector = [NSDataDetector dataDetectorWithTypes:
                             (NSTextCheckingTypes)NSTextCheckingTypeLink
                                                  error:NULL];
   
    return YES;
}
							
#pragma mark - DTCameraPreviewControllerDelegate

- (void)previewController:(DTCameraPreviewController *)previewController
              didScanCode:(NSString *)code
                   ofType:(NSString *)type
{
	NSRange entireString = NSMakeRange(0, [code length]);
	NSArray *matches = [_urlDetector matchesInString:code
                                            options:0
                                              range:entireString];
	
	for (NSTextCheckingResult *match in matches)
	{
		if ([[UIApplication sharedApplication] canOpenURL:match.URL])
		{
			NSLog(@"Opening URL '%@' in external browser",
               [match.URL absoluteString]);
			[[UIApplication sharedApplication] openURL:match.URL];
			
			// prevent additional URLs from opening
			break;
		}
		else
		{
			// some URL schemes cannot be opened
			NSLog(@"Device cannot open URL '%@'",
               [match.URL absoluteString]);
		}
	}
}


@end
