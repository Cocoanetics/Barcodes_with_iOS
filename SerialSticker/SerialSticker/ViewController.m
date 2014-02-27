//
//  ViewController.m
//  SerialSticker
//
//  Created by Oliver Drobnik on 26.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)print:(UIButton *)sender {
   NSLog(@"Print pushed");
}

- (IBAction)textFieldChanged:(UITextField *)sender {
   NSLog(@"New value: %@", sender.text);
}

@end
