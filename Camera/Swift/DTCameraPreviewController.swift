//
//  DTCameraPreviewController.swift
//  Camera
//
//  Created by Geoff Breemer on 11/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import UIKit
import AVFoundation
import Dispatch

@objc(DTCameraPreviewController) class DTCameraPreviewController : UIViewController
{
    @IBOutlet var switchCamButton: UIButton?
    @IBOutlet var toggleTorchButton: UIButton?
    @IBOutlet var snapButton: UIButton?
    
    private var _camera: AVCaptureDevice?
    private var _videoInput: AVCaptureDeviceInput?
    private var _imageOutput: AVCaptureStillImageOutput?
    private var _captureSession: AVCaptureSession?
    private var _videoPreview: DTVideoPreviewView?
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Internal Methods
    
    func _informUserAboutCamNotAuthorized()
    {
        let alert: UIAlertView = UIAlertView(title: "Cam Access", message: "Access to the camera hardware has been disabled. This disables all related functionality in this app. Please enable it via device settings.", delegate:nil, cancelButtonTitle:"Ok")
        alert.show()
    }
    
    func _informUserAboutNoCam()
    {
        let alert: UIAlertView = UIAlertView(title: "Cam Access", message: "The current device does not have any cameras installed, are you running this in iOS Simulator?", delegate: nil, cancelButtonTitle: "Yes")
        alert.show()
    }
    
    func _setupCamera()
    {
        // get the default camera, usually the one on the back
        _camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if (_camera == nil)
        {
            snapButton!.setTitle("No Camera Found", forState: .Normal)
            snapButton!.enabled = false
            
            _informUserAboutNoCam()
            return
        }
        
        _configureCurrentCamera()
        
        // connect camera to input
        var error: NSError?
        _videoInput = AVCaptureDeviceInput(device: _camera, error: &error)
        
        if (error != nil)
        {
            println("Error connecting video input: %@", error!.localizedDescription)
            return
        }
        
        // Create session (use default AVCaptureSessionPresetHigh)
        _captureSession = AVCaptureSession()
        
        if (_captureSession!.canAddInput(_videoInput) == false)
        {
            println("Unable to add video input to capture session")
            return
        }
        
        _captureSession!.addInput(_videoInput)
        
        // add still image output
        _imageOutput = AVCaptureStillImageOutput()
        
        if (_captureSession!.canAddOutput(_imageOutput) == false)
        {
            println("Unable to add still image output to capture session")
            return
        }
        
        _captureSession!.addOutput(_imageOutput)
        
        // set the session to be previewed
        _videoPreview!.previewLayer.session = _captureSession
    }
    
    func _setupCameraAfterCheckingAuthorization()
    {
        // Note: iOS6 check included here before is not required: Swift requires at least iOS7
        
        let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        switch (authStatus)
            {
        case .Authorized:
            _setupCamera()
            
        case .NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
                [unowned self]
                (granted: Bool) -> Void in
                
                // background thread, we want to setup on main thread
                dispatch_async(dispatch_get_main_queue(), {
                    if (granted)
                    {
                        self._setupCamera()
                        
                        // need to do more setup because View Controller is already present
                        self._setupCamSwitchButton()
                        self._setupTorchToggleButton()
                        
                        // need to start capture session
                        self._captureSession!.startRunning()
                    }
                    else
                    {
                        self._informUserAboutCamNotAuthorized()
                    }
                })
            })
        case .Restricted, .Denied:
            _informUserAboutCamNotAuthorized()
        }
    }
    
    // applies settings to the currently active camera
    func _configureCurrentCamera()
    {
        // if cam supports AV lock then we want to be able to get out of this
        if (_camera!.isFocusModeSupported(.Locked))
        {
            if (_camera!.lockForConfiguration(nil))
            {
                _camera!.subjectAreaChangeMonitoringEnabled = true
                _camera!.unlockForConfiguration()
            }
        }
    }
    
    // checks if there is an alternative camera to the current one
    func _alternativeCamToCurrent() -> AVCaptureDevice?
    {
        if (_camera == nil)
        {
            // no current camera
            return nil
        }
        
        var allCams: NSArray = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
        for oneCam in allCams
        {
            if (oneCam as? AVCaptureDevice != _camera)
            {
                // found an alternative!
                return oneCam as? AVCaptureDevice
            }
        }
        
        // no alternative cameras present
        return nil
    }
    
    func _captureConnection() -> AVCaptureConnection?
    {
        for connection in _imageOutput!.connections
        {
            for port in (connection as AVCaptureConnection).inputPorts
            {
                if (port.mediaType == AVMediaTypeVideo)
                {
                    return connection as? AVCaptureConnection
                }
            }
        }
        
        // no connection found
        return nil
    }
    
    // update all capture connections for the current interface orientation
    func _updateConnectionsForInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation)
    {
        var captureOrientation: AVCaptureVideoOrientation = DTAVCaptureVideoOrientationForUIInterfaceOrientation(interfaceOrientation)
        
        for connection in _imageOutput!.connections!
        {
            if ((connection as? AVCaptureConnection)!.supportsVideoOrientation)
            {
                (connection as? AVCaptureConnection)!.videoOrientation = captureOrientation
            }
        }
        
        let con: AVCaptureConnection = _videoPreview!.previewLayer.connection
        
        if (con.supportsVideoOrientation)
        {
            con.videoOrientation = captureOrientation
        }
    }
    
    // configures cam switch button
    func _setupCamSwitchButton()
    {
        var alternativeCam: AVCaptureDevice? = _alternativeCamToCurrent()
        
        if (alternativeCam != nil)
        {
            switchCamButton!.hidden = false
            
            var title: NSString
            
            switch (alternativeCam!.position)
                {
            case .Back:
                title = "Back"
            case .Front:
                title = "Front"
            case .Unspecified:
                title = "Other"
            }
            
            switchCamButton!.setTitle(title, forState:.Normal)
        }
        else
        {
            switchCamButton!.hidden = true
        }
    }
    
    // configure torch button for current cam
    func _setupTorchToggleButton()
    {
        if let _camera = _camera {
            if (_camera.hasTorch)
            {
                toggleTorchButton!.hidden = false
            }
        }
        else
        {
            toggleTorchButton!.hidden = true
        }
    }
    
    // MARK: - View Appearance
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.view is DTVideoPreviewView, "Wrong root view class \(NSStringFromClass(self.view!.dynamicType)) in \(NSStringFromClass(self.dynamicType))")
        
        _videoPreview = self.view as? DTVideoPreviewView
        
        _setupCameraAfterCheckingAuthorization()
        
        var tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        
        self.view.addGestureRecognizer(tap)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"subjectChanged:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // start session so that we don't see a black rectangle, but video
        _captureSession?.startRunning()

        _setupCamSwitchButton()
        _setupTorchToggleButton()
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        _captureSession!.stopRunning()
    }
    
    override func shouldAutorotate() -> Bool
    {
        if let connection = _videoPreview?.previewLayer.connection
        {
            if connection.supportsVideoOrientation {
                return true
            }
        }
        
        // prevent UI autorotation to avoid confusing the preview layer
        return false
    }
    
    // MARK: - Interface Rotation
    
    // for demonstration all orientations are supported
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval)
    {
        
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        // need to update capture and preview connections
        _updateConnectionsForInterfaceOrientation(toInterfaceOrientation)
    }
    
    // MARK: - Actions
    
    @IBAction func snap(sender: UIButton)
    {
        if (_camera == nil)
        {
            return
        }
        
        // find correct connection
        let videoConnection: AVCaptureConnection? = _captureConnection()
        
        if (videoConnection == nil)
        {
            println("Error: No Video connection found on still image output")
            return
        }
        
        _imageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection!, completionHandler: { (imageSampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            if (error != nil)
            {
                println("Error capturing still image: \(error.localizedDescription)")
                return
            }
            
            let imageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
            let image: UIImage = UIImage(data: imageData)!
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
        })
    }
    
    @IBAction func switchCam(sender: UIButton)
    {
        _captureSession!.beginConfiguration()
        
        _camera = _alternativeCamToCurrent()
        _configureCurrentCamera()
        
        // remove all old inputs
        for input in _captureSession!.inputs
        {
            _captureSession!.removeInput(input as AVCaptureInput)
        }
        
        // add new input
        _videoInput = AVCaptureDeviceInput(device: _camera, error: nil)
        _captureSession!.addInput(_videoInput)
        
        // there are new connections, tell them about current UI orientation
        _updateConnectionsForInterfaceOrientation(self.interfaceOrientation)
        
        _captureSession!.commitConfiguration()
        
        // update the buttons
        _setupCamSwitchButton()
        _setupTorchToggleButton()
    }
    
    @IBAction func toggleTorch(sender: UIButton)
    {
        if (_camera!.hasTorch)
        {
            let torchActive: Bool = _camera!.torchActive
            
            // need to lock, without this there is an exception
            if (_camera!.lockForConfiguration(nil))
            {
                if (torchActive)
                {
                    if (_camera!.isTorchModeSupported(.Off))
                    {
                        _camera!.torchMode = .Off
                    }
                }
                else
                {
                    if (_camera!.isTorchModeSupported(.On))
                    {
                        _camera!.torchMode = .On
                    }
                }
                
                _camera!.unlockForConfiguration()
            }
        }
    }
    
    func handleTap(gesture: UITapGestureRecognizer)
    {
        if (_camera == nil)
        {
            return
        }
        
        if (gesture.state == .Ended)
        {
            // require both focus point and autofocus
            if ( (_camera!.focusPointOfInterestSupported == false) || (_camera!.isFocusModeSupported(.AutoFocus) == false))
            {
                println("Focus Point Not Supported by current camera")
                return
            }
            
            let locationInPreview: CGPoint = gesture.locationInView(_videoPreview)
            let locationInCapture: CGPoint = _videoPreview!.previewLayer.captureDevicePointOfInterestForPoint(locationInPreview)
            
            if (_camera!.lockForConfiguration(nil) == true)
            {
                // this alone does not trigger focussing
                _camera!.focusPointOfInterest = locationInCapture
                
                // this focusses once and then changes to locked
                _camera!.focusMode = .AutoFocus
                
                println("Focus Mode: Locked to Focus Point")
                
                _camera!.unlockForConfiguration()
            }
        }
    }
    
    // MARK: - Notifications
    
    func subjectChanged(notification: NSNotification)
    {
        // switch back to continuous auto focus mode
        if (_camera!.focusMode == .Locked)
        {
            if (_camera!.lockForConfiguration(nil))
            {
                // restore default focus point
                if (_camera!.focusPointOfInterestSupported)
                {
                    _camera!.focusPointOfInterest = CGPointMake(0.5, 0.5)
                }
                
                if (_camera!.isFocusModeSupported(.ContinuousAutoFocus))
                {
                    _camera!.focusMode = .ContinuousAutoFocus
                }
                
                println("Focus Mode: Continuous")
            }
        }
    }
    
}

