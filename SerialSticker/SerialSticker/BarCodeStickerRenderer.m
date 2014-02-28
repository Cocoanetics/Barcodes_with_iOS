//
//  BarCodeStickerRenderer.m
//  SerialSticker
//
//  Created by Oliver Drobnik on 27.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "BarCodeStickerRenderer.h"

@implementation BarCodeStickerRenderer

- (NSInteger)numberOfPages {
   return 1;
}

- (CGFloat)cutLengthForRollWidth:(CGFloat)width
{
   CGSize fitSize = CGSizeMake(CGFLOAT_MAX, width);
   NSUInteger barScale =
      BCKCodeMaxBarScaleThatFitsCodeInSize(self.barcode,
                                           fitSize,
                                           nil);
   
   NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(barScale)};
   CGSize neededSize = [self.barcode sizeWithRenderOptions:options];
   
   return neededSize.width;
}

- (void)drawContentForPageAtIndex:(NSInteger)pageIndex
                           inRect:(CGRect)contentRect {
   NSUInteger barScale =
      BCKCodeMaxBarScaleThatFitsCodeInSize(self.barcode,
                                           self.paperRect.size,
                                           nil);

   NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(barScale)};
   
   CGSize barcodeSize = [self.barcode sizeWithRenderOptions:options];
   CGPoint origin = CGPointMake((self.paperRect.size.width -
                                 barcodeSize.width)/2.0,
                                (self.paperRect.size.height -
                                 barcodeSize.height)/2.0);
   
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   
   // position context translation matrix to center barcode
   CGContextTranslateCTM(ctx, origin.x, origin.y);
   
   [self.barcode renderInContext:ctx options:options];
}

@end
