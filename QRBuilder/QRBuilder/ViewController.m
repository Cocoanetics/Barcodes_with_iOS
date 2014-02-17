//
//  ViewController.m
//  QRBuilder
//
//  Created by Oliver Drobnik on 13.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   [self _updateBarcodePreview];
}


- (UIImage *)_scaledImageFromCIImage:(CIImage *)image
                             withScale:(CGFloat)scale
{
   CIContext *ciContext = [CIContext contextWithOptions:nil];
   
   CGImageRef cgImage = [ciContext createCGImage:image
                                      fromRect:image.extent];
   
   CGSize size = CGSizeMake(image.extent.size.width * scale,
                            image.extent.size.height * scale);
   UIGraphicsBeginImageContext(size);
   
   CGContextRef context = UIGraphicsGetCurrentContext();
   
   // We don't want to interpolate
   CGContextSetInterpolationQuality(context, kCGInterpolationNone);
   
   CGRect bounds = CGContextGetClipBoundingBox(context);
   CGContextDrawImage(context, bounds, cgImage);
   UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   
   CGImageRelease(cgImage);
   
   return scaledImage;
}


- (void)_updateBarcodePreview
{
   NSString *text = self.textField.text;
   NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
   
   CIFilter *code = [CIFilter filterWithName:@"CIQRCodeGenerator"];
   [code setValue:data forKey:@"inputMessage"];
   
   NSUInteger errorCorrLevel = roundf(self.slider.value);
   
   switch (errorCorrLevel) {
      case 0:
         [code setValue:@"L"
                 forKey:@"inputCorrectionLevel"];
         break;
      default:
         [code setValue:@"M"
                 forKey:@"inputCorrectionLevel"];
         break;
      case 2:
         [code setValue:@"Q"
                 forKey:@"inputCorrectionLevel"];
         break;
      case 3:
         [code setValue:@"H"
                 forKey:@"inputCorrectionLevel"];
         break;
   }

   CGSize originalSize = code.outputImage.extent.size;
   CGSize maxSize = self.imageView.bounds.size;
   
   NSInteger scale = truncf(MIN(maxSize.width/originalSize.width,
                                maxSize.height/originalSize.height));
   
   
   UIImage *scaledImage = [self _scaledImageFromCIImage:code.outputImage
                                              withScale:scale];
   self.imageView.image = scaledImage;
}

#pragma mark - Actions

- (IBAction)sliderChanged:(UISlider *)sender {
   [self _updateBarcodePreview];
}

- (IBAction)textFieldChanged:(UITextField *)sender {
   [self _updateBarcodePreview];
}

@end
