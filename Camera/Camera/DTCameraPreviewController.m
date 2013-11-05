//
//  ViewController.m
//  Camera
//
//  Created by Oliver Drobnik on 05.11.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTCameraPreviewController.h"
#import "DTVideoPreviewView.h"


@interface DTCameraPreviewController ()

@end

@implementation DTCameraPreviewController
{
	AVCaptureDevice *_camera;
	AVCaptureDeviceInput *_videoInput;
	AVCaptureSession *_captureSession;
	DTVideoPreviewView *_videoPreview;
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
	
	_videoPreview.previewLayer.session = _captureSession;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

	NSAssert([self.view isKindOfClass:[DTVideoPreviewView class]], @"Wrong root view class %@ in %@", NSStringFromClass([self.view class]), NSStringFromClass([self class]));
	
	_videoPreview = (DTVideoPreviewView *)self.view;
	
	[self _setupCamera];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (![_videoPreview.previewLayer.connection isVideoOrientationSupported])
	{
		return;
	}
	
	switch (toInterfaceOrientation)
	{
		case UIInterfaceOrientationLandscapeLeft:
		{
			_videoPreview.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
			break;
		}
			
		case UIInterfaceOrientationLandscapeRight:
		{
			_videoPreview.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
			break;
		}

		case UIInterfaceOrientationPortrait:
		{
			_videoPreview.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
			break;
		}

			
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			_videoPreview.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
			break;
		}
	}
}

#pragma mark - Actions

- (IBAction)snap:(UIButton *)sender
{
	
}

@end
