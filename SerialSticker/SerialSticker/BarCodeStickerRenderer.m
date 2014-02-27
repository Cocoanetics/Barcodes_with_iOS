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

- (NSUInteger)_maxBarScaleThatFitsCode:(BCKCode *)code
                                inSize:(CGSize)size
{
   NSInteger retScale = 1;
   
   // round up the size, there is a rounding problem with cut length
   size.width = ceilf(size.width);
   size.height = ceilf(size.height);
   
   for (NSUInteger scale=1;;scale++)
   {
      NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(scale)};
      CGSize neededSize = [code sizeWithRenderOptions:options];
      
      if (neededSize.width > size.width
          || neededSize.height > size.height) {
         return retScale;
      }
      
      retScale = scale;
   }
}

- (CGFloat)cutLengthForRollWidth:(CGFloat)width
{
   CGSize fitSize = CGSizeMake(CGFLOAT_MAX, width);
   NSUInteger barScale = [self _maxBarScaleThatFitsCode:self.barcode
                                                 inSize:fitSize];
   
   NSDictionary *options = @{BCKCodeDrawingBarScaleOption: @(barScale)};
   CGSize neededSize = [self.barcode sizeWithRenderOptions:options];
   
   return neededSize.width;
}

- (void)drawContentForPageAtIndex:(NSInteger)pageIndex
                           inRect:(CGRect)contentRect {
   NSUInteger barScale = [self _maxBarScaleThatFitsCode:self.barcode
                                      inSize:self.paperRect.size];
   
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
