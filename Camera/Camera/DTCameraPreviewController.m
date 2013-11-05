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
	AVCaptureStillImageOutput *_imageOutput;
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
		
		
		CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
		
		if (exifAttachments)
		{
			
			
			NSLog(@"attachements: %@", exifAttachments);
		}
		else
		{
			NSLog(@"no attachments");
		}
		
		NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
		UIImage *image = [UIImage imageWithData:imageData];
		UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	 }];
}

@end
