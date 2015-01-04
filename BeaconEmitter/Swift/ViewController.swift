//
//  ViewController.swift
//  BeaconEmitter
//
//  Created by Geoff Breemer on 11/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import Foundation

@objc(ViewController) class ViewController: UIViewController, CBPeripheralManagerDelegate
{
    @IBOutlet var UUIDTextField: UITextField?
    @IBOutlet var majorTextField: UITextField?
    @IBOutlet var minorTextField: UITextField?
    
    @IBOutlet var beaconSwitch: UISwitch!
    
    private var _peripheralManager: CBPeripheralManager?
    private var _isAdvertising: Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        _peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        // changing autorization status kills app
        _updateUIForAuthorizationStatus()
    }
    
    func _updateUIForAuthorizationStatus()
    {
        let status: CBPeripheralManagerAuthorizationStatus = CBPeripheralManager.authorizationStatus()
        
        if (status == .Restricted ||
            status == .Denied)
        {
            println("Cannot start BT peripheral, not authorized")
            
            beaconSwitch.enabled = false
        }
        else
        {
            beaconSwitch.enabled = true
        }
    }
    
    func _startAdvertising()
    {
        // get values from UI
        let UUIDString: String = UUIDTextField!.text
        let major: NSInteger = majorTextField!.text.toInt()!
        let minor: NSInteger = minorTextField!.text.toInt()!
        let UUID: NSUUID = NSUUID(UUIDString: UUIDString)!
        
        // identifier cannot be nil, but is inconsequential
        let region: CLBeaconRegion = CLBeaconRegion(proximityUUID: UUID, major: CLBeaconMajorValue(major), minor: CLBeaconMinorValue(minor), identifier: "FooBar")
        
        // only care about this dictionary for advertising it
        let beaconPeripheralData: Dictionary = region.peripheralDataWithMeasuredPower(nil)
        _peripheralManager!.startAdvertising(beaconPeripheralData)
    }
    
    func _updateEmitterForDesiredState()
    {
        // only issue commands when powered on
        if (_peripheralManager!.state == .PoweredOn)
        {
            if (_isAdvertising)
            {
                if (!_peripheralManager!.isAdvertising)
                {
                    _startAdvertising()
                }
            }
            else
            {
                if (_peripheralManager!.isAdvertising)
                {
                    _peripheralManager!.stopAdvertising()
                }
            }
        }
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        _updateEmitterForDesiredState()
    }
    
    // MARK: - Actions
    
    @IBAction func advertisingSwitch(sender: UISwitch)
    {
        _isAdvertising = sender.on
        _updateEmitterForDesiredState()
    }
}