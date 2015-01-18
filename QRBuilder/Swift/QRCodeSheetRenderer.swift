//
//  QRCodeSheetRenderer.swift
//  QRBuilder
//
//  Created by Geoffry Breemer on 7/01/2015.
//  Copyright (c) 2015 Cocoanetics. All rights reserved.
//

import Foundation
import UIKit

@objc(QRCodeSheetRenderer) class QRCodeSheetRenderer : UIPrintPageRenderer
{
    var image : UIImage?
    
    // fixed label size for demo
    private let MARGIN_TOP_CM: CGFloat = 1.0
    private let MARGIN_LEFT_CM: CGFloat = 1.0
    private let LABEL_WIDTH_CM: CGFloat = 1.5
    private let LABEL_HEIGHT_CM: CGFloat = 1.5
    private let MARGIN_AROUND_IMAGE_CM: CGFloat = 0.125
    
    // useful macros
    func IN_TO_POINTS(inch: CGFloat) -> CGFloat
    {
        return inch * 72.0
    }
    
    func CM_TO_POINTS(cm: CGFloat) -> CGFloat
    {
        return cm * 72.0 / 2.54
    }
    
    override func numberOfPages() -> Int
    {
        return 1
    }
    
    override func prepareForDrawingPages(range: NSRange)
    {
        // nothing to prepare
    }

    func drawLabelInRect(labelRect: CGRect)
    {
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()
        
        CGContextSaveGState(ctx)
        
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone)
        
        let imageMargin: CGFloat = CM_TO_POINTS(MARGIN_AROUND_IMAGE_CM)
        let imageRect: CGRect = CGRectInset(labelRect, imageMargin, imageMargin)
        
        self.image!.drawInRect(imageRect)
        
        CGContextRestoreGState(ctx)
    }
    
    override func drawContentForPageAtIndex(index: Int, inRect contentRect: CGRect)
    {
        // initial label at top left
        var labelRect: CGRect = CGRectMake(CM_TO_POINTS(MARGIN_LEFT_CM),
            CM_TO_POINTS(MARGIN_TOP_CM),
            CM_TO_POINTS(LABEL_WIDTH_CM),
            CM_TO_POINTS(LABEL_HEIGHT_CM))
        
        while (true) {
            self.drawLabelInRect(labelRect)
            
            labelRect.origin.x += CM_TO_POINTS(LABEL_WIDTH_CM)
            
            if (CGRectGetMaxX(labelRect)>=CGRectGetMaxX(contentRect))
            {
                labelRect.origin.x = CM_TO_POINTS(MARGIN_LEFT_CM)
                labelRect.origin.y += CM_TO_POINTS(LABEL_HEIGHT_CM)
                
                if (CGRectGetMaxY(labelRect)>=CGRectGetMaxY(contentRect))
                {
                    break
                }
            }
        }
    }
}
