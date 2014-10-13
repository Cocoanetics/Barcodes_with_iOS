//
//  AppDelegate.swift
//  MovieNight
//
//  Created by Geoff Breemer on 12/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var alert: UIAlertView?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        // Scanner view controller is root VC of window
        let previewController: DTCameraPreviewController = window!.rootViewController as DTCameraPreviewController
        
        // Set delegate to self
        previewController.delegate = self
        
        return true
    }
    
    func _reportValidTicketDate(date: NSDate, seat: NSString)
    {
        var formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        
        let msgDate = formatter.stringFromDate(date)
        let msg = String(format: "Seat %@\n%@", seat, msgDate)
        
        let alert = UIAlertView(title: "Ticket Ok", message: msg, delegate: self, cancelButtonTitle: "Ok")
        alert.show()
    }
    
    func _reportInvalidTicket(msg: NSString)
    {
        let alert = UIAlertView(title: "Invalid Ticket", message: msg, delegate: self, cancelButtonTitle: "Ok")
        alert.show()
    }
    
    func _MD5ForString(string: String) -> String
    {
        let data: NSData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))
        let digest = UnsafeMutablePointer<CUnsignedChar>(result.mutableBytes)
        
        CC_MD5(data.bytes, CC_LONG(data.length), digest)
        
        var output: NSMutableString = ""
        
        for i in 0..<Int(CC_MD5_DIGEST_LENGTH)
        {
            output.appendFormat("%02x", digest[i])
        }
        
        return String(format: output)
    }
    
    func _SHA1ForString(string: String) -> String
    {
        let data: NSData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let result = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))
        let digest = UnsafeMutablePointer<CUnsignedChar>(result.mutableBytes)
        
        CC_SHA1(data.bytes, CC_LONG(data.length), digest)
        
        var output: NSMutableString = ""
        
        for i in 0..<Int(CC_SHA1_DIGEST_LENGTH)
        {
            output.appendFormat("%02x", digest[i])
        }
        
        return String(format: output)
    }
}

// MARK: - DTCameraPreviewControllerDelegate
extension AppDelegate : DTCameraPreviewControllerDelegate
{
    
    func previewController(previewController: DTCameraPreviewController, didScanCode code: NSString, ofType type: NSString)
    {
        // don't handle if alert showing
        if let alert = alert
        {
            if alert.visible {
                return
            }
        }
        
        if code.hasPrefix("TICKET:") == false
        {
            return
        }
        
        let components = code.componentsSeparatedByString("|")
        
        // ignore ticket without signature
        if (components.count != 2)
        {
            println("Ticket without Signature ignored")
            return
        }
        
        // server-less verification
        let salt = "EXTRA SECRET SAUCE"
        let details = components[0] as String
        let saltedDetails = details.stringByAppendingString(salt)
        let signature = components[1] as String
        let verify = self._SHA1ForString(saltedDetails)
        
        if (signature != verify)
        {
            _reportInvalidTicket("Ticket has invalid signature")
            return
        }
        
        // skip prefix
        let ticket: String = (details as NSString).substringFromIndex(7)
        let comps = ticket.componentsSeparatedByString(",")
        
        let dateStr = comps[0]
        let seat = comps[1]
        //	let serial = comps[2]
        
        var parser = NSDateFormatter()
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        let date = parser.dateFromString(dateStr)
        
        // check if event date no futher than 1 hour away
        let intervalToNow = date!.timeIntervalSinceNow
        
        if (intervalToNow < -3600)
        {
            _reportInvalidTicket("Event on this ticket is more than 60 mins in the past")
            return
        }
        
        if (intervalToNow > 3600)
        {
            _reportInvalidTicket("Event on this ticket is more than 60 mins in the future")
            return
        }
        
        // ticket is valid, so let's report that
        _reportValidTicketDate(date!, seat: seat)
    }
}
