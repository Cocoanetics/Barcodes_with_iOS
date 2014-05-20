//
//  ViewController.m
//  BeaconEmitter
//
//  Created by Oliver Drobnik on 20.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <CBPeripheralManagerDelegate>

@end

@implementation ViewController
{
   CBPeripheralManager *_peripheralManager;
   BOOL _isAdvertising;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   _peripheralManager =
   [[CBPeripheralManager alloc] initWithDelegate:self
                                           queue:nil];
   
   // changing autorization status kills app
   [self _updateUIForAuthorizationStatus];
}

- (void)_updateUIForAuthorizationStatus
{
   CBPeripheralManagerAuthorizationStatus
      status = [CBPeripheralManager authorizationStatus];
   
   if (status == CBPeripheralManagerAuthorizationStatusRestricted ||
       status == CBPeripheralManagerAuthorizationStatusDenied)
   {
      NSLog(@"Cannot start BT peripheral, not authorized");
      
      self.beaconSwitch.enabled = NO;
   }
   else
   {
      self.beaconSwitch.enabled = YES;
   }
}

- (void)_startAdvertising
{
   // get values from UI
   NSString *UUIDString = self.UUIDTextField.text;
   NSInteger major = [self.majorTextField.text integerValue];
   NSInteger minor = [self.minorTextField.text integerValue];
   NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
   
   // identifier cannot be nil, but is inconsequential
   CLBeaconRegion *region =
      [[CLBeaconRegion alloc] initWithProximityUUID:UUID
                                              major:major
                                              minor:minor
                                         identifier:@"FooBar"];
   
   // only care about this dictionary for advertising it
   NSDictionary *beaconPeripheralData =
      [region peripheralDataWithMeasuredPower:nil];
   [_peripheralManager startAdvertising:beaconPeripheralData];
}

- (void)_updateEmitterForDesiredState
{
   // only issue commands when powered on
   if (_peripheralManager.state == CBPeripheralManagerStatePoweredOn)
   {
      if (_isAdvertising)
      {
         if (!_peripheralManager.isAdvertising)
         {
            [self _startAdvertising];
         }
      }
      else
      {
         if (_peripheralManager.isAdvertising)
         {
            [_peripheralManager stopAdvertising];
         }
      }
   }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
   [self _updateEmitterForDesiredState];
}

#pragma mark - Actions

- (IBAction)advertisingSwitch:(UISwitch *)sender
{
   _isAdvertising = sender.isOn;
   [self _updateEmitterForDesiredState];
}

@end
