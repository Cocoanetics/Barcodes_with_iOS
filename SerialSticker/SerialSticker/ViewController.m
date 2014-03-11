//
//  ViewController.m
//  SerialSticker
//
//  Created by Oliver Drobnik on 26.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"
#import "BarCodeStickerRenderer.h"

@interface ViewController () <UIPrintInteractionControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
   self.textField.text = @"1234567890";
   [self _updatePreviewImage];
}

- (BCKCode *)_currentBarcodeFromTextField {
   NSError *error;
   BCKCode93Code *code = [[BCKCode93Code alloc]
                          initWithContent:self.textField.text
                                    error:&error];
   
   if (!code) {
      NSLog(@"%@", [error localizedDescription]);
   }
   
   return code;
}

- (void)_updatePreviewImage {
   BCKCode *barcode = [self _currentBarcodeFromTextField];
   
   if (!barcode) {
      self.imageView.image = nil;
      return;
   }
   
   NSInteger barScale = BCKCodeMaxBarScaleThatFitsCodeInSize(barcode,
                                             self.imageView.frame.size,
                                                             nil);
   NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(barScale)};
   
   barScale = 1;
   UIImage *image = [UIImage imageWithBarCode:barcode options:options];
   self.imageView.image = image;
}

#pragma mark - UIPrintInteractionControllerDelegate

- (CGFloat)printInteractionController:
           (UIPrintInteractionController *)printInteractionController
                    cutLengthForPaper:(UIPrintPaper *)paper
{
   BarCodeStickerRenderer *renderer = (BarCodeStickerRenderer *)
                           printInteractionController.printPageRenderer;
   
   return [renderer cutLengthForRollWidth:paper.paperSize.width];
}

#pragma mark - Actions

- (IBAction)textFieldChanged:(UITextField *)sender {
   [self _updatePreviewImage];
}

- (IBAction)print:(UIButton *)sender {
   UIPrintInfo *printInfo = [UIPrintInfo printInfo];
   
   // photo grayscale improves resolution on printing
   printInfo.outputType = UIPrintInfoOutputPhotoGrayscale;
   printInfo.jobName = @"Code93 Sticker";
   printInfo.duplex = UIPrintInfoDuplexNone;
   
   printInfo.orientation = UIPrintInfoOrientationLandscape;
   
   BarCodeStickerRenderer *renderer = [[BarCodeStickerRenderer alloc]
                                       init];
   renderer.barcode = [self _currentBarcodeFromTextField];
   
   UIPrintInteractionController *printController =
   [UIPrintInteractionController sharedPrintController];
   printController.printInfo = printInfo;
   printController.showsPageRange = NO;
   printController.printPageRenderer = renderer;
   printController.delegate = self;
   
   void (^completionHandler)(UIPrintInteractionController *,
                             BOOL, NSError *) =
   ^(UIPrintInteractionController *printController,
     BOOL completed, NSError *error) {
      if (!completed && error) {
         NSLog(@"FAILED! due to error in domain %@ with error code %ld",
               error.domain, (long)error.code);
      }
   };
   
   [printController presentAnimated:YES
                  completionHandler:completionHandler];
}

@end
