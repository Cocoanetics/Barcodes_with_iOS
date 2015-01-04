//
//  DTVideoPreviewView.swift
//  MovieNight
//
//  Created by Geoff Breemer on 12/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import UIKit
import AVFoundation

@objc(DTVideoPreviewView) class DTVideoPreviewView : UIView
{
    var previewLayer: AVCaptureVideoPreviewLayer
        {
        // Passthrough typecast for convenient access
        get
        {
            return self.layer as AVCaptureVideoPreviewLayer
        }
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        _commonSetup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Called when loaded from NIB file
    override func awakeFromNib()
    {
        _commonSetup()
    }
    
    override class func layerClass() -> AnyClass
    {
        return AVCaptureVideoPreviewLayer.self
    }
    
    // Setup to be performed when view is created in code or when loaded from NIB
    func _commonSetup()
    {
        self.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        self.backgroundColor = UIColor.blackColor()
        
        // Default is resize aspect, we need aspect fill to avoid side bars on iPad
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
}
