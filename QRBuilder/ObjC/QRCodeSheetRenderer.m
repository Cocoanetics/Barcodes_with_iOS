//
//  QRCodeSheetRenderer.m
//  QRBuilder
//
//  Created by Oliver Drobnik on 19.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "QRCodeSheetRenderer.h"

// useful macros
#define IN_TO_POINTS(in) in*72.0
#define CM_TO_POINTS(cm) cm*72.0/2.54

// fixed label size for demo
#define MARGIN_TOP_CM 1.0
#define MARGIN_LEFT_CM 1.0
#define LABEL_WIDTH_CM 1.5
#define LABEL_HEIGHT_CM 1.5
#define MARGIN_AROUND_IMAGE_CM 0.125

@implementation QRCodeSheetRenderer

- (NSInteger)numberOfPages {
   return 1;
}

- (void)prepareForDrawingPages:(NSRange)range {
   // nothing to prepare
}

- (void)drawLabelInRect:(CGRect)labelRect {
   CGContextRef ctx = UIGraphicsGetCurrentContext();
   
   CGContextSaveGState(ctx);
   
   CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
   
   CGFloat imageMargin = CM_TO_POINTS(MARGIN_AROUND_IMAGE_CM);
   CGRect imageRect = CGRectInset(labelRect, imageMargin, imageMargin);
   
   [self.image drawInRect:imageRect];
   
   CGContextRestoreGState(ctx);
}

- (void)drawContentForPageAtIndex:(NSInteger)pageIndex
                           inRect:(CGRect)contentRect {
   
   // initial label at top left
   CGRect labelRect = CGRectMake(CM_TO_POINTS(MARGIN_LEFT_CM),
                                 CM_TO_POINTS(MARGIN_TOP_CM),
                                 CM_TO_POINTS(LABEL_WIDTH_CM),
                                 CM_TO_POINTS(LABEL_HEIGHT_CM));
   
   while (1) {
      [self drawLabelInRect:labelRect];
      
      labelRect.origin.x += CM_TO_POINTS(LABEL_WIDTH_CM);
      
      if (CGRectGetMaxX(labelRect)>=CGRectGetMaxX(contentRect)) {
         labelRect.origin.x = CM_TO_POINTS(MARGIN_LEFT_CM);
         labelRect.origin.y += CM_TO_POINTS(LABEL_HEIGHT_CM);
         
         if (CGRectGetMaxY(labelRect)>=CGRectGetMaxY(contentRect)) {
            break;
         }
      }
   }
}

@end
