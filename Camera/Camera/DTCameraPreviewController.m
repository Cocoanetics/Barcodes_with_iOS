//
//  ViewController.m
//  Camera
//
//  Created by Oliver Drobnik on 05.11.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTCameraPreviewController.h"

#import "DTAVFoundationFunctions.h"
#import "DTVideoPreviewView.h"

@implementation DTCameraPreviewController
{
	AVCaptureDevice *_camera;
	AVCaptureDeviceInput *_videoInput;
	AVCaptureStillImageOutput *_imageOutput;
	AVCaptureSession *_captureSession;
	DTVideoPreviewView *_videoPreview;
}

#pragma mark - Internal Methods

- (void)_informUserAboutCamNotAuthorized
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cam Access" message:@"Access to the camera hardware has been disabled. This disables all related functionality in this app. Please enable it via device settings." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];
}

- (void)_informUserAboutNoCam
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cam Access" message:@"The current device does not have any cameras installed, are you running this in iOS Simulator?" delegate:nil cancelButtonTitle:@"Yes" otherButtonTitles:nil];
	[alert show];
}

- (void)_setupCamera
{
	// get the camera
	_camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	if (!_camera)
	{
		[self.snapButton setTitle:@"No Camera Found" forState:UIControlStateNormal];
		self.snapButton.enabled = NO;
		
		[self _informUserAboutNoCam];
		
		return;
	}
	
	[self _configureCurrentCamera];
	
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
		NSLog(@"Unable to add still image output to capture session");
		return;
	}
	
	[_captureSession addOutput:_imageOutput];
	
	// set the session to be previewed
	_videoPreview.previewLayer.session = _captureSession;
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

// applies settings to the currently active camera
- (void)_configureCurrentCamera
{
	// if cam supports AV lock then we want to be able to get out of this
	if ([_camera isFocusModeSupported:AVCaptureFocusModeLocked])
	{
		if ([_camera lockForConfiguration:nil])
		{
			_camera.subjectAreaChangeMonitoringEnabled = YES;
			
			[_camera unlockForConfiguration];
		}
	}
}

// checks if there is an alternative camera to the current one
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

- (AVCaptureConnection *)_captureConnection
{
	for (AVCaptureConnection *connection in _imageOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts])
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				return connection;
				break;
			}
		}
	}
	
	// no connection found
	return nil;
}

// update all capture connections for the current interface orientation
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

// configures cam switch button
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

// configure torch button for current cam
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

#pragma mark - View Appearance

- (void)viewDidLoad
{
    [super viewDidLoad];

	NSAssert([self.view isKindOfClass:[DTVideoPreviewView class]], @"Wrong root view class %@ in %@", NSStringFromClass([self.view class]), NSStringFromClass([self class]));
	
	_videoPreview = (DTVideoPreviewView *)self.view;
	
	[self _setupCameraAfterCheckingAuthorization];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	[self.view addGestureRecognizer:tap];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectChanged:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
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

#pragma mark - Interface Rotation

// for demonstration all orientations are supported
- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	// need to update capture and preview connections
	[self _updateConnectionsForInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - Actions

- (IBAction)snap:(UIButton *)sender
{
	if (!_camera)
	{
		return;
	}
	
	// find correct connection
	AVCaptureConnection *videoConnection = [self _captureConnection];
	
	if (!videoConnection)
	{
		NSLog(@"Error: No Video connection found on still image output");
		return;
	}
	
	[_imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		
		if (error)
		{
			NSLog(@"Error capturing still image: %@", [error localizedDescription]);
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
	[self _configureCurrentCamera];
	
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
	
	[_captureSession commitConfiguration];
	
	// update the buttons
	[self _setupCamSwitchButton];
	[self _setupTorchToggleButton];
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

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateRecognized)
	{
		// require both focus point and autofocus
		if (![_camera isFocusPointOfInterestSupported] || ![_camera isFocusModeSupported:AVCaptureFocusModeAutoFocus])
		{
			NSLog(@"Focus Point Not Supported by current camera");
			
			return;
		}
		
		CGPoint locationInPreview = [gesture locationInView:_videoPreview];
		CGPoint locationInCapture = [_videoPreview.previewLayer captureDevicePointOfInterestForPoint:locationInPreview];
		
		if ([_camera lockForConfiguration:nil])
		{
			// this alone does not trigger focussing
			[_camera setFocusPointOfInterest:locationInCapture];
			
			// this focusses once and then changes to locked
			[_camera setFocusMode:AVCaptureFocusModeAutoFocus];
			
			NSLog(@"Focus Mode: Locked to Focus Point");

			[_camera unlockForConfiguration];
		}
	}
}

#pragma mark - Notifications

- (void)subjectChanged:(NSNotification *)notification
{
	// switch back to continuous auto focus mode
	if (_camera.focusMode == AVCaptureFocusModeLocked)
	{
		if ([_camera lockForConfiguration:nil])
		{
			// restore default focus point
			if ([_camera isFocusPointOfInterestSupported])
			{
				_camera.focusPointOfInterest = CGPointMake(0.5, 0.5);
			}
			
			// this focusses once and then changes to locked
			if ([_camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
			{
				[_camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			}
			
			NSLog(@"Focus Mode: Continuos");
		}
	}
}

@end
