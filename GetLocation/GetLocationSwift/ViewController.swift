//
//  ViewController.swift
//  GetLocationSwift
//
//  Created by Geoff Breemer on 04/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import UIKit
import CoreLocation
import Dispatch
import AddressBookUI
import Foundation

class ViewController: UIViewController, CLLocationManagerDelegate
{
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressTextView:  UITextView!
    
    private var _locationMgr: CLLocationManager!
    private var _mostRecentLoc: CLLocation?
    private var _geoCoder : CLGeocoder?
    private var _addressDictionary = [NSObject : AnyObject]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // initialize geo coder
        _geoCoder = CLGeocoder()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive:", name:UIApplicationDidBecomeActiveNotification, object:nil)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        _enableLocationUpdatesIfAuthorized()
    }
    
    // MARK: Notifications
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // when app comes into foreground and also following the initial authorization dialog
    func didBecomeActive(notification: NSNotification)
    {
        self._enableLocationUpdatesIfAuthorized()
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        var location: CLLocation = locations.last as CLLocation!
        
        if (self._mostRecentLoc == nil || location.coordinate.longitude != self._mostRecentLoc!.coordinate.longitude ||
            location.coordinate.latitude != self._mostRecentLoc!.coordinate.latitude)
        {
            _updateLatLongLabelsWithLocation(location)
            
            _geoCoder?.reverseGeocodeLocation(location, completionHandler: {
                [unowned self]
                (placemarks: [AnyObject]!, error: NSError!) -> Void in
                if (placemarks != nil)
                {
                    var placemark: CLPlacemark = placemarks.first as CLPlacemark
                    self._updateAddressLabelWithPlacemark(placemark)
                }
                else
                {
                    println("Error from geocoder: \(error.localizedDescription)")
                }
                return
            })
            
            self._mostRecentLoc = locations.last as? CLLocation
        }
    }
    
    // MARK: Helpers
    
    func _updateLatLongLabelsWithLocation(location: CLLocation)
    {
        dispatch_async(dispatch_get_main_queue(), {
            [unowned self] in
            self.latitudeLabel?.text = "\(location.coordinate.latitude)"
            self.longitudeLabel?.text = "\(location.coordinate.longitude)"
            return
        })
    }
    
    func _updateAddressLabelWithPlacemark(placemark: CLPlacemark)
    {
        dispatch_async(dispatch_get_main_queue(), {
            [unowned self] in
            self._addressDictionary = placemark.addressDictionary
            var addressStr: String = ABCreateStringWithAddressDictionary(self._addressDictionary, true)
            self.addressTextView?.text = addressStr
        })
    }
    
    func _enableLocationUpdatesIfAuthorized()
    {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == CLAuthorizationStatus.Restricted || authStatus == CLAuthorizationStatus.Denied
        {
            println("policy has restricted location updates or user denied it")
            _locationMgr = nil
            return
        }
        
        println("authorized or not determined")
        
        // initialize location manager
        if _locationMgr == nil
        {
            _locationMgr = CLLocationManager()
            _locationMgr.delegate = self

            // on iOS 8 you need to explicitly request authorization
            let iosVersion = NSOperatingSystemVersion(majorVersion: 8, minorVersion: 0, patchVersion: 0)
            if NSProcessInfo.processInfo().isOperatingSystemAtLeastVersion(iosVersion)
            {
                _locationMgr?.requestWhenInUseAuthorization()
            }
            
            _locationMgr.startUpdatingLocation()
        }
    }
    
    // MARK: Actions
    
    @IBAction func copyAddress(sender: AnyObject)
    {
        var record: ABRecordRef = ABPersonCreate().takeRetainedValue()
        ABRecordSetValue(record, kABPersonFirstNameProperty, "My Location", nil)
        
        var multiHome: ABMutableMultiValueRef = ABMultiValueCreateMutable(ABPropertyType(kABMultiDictionaryPropertyType)).takeRetainedValue()
        var didAddHome: Bool = ABMultiValueAddValueAndLabel(multiHome, _addressDictionary, kABHomeLabel, nil)
        
        if(didAddHome)
        {
            ABRecordSetValue(record, kABPersonAddressProperty, multiHome, nil)
            println("Address saved.")
        }
        
        var mapString:String = NSString(format: "http://maps.apple.com/?q=%f,%f&sspn=0.002828,0.006132&sll=%f,%f",
            _mostRecentLoc!.coordinate.latitude,
            _mostRecentLoc!.coordinate.longitude,
            _mostRecentLoc!.coordinate.latitude,
            _mostRecentLoc!.coordinate.longitude)
        
        // Adding url
        var urlMultiValue: ABMutableMultiValueRef = ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)).takeRetainedValue()
        ABMultiValueAddValueAndLabel(urlMultiValue, mapString, "Map URL", nil)
        ABRecordSetValue(record, kABPersonURLProperty, urlMultiValue, nil)
        
        // Obtain vCard
        var people : NSArray = [record]
        var data: NSData = ABPersonCreateVCardRepresentationWithPeople(people as CFArray).takeRetainedValue()
        var vcardString: String = NSString(data: data, encoding: NSASCIIStringEncoding)
        
        println(vcardString)
        
        // Write vCard
        var paths: [AnyObject] = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var documentsDirectory: String = paths.first as String // Get documents directory
        var filePath: String = documentsDirectory.stringByAppendingPathComponent("pin.loc.vcf")
        vcardString.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        
        var url: NSURL = NSURL(string: filePath)
        
        println("url> \(url.absoluteString)")
        
        // Share Code
        var itemsToShare: [NSURL] = [url]
        var activityVC: UIActivityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityTypePrint,
            UIActivityTypeCopyToPasteboard,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypePostToWeibo]
        
        if (UIDevice.currentDevice().userInterfaceIdiom == .Phone)
        {
            self.presentViewController(activityVC, animated: true, nil)
        }
    }
}