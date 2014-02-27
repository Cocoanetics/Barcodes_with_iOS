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
   
   self.textField.text = @"1234567890";
   [self _updateCodeFromTextField];
}


- (NSUInteger)_maxBarScaleThatFitsCode:(BCKCode *)code
{
   CGSize maxSize = self.imageView.frame.size;
   NSInteger retScale = 1;

   for (NSUInteger scale=1;;scale++)
   {
      NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(scale)};
      CGSize size = [code sizeWithRenderOptions:options];
      
      if (size.width > maxSize.width
          || size.height > maxSize.height) {
         return retScale;
      }
      
      retScale = scale;
   }
}

- (void)_updatePreviewFromCode:(BCKCode *)code
{
   if (!code) {
      self.imageView.image = nil;
      return;
   }
   
   NSInteger barScale = [self _maxBarScaleThatFitsCode:code];
   NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(barScale)};
   UIImage *image = [UIImage imageWithBarCode:code options:options];
   self.imageView.image = image;
}

- (void)_updateCodeFromTextField
{
   NSError *error;
   BCKCode93Code *code = [[BCKCode93Code alloc] initWithContent:
                          self.textField.text error:&error];
   
   if (!code) {
      NSLog(@"%@", [error localizedDescription]);
   }
   
   [self _updatePreviewFromCode:code];
}


- (IBAction)print:(UIButton *)sender {
   NSLog(@"Print pushed");
}

- (IBAction)textFieldChanged:(UITextField *)sender {
   [self _updateCodeFromTextField];
}

@end
