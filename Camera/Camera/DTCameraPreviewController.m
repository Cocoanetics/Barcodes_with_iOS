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
	if (![[AVCaptureDevice class] respondsToSelector:@selector(authorizationStatusForMediaType:)])
	{
		// running on iOS 6, assume authorization
		[self _setupCamera];
		
		return;
	}
	
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
						
						// need to do more setup because View Controller is already present
						[self _setupCamSwitchButton];
						[self _setupTorchToggleButton];
						
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

- (AVCaptureDevice *)_alternativeCamToCurrent
{
	if (!_camera)
	{
		// no current camera
		return nil;
	}
	
	NSArray *allCams = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	
	for (AVCaptureDevice *oneCam in allCams)
	{
		if (oneCam != _camera)
		{
			// found an alternative!
			return oneCam;
		}
	}
	
	// no alternative cameras present
	return nil;
}

- (void)_setupCamSwitchButton
{
	AVCaptureDevice *alternativeCam = [self _alternativeCamToCurrent];
	
	if (alternativeCam)
	{
		self.switchCamButton.hidden = NO;

		NSString *title;
		
		switch (alternativeCam.position)
		{
			case AVCaptureDevicePositionBack:
			{
				title = @"Back";
				break;
			}
				
			case AVCaptureDevicePositionFront:
			{
				title = @"Front";
				break;
			}

			case AVCaptureDevicePositionUnspecified:
			{
				title = @"Other";
				break;
			}
		}
		
		[self.switchCamButton setTitle:title forState:UIControlStateNormal];
	}
	else
	{
		self.switchCamButton.hidden = YES;
	}
}

- (void)_setupTorchToggleButton
{
	if ([_camera hasTorch])
	{
		self.toggleTorchButton.hidden = NO;
	}
	else
	{
		self.toggleTorchButton.hidden = YES;
	}
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
	
	[self _setupCamSwitchButton];
	[self _setupTorchToggleButton];
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

- (void)_updateConnectionsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	AVCaptureVideoOrientation captureOrientation = DTAVCaptureVideoOrientationForUIInterfaceOrientation(interfaceOrientation);
	
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self _updateConnectionsForInterfaceOrientation:toInterfaceOrientation];
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

- (IBAction)switchCam:(UIButton *)sender
{
	[_captureSession beginConfiguration];
	
	_camera = [self _alternativeCamToCurrent];
	
	// remove all old inputs
	for (AVCaptureDeviceInput *input in _captureSession.inputs)
	{
		[_captureSession removeInput:input];
	}
	
	// add new input
	_videoInput = [AVCaptureDeviceInput deviceInputWithDevice:_camera error:nil];
	[_captureSession addInput:_videoInput];
	
	// there are new connections, tell them about current UI orientation
	[self _updateConnectionsForInterfaceOrientation:self.interfaceOrientation];
	
	// update the buttons
	[self _setupCamSwitchButton];
	[self _setupTorchToggleButton];
	
	[_captureSession commitConfiguration];
}

- (IBAction)toggleTorch:(UIButton *)sender
{
	if ([_camera hasTorch])
	{
		BOOL torchActive = [_camera isTorchActive];
		
		// need to lock, without this there is an exception
		if ([_camera lockForConfiguration:nil])
		{
			if (torchActive)
			{
				if ([_camera isTorchModeSupported:AVCaptureTorchModeOff])
				{
					[_camera setTorchMode:AVCaptureTorchModeOff];
				}
			}
			else
			{
				if ([_camera isTorchModeSupported:AVCaptureTorchModeOn])
				{
					[_camera setTorchMode:AVCaptureTorchModeOn];
				}
			}
			
			[_camera unlockForConfiguration];
		}
	}
}

@end
