//
//  DTCameraPreviewController.swift
//  QRScanner
//
//  Created by Geoff Breemer on 11/10/14.
//  Copyright (c) 2014 Oliver Drobnik. All rights reserved.
//

import UIKit
import AVFoundation
import Dispatch
import CoreGraphics

/**
protocol for receiving updates on newly visible barcodes
*/
@objc protocol DTCameraPreviewControllerDelegate
{
    optional func previewController(previewController: DTCameraPreviewController, didScanCode code: NSString, ofType type: NSString)
}

@objc(DTCameraPreviewController) class DTCameraPreviewController : UIViewController
{
    @IBOutlet var switchCamButton: UIButton?
    @IBOutlet var toggleTorchButton: UIButton?
    @IBOutlet var snapButton: UIButton?
    @IBOutlet var iBox: DTVideoPreviewInterestBox?
    @IBOutlet var delegate: DTCameraPreviewControllerDelegate?
    
    private var _camera: AVCaptureDevice?
    private var _videoInput: AVCaptureDeviceInput?
    private var _imageOutput: AVCaptureStillImageOutput?
    private var _captureSession: AVCaptureSession?
    private var _videoPreview: DTVideoPreviewView?
    
    private var _metaDataOutput: AVCaptureMetadataOutput?
    private var _metaDataQueue: dispatch_queue_t?
    
    private var _visibleCodes: NSMutableSet?
    private var _visibleShapes: Dictionary<String, CAShapeLayer>? = [:]
    
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
    
    func _setupMetadataOutput()
    {
        // Create a new metadata output
        _metaDataOutput =  AVCaptureMetadataOutput()
        
        // GCD queue on which delegate method is called
        _metaDataQueue = dispatch_get_main_queue()
        
        // Set self as delegate, using the specified GCD queue
        _metaDataOutput?.setMetadataObjectsDelegate(self, queue: _metaDataQueue)
        
        // Connect metadata output only if possible
        if (!_captureSession!.canAddOutput(_metaDataOutput))
        {
            println("Unable to add metadata output to capture session")
            return
        }
        
        // Connect metadata output to capture session
        _captureSession!.addOutput(_metaDataOutput)
        
        // Specify to scan for supported 2D barcode types
        let barcodes2D: NSArray = [AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode]
        let availableTypes: NSArray = _metaDataOutput!.availableMetadataObjectTypes
        
        if (availableTypes.count == 0)
        {
            println("Unable to get any available metadata types, did you forget the addOutput: on the capture session?")
            return
        }
        
        // Extra defensive: only adds supported types, log unsupported
        var tmpArray: [String] = []
        
        for oneCodeType in barcodes2D
        {
            if (availableTypes.containsObject(oneCodeType))
            {
                tmpArray.append(oneCodeType as String)
            }
            else {
                println("Weird: Code type '\(oneCodeType)' is not reported as supported on this device")
            }
        }
        
        if (tmpArray.count > 0)
        {
            _metaDataOutput!.metadataObjectTypes = tmpArray
        }
        
        _metaDataOutput!.rectOfInterest = CGRectMake(0.25, 0.25, 0.5, 0.5)
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
        
        _configureCurrentCamera()
        
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
        
        // setup the barcode scanner output
        _setupMetadataOutput()
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
        
        let allCams: NSArray = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        
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
        let captureOrientation: AVCaptureVideoOrientation = DTAVCaptureVideoOrientationForUIInterfaceOrientation(interfaceOrientation)
        
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
            con.videoOrientation = captureOrientation;
        }
    }
    
    // configures cam switch button
    func _setupCamSwitchButton()
    {
        let alternativeCam: AVCaptureDevice? = _alternativeCamToCurrent()
        
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
        if (_camera!.hasTorch)
        {
            toggleTorchButton!.hidden = false
        }
        else
        {
            toggleTorchButton!.hidden = true
        }
    }
    
    // updates the rect of interest for barcode scanning for the current interest box frame
    func _updateMetadataRectOfInterest()
    {
        if (_captureSession!.running == false)
        {
            return
        }
        
        let rectOfInterest : CGRect = _videoPreview!.previewLayer.metadataOutputRectOfInterestForRect(iBox!.frame)
        _metaDataOutput!.rectOfInterest = rectOfInterest
    }
    
    // MARK: - View Appearance
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.view is DTVideoPreviewView, "Wrong root view class \(NSStringFromClass(self.view.dynamicType)) in \(NSStringFromClass(self.dynamicType))")
        
        _videoPreview = self.view as? DTVideoPreviewView
        
        _setupCameraAfterCheckingAuthorization()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        
        self.view.addGestureRecognizer(tap)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"subjectChanged:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // start session so that we don't see a black rectangle, but video
        _captureSession!.startRunning()
        
        // need to update capture and preview connections
        let orientation: UIInterfaceOrientation = interfaceOrientation
        _updateConnectionsForInterfaceOrientation(orientation)
        
        // start session so that we don't see a black rectangle, but video
        _captureSession!.startRunning()
        
        _setupCamSwitchButton()
        _setupTorchToggleButton()
        
        _visibleCodes = NSMutableSet()
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        _captureSession!.stopRunning()
    }
    
    override func shouldAutorotate() -> Bool
    {
        if (_videoPreview!.previewLayer.connection.supportsVideoOrientation)
        {
            return true
        }
        
        // prevent UI autorotation to avoid confusing the preview layer
        return false
    }
    
    // MARK: - Interface Rotation
    
    // for demonstration all orientations are supported
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.toRaw())
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval)
    {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        // need to update capture and preview connections
        _updateConnectionsForInterfaceOrientation(toInterfaceOrientation)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        _updateMetadataRectOfInterest()
    }
    
    // MARK: - Actions
    
    @IBAction func snap(sender: UIButton)
    {
        if (_camera == false)
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
            let image: UIImage = UIImage(data: imageData)
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
        })
    }
    
    @IBAction func switchCam(sender: UIButton)
    {
        _captureSession!.beginConfiguration()
        
        _camera = _alternativeCamToCurrent()
        
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
        
        _updateMetadataRectOfInterest()
        
        _configureCurrentCamera()
        
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
        if (gesture.state == .Ended)
        {
            // require both focus point and autofocus
            if ( (_camera!.focusPointOfInterestSupported == false) || (_camera!.isFocusModeSupported(.AutoFocus) == false))
            {
                println("Focus Point Not Supported by current camera")
                return
            }
            
            let loc: CGPoint = gesture.locationInView(_videoPreview)
            let locInCapture: CGPoint = _videoPreview!.previewLayer.captureDevicePointOfInterestForPoint(loc)
            
            if (_camera!.lockForConfiguration(nil) == true)
            {
                // this alone does not trigger focussing
                _camera!.focusPointOfInterest = locInCapture
                
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

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension DTCameraPreviewController : AVCaptureMetadataOutputObjectsDelegate
    {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!)
    {
        var reportedCodes = NSMutableSet()
        var repCount: Dictionary<String, UInt> = [:]
        
        for object in metadataObjects
        {
            if (object as? AVMetadataMachineReadableCodeObject != nil)
            {
                let machineObject = object as AVMetadataMachineReadableCodeObject
                var code = String("\(machineObject.type):\(machineObject.stringValue)")
                
                // get the number of times this code was reported before in this loop
                var occurencesOfCode: UInt = (repCount[code] ?? 0) + 1
                repCount[code] = occurencesOfCode
                var numberedCode = code + String(format: "-%lu", occurencesOfCode)
                
                // if it was not previously visible it is new
                if (!_visibleCodes!.containsObject(numberedCode))
                {
                    println("code appeared: \(numberedCode)")
                    delegate?.previewController!(self, didScanCode:machineObject.stringValue, ofType:machineObject.type)
                }
                
                reportedCodes.addObject(numberedCode)
                
                // create a suitable CGPath for the barcode area
                let path: CGPathRef = DTAVMetadataMachineReadableCodeObjectCreatePathForCorners(_videoPreview!.previewLayer, machineObject)
                
                // get previous shape for this code
                var shapeLayer: CAShapeLayer? = _visibleShapes![numberedCode]
                
                // if none found then this is a new shape
                if (shapeLayer == nil)
                {
                    shapeLayer =  CAShapeLayer()
                    
                    // basic configuration, stays the same regardless of path
                    shapeLayer!.strokeColor = UIColor.greenColor().CGColor
                    shapeLayer!.fillColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.25).CGColor
                    shapeLayer!.lineWidth = 2
                    
                    _videoPreview!.layer.addSublayer(shapeLayer)
                    
                    // add it to shape dictionary
                    _visibleShapes![numberedCode] = shapeLayer
                }
                
                // configure shape, relative to video preview
                shapeLayer!.frame = _videoPreview!.bounds
                shapeLayer!.path = path
                
            }
            else if (object as? AVMetadataFaceObject != nil)
            {
                println("Face detection marking not implemented")
            }
        }
        
        // check which codes which we saw in previous cycle are no longer present
        for oneCode in _visibleCodes!.allObjects
        {
            if (!reportedCodes.containsObject(oneCode))
            {
                println("code disappeared: \(oneCode)")
                
                var shape = _visibleShapes![oneCode as String]
                
                shape!.removeFromSuperlayer()
                _visibleShapes!.removeValueForKey(oneCode as String)
            }
        }
        
        _visibleCodes = reportedCodes
    }
}