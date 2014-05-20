//
//  ViewController.h
//  BeaconEmitter
//
//  Created by Oliver Drobnik on 20.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *UUIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *majorTextField;
@property (weak, nonatomic) IBOutlet UITextField *minorTextField;

@property (weak, nonatomic) IBOutlet UISwitch *beaconSwitch;

@end
