//
//  AppDelegate.swift
//  QRScanner
//
//  Created by Geoff Breemer on 01/10/14.
//  Copyright (c) 2014 Oliver Drobnik. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, DTCameraPreviewControllerDelegate {
    var window: UIWindow?
    var _urlDetector: NSDataDetector?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Scanner view controller is root VC of window
        let previewController: DTCameraPreviewController = window!.rootViewController as DTCameraPreviewController
        
        // Set delegate to self
        previewController.delegate = self
        
        // configure URL detector
        _urlDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue, error: nil)
        
        return true
    }
    
    // MARK: - DTCameraPreviewControllerDelegate
    
    func previewController(previewController: DTCameraPreviewController, didScanCode code: NSString, ofType type: NSString)
    {
        let entireString: NSRange = NSMakeRange(0, code.length)
        
        let matches = _urlDetector!.matchesInString(code, options: nil, range: entireString)
        
        for match in matches
        {
            let tmpURL = match.URL
            
            if (UIApplication.sharedApplication().canOpenURL(tmpURL!!))
            {
                println("Opening URL '\(match.URL!!.absoluteString)' in external browser")
                UIApplication.sharedApplication().openURL(match.URL!!)
                
                // Prevent additional URLs from opening
                break
            }
            else
            {
                // Some URL schemes cannot be opened
                println("Device cannot open URL '\(match.URL!!.absoluteString)'")
            }
        }
    }
}
