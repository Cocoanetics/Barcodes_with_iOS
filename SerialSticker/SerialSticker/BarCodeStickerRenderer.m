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
   UIImage *image = [UIImage imageWithBarCode:self.barcode
                                      options:options];
   
   CGPoint origin = CGPointMake((self.paperRect.size.width -
                                        image.size.width)/2.0,
                                (self.paperRect.size.height -
                                        image.size.height)/2.0);
   [image drawAtPoint:origin];
}

@end
