//
//  DTAVFoundationFunctions.swift
//  Camera
//
//  Created by Geoff Breemer on 11/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import AVFoundation
import UIKit

// helper function to convert interface orienation to correct video capture orientation
func DTAVCaptureVideoOrientationForUIInterfaceOrientation(interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation
{
    switch (interfaceOrientation)
        {
    case .LandscapeLeft:
        return .LandscapeLeft;
    case .LandscapeRight:
        return .LandscapeRight;
    case .Portrait:
        return .Portrait;
    case .PortraitUpsideDown:
        return .PortraitUpsideDown;
    case .Unknown:
        return .Portrait
    }
}