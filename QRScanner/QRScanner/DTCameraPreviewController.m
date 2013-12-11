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


// private interface to tag with metadata delegate protocol
@interface DTCameraPreviewController () <AVCaptureMetadataOutputObjectsDelegate>
@end

@implementation DTCameraPreviewController
{
	AVCaptureDevice *_camera;
	AVCaptureDeviceInput *_videoInput;
	AVCaptureStillImageOutput *_imageOutput;
	AVCaptureSession *_captureSession;
	DTVideoPreviewView *_videoPreview;
	
	AVCaptureMetadataOutput *_metaDataOutput;
	dispatch_queue_t _metaDataQueue;
	
	NSMutableSet *_visibleCodes;
	NSMutableDictionary *_visibleCodeShapes;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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


- (void)_setupMetadataOutput
{
	// create a new metadata output
	_metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
	
	// create a GCD queue on which recognized codes are to be delivered
	//_metaDataQueue = dispatch_queue_create("com.cocoanetics.metadata", NULL);
	_metaDataQueue = dispatch_get_main_queue();

	// set self as delegate, using the background queue
	[_metaDataOutput setMetadataObjectsDelegate:self queue:_metaDataQueue];
	
	// connect meta data output only if possible
	if (![_captureSession canAddOutput:_metaDataOutput])
	{
		NSLog(@"Unable to add meta data output to capture session");
		return;
	}
	
	// connect it
	[_captureSession addOutput:_metaDataOutput];
	 
	 // specify to scan for supported 2D barcode types
	NSArray *barcodes2D = @[AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
	NSArray *availableTypes = [_metaDataOutput availableMetadataObjectTypes];
	
	if (![availableTypes count])
	{
		NSLog(@"Unable to get any available metadata types, did you forget the addOutput: on the capture session?");
		return;
	}
	
	// be extra defensive: only adds supported types, log unsupported
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (NSString *oneCodeType in barcodes2D)
	{
		if ([availableTypes containsObject:oneCodeType])
		{
			[tmpArray addObject:oneCodeType];
		}
		else
		{
			NSLog(@"Weird: Code type '%@' is not reported as supported on this device", oneCodeType);
		}
	}
	
	_metaDataOutput.metadataObjectTypes = tmpArray;
	
	if ([tmpArray count])
	{
		 _metaDataOutput.metadataObjectTypes = tmpArray;
	}
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

	// configure cam here because active format depends on capture session
	[self _configureCurrentCamera];
	
	// add still image output
	_imageOutput = [AVCaptureStillImageOutput new];
	
	if (![_captureSession canAddOutput:_imageOutput])
	{
		NSLog(@"Unable to add still image output to capture session");
		return;
	}
	
	[_captureSession addOutput:_imageOutput];
	
	// set the session to be previewed
	_videoPreview.previewLayer.session = _captureSession;
	
	// setup the barcode scanner output
	[self _setupMetadataOutput];
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
			
			if ([_camera isSmoothAutoFocusSupported])
			{
				_camera.smoothAutoFocusEnabled = YES;
			}
			
			// get more pixels to image outputs
			_camera.videoZoomFactor = MIN(_camera.activeFormat.videoZoomFactorUpscaleThreshold, 1.25);
			
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
	
	// default is resize aspect, we need aspect fill to avoid side bars on iPad
	[_videoPreview.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	
	[self _setupCameraAfterCheckingAuthorization];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	[self.view addGestureRecognizer:tap];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectChanged:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// need to update capture and preview connections
	[self _updateConnectionsForInterfaceOrientation:self.interfaceOrientation];
	
	// start session so that we don't see a black rectangle, but video
	[_captureSession startRunning];
	
	[self _setupCamSwitchButton];
	[self _setupTorchToggleButton];
	
	_visibleCodes = [NSMutableSet new];
	_visibleCodeShapes = [NSMutableDictionary new];
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

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
	// set to take on codes that this pass of the method is reporting
	NSMutableSet *reportedCodes = [NSMutableSet set];
	
	// dictionary to count the number of occurences of a type+stringValue
	NSMutableDictionary *reportedCodesCount = [NSMutableDictionary dictionary];
	
	for (AVMetadataMachineReadableCodeObject *object in metadataObjects)
	{
		if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]] && object.stringValue)
		{
			NSString *code = [NSString stringWithFormat:@"%@:%@", object.type, object.stringValue];
			
			// get the number of times this code was reported before in this loop
			NSUInteger occurencesOfCode = [reportedCodesCount[code] unsignedIntegerValue] + 1;
			reportedCodesCount[code] = @(occurencesOfCode);
			NSString *numberedCode = [code stringByAppendingFormat:@"-%lu", (unsigned long)occurencesOfCode];

			// if it was not previously visible it is new
			if (![_visibleCodes containsObject:numberedCode])
			{
				NSLog(@"code appeared: %@", numberedCode);
				
				if ([_delegate respondsToSelector:@selector(previewController:didScanCode:ofType:)])
				{
					[_delegate previewController:self didScanCode:object.stringValue ofType:object.type];
				}
			}

			[reportedCodes addObject:numberedCode];

			// create a suitable CGPath for the barcode area
			CGPathRef path = DTAVMetadataMachineReadableCodeObjectCreatePathForCorners(_videoPreview.previewLayer, object);
			
			// get previous shape for this code
			CAShapeLayer *shapeLayer = _visibleCodeShapes[numberedCode];
			
			// if none found then this is a new shape
			if (!shapeLayer)
			{
				shapeLayer = [CAShapeLayer layer];
				
				// basic configuration, stays the same regardless of path
				shapeLayer.strokeColor = [UIColor greenColor].CGColor;
				shapeLayer.fillColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.25].CGColor;
				shapeLayer.lineWidth = 2;

				[_videoPreview.layer addSublayer:shapeLayer];
				
				// add it to shape dictionary
				_visibleCodeShapes[numberedCode] = shapeLayer;
			}
			
			// configure shape, relative to video preview
			shapeLayer.frame = _videoPreview.bounds;
			shapeLayer.path = path;
			
			// need to release the path now
			CGPathRelease(path);
		}
	}
	
	// check which codes which we saw in previous cycle are no longer present
	for (NSString *oneCode in _visibleCodes)
	{
		if (![reportedCodes containsObject:oneCode])
		{
			NSLog(@"code disappeared: %@", oneCode);
			
			CAShapeLayer *shape = _visibleCodeShapes[oneCode];
			
			[shape removeFromSuperlayer];
			[_visibleCodeShapes removeObjectForKey:oneCode];
		}
	}
	
	_visibleCodes = reportedCodes;
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
	
	// configure camera after session changes
	[self _configureCurrentCamera];
	
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
			
			if ([_camera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
			{
				[_camera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			}
			
			NSLog(@"Focus Mode: Continuos");
		}
	}
}

@end
