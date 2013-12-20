//
//  AppDelegate.m
//  QRScanner
//
//  Created by Oliver Drobnik on 10/12/13.
//  Copyright (c) 2013 Oliver Drobnik. All rights reserved.
//

#import "AppDelegate.h"
#import "DTCameraPreviewController.h"

// Private interface tagged with promise to implement protocol
@interface AppDelegate () <DTCameraPreviewControllerDelegate>
@end

@implementation AppDelegate
{
   // Detector for URLs in strings
   NSDataDetector *_urlDetector;
}

- (BOOL)application:(UIApplication *)application
             didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Scanner view controller is root VC of window
	DTCameraPreviewController *previewController =
            (DTCameraPreviewController *)self.window.rootViewController;
	
	// Set delegate to self
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
			
			// Prevent additional URLs from opening
			break;
		}
		else
		{
			// Some URL schemes cannot be opened
			NSLog(@"Device cannot open URL '%@'",
               [match.URL absoluteString]);
		}
	}
}

@end
