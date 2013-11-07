//
//  ViewController.m
//  Camera
//
//  Created by Oliver Drobnik on 05.11.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTCameraPreviewController.h"
#import "DTVideoPreviewView.h"


// helper function to convert interface orienation to correct video capture orientation
AVCaptureVideoOrientation DTAVCaptureVideoOrientationForUIInterfaceOrientation(UIInterfaceOrientation interfaceOrientation)
{
	switch (interfaceOrientation)
	{
		case UIInterfaceOrientationLandscapeLeft:
		{
			return AVCaptureVideoOrientationLandscapeLeft;
		}
			
		case UIInterfaceOrientationLandscapeRight:
		{
			return AVCaptureVideoOrientationLandscapeRight;
		}
			
		case UIInterfaceOrientationPortrait:
		{
			return AVCaptureVideoOrientationPortrait;
		}
			
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			return AVCaptureVideoOrientationPortraitUpsideDown;
		}
	}
}


@interface DTCameraPreviewController ()

@end

@implementation DTCameraPreviewController
{
	AVCaptureDevice *_camera;
	AVCaptureDeviceInput *_videoInput;
	AVCaptureStillImageOutput *_imageOutput;
	AVCaptureSession *_captureSession;
	DTVideoPreviewView *_videoPreview;
}


- (void)_informUserAboutCamNotAuthorized
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cam Access" message:@"Access to the camera hardward has been disabled. This disables all related functionality in this app. Please enable it via device settings." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];
}


- (void)_setupCameraAfterCheckingAuthorization
{
	AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
	
	switch (authStatus)
	{
		case AVAuthorizationStatusAuthorized:
		{
			[self _setupCamera];
			
			break;
		}
			
		case AVAuthorizationStatusNotDetermined:
		{
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
				
				// background thread, we want to setup on main thread
				dispatch_async(dispatch_get_main_queue(), ^{
					
					if (granted)
					{
						[self _setupCamera];
						
						// need to start capture session
						[_captureSession startRunning];
					}
					else
					{
						[self _informUserAboutCamNotAuthorized];
					}
				});
			}];
			
			break;
		}

		case AVAuthorizationStatusRestricted:
		case AVAuthorizationStatusDenied:
		{
			[self _informUserAboutCamNotAuthorized];
			
			break;
		}
	}
}

- (void)_setupCamera
{
	// get the camera
	_camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	// connect camera to input
	NSError *error;
	_videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&error];
	
	if (!_videoInput)
	{
		NSLog(@"Error connecting video input: %@", [error localizedDescription]);
		return;
	}
	
	// Create session (use default AVCaptureSessionPresetHigh)
	_captureSession = [[AVCaptureSession alloc] init];
	
	if (![_captureSession canAddInput:_videoInput])
	{
		NSLog(@"Unable to add video input to capture session");
		return;
	}
	
	[_captureSession addInput:_videoInput];
	
	
	_imageOutput = [AVCaptureStillImageOutput new];
	
	if (![_captureSession canAddOutput:_imageOutput])
	{
		NSLog(@"Unable to still image output to capture session");
		return;
	}
	
	[_captureSession addOutput:_imageOutput];
	
	// set the session to be previewed
	_videoPreview.previewLayer.session = _captureSession;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

	NSAssert([self.view isKindOfClass:[DTVideoPreviewView class]], @"Wrong root view class %@ in %@", NSStringFromClass([self.view class]), NSStringFromClass([self class]));
	
	_videoPreview = (DTVideoPreviewView *)self.view;
	
	[self _setupCameraAfterCheckingAuthorization];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// start session so that we don't see a black rectangle, but video
	[_captureSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[_captureSession stopRunning];
}

- (BOOL)shouldAutorotate
{
	if ([_videoPreview.previewLayer.connection isVideoOrientationSupported])
	{
		return YES;
	}
	
	// prevent UI autorotation to avoid confusing the preview layer
	return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	AVCaptureVideoOrientation captureOrientation = DTAVCaptureVideoOrientationForUIInterfaceOrientation(toInterfaceOrientation);
	
	for (AVCaptureConnection *connection in _imageOutput.connections)
	{
		if ([connection isVideoOrientationSupported])
		{
			connection.videoOrientation = captureOrientation;
		}
	}
	
	if ([_videoPreview.previewLayer.connection isVideoOrientationSupported])
	{
		_videoPreview.previewLayer.connection.videoOrientation = captureOrientation;
	}
}

#pragma mark - Actions

- (IBAction)snap:(UIButton *)sender
{
	// find correct connection
	AVCaptureConnection *videoConnection = nil;
	
	for (AVCaptureConnection *connection in _imageOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts])
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				videoConnection = connection;
				break;
			}
		}
		
		if (videoConnection)
		{
			break;
		}
	}
	
	if (!videoConnection)
	{
		NSLog(@"no video connection found");
		return;
	}
	
	[_imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		
		if (error)
		{
			NSLog(@"error capturing still image: %@", [error localizedDescription]);
			return;
		}
		
		NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
		UIImage *image = [UIImage imageWithData:imageData];
		
		UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	 }];
}

@end
