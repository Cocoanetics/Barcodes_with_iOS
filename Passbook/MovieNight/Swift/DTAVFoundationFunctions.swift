//
//  DTAVFoundationFunctions.swift
//  MovieNight
//
//  Created by Geoff Breemer on 12/10/14.
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

func DTAVMetadataMachineReadableCodeObjectCreatePathForCorners(
    previewLayer: AVCaptureVideoPreviewLayer,
    barcodeObject: AVMetadataMachineReadableCodeObject) -> CGPathRef
{
    let transformedObject: AVMetadataMachineReadableCodeObject? = previewLayer.transformedMetadataObjectForMetadataObject(barcodeObject) as? AVMetadataMachineReadableCodeObject
    
    // new mutable path
    var path: CGMutablePathRef = CGPathCreateMutable()
    
    // first point
    var point: CGPoint = CGPointZero
    CGPointMakeWithDictionaryRepresentation(transformedObject!.corners[0] as NSDictionary, &point)
    CGPathMoveToPoint(path, nil, point.x, point.y);
    
    // second point
    CGPointMakeWithDictionaryRepresentation(transformedObject!.corners[1] as NSDictionary, &point)
    CGPathAddLineToPoint(path, nil, point.x, point.y)
    
    // third point
    CGPointMakeWithDictionaryRepresentation(transformedObject!.corners[2] as NSDictionary, &point)
    CGPathAddLineToPoint(path, nil, point.x, point.y)
    
    // fourth point
    CGPointMakeWithDictionaryRepresentation(transformedObject!.corners[3] as NSDictionary, &point)
    CGPathAddLineToPoint(path, nil, point.x, point.y)
    
    // and back to first point
    CGPathCloseSubpath(path)
    
    return path
}