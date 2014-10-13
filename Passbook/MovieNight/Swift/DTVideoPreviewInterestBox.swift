//
//  DTVideoPreviewInterestBox.swift
//  MovieNight
//
//  Created by Geoff Breemer on 12/10/14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

import UIKit
import CoreGraphics

@objc(DTVideoPreviewInterestBox) class DTVideoPreviewInterestBox: UIView
{
    private let EDGE_LENGTH: CGFloat = 10.0
    
    override func drawRect(rect: CGRect)
    {
        let ctx: CGContextRef = UIGraphicsGetCurrentContext()
        
        UIColor.redColor().setStroke()
        
        let lineWidth: CGFloat = 3
        let box: CGRect = CGRectInset(self.bounds, lineWidth/2.0, lineWidth/2.0)
        
        CGContextSetLineWidth(ctx, lineWidth)
        
        let minX: CGFloat = CGRectGetMinX(box)
        let minY: CGFloat = CGRectGetMinY(box)
        
        let maxX: CGFloat = CGRectGetMaxX(box)
        let maxY: CGFloat = CGRectGetMaxY(box)
        
        // top left
        CGContextMoveToPoint(ctx, minX, minY + EDGE_LENGTH)
        CGContextAddLineToPoint(ctx, minX, minY)
        CGContextAddLineToPoint(ctx, minX +  EDGE_LENGTH, minY)
        
        // bottom left
        CGContextMoveToPoint(ctx, minX, maxY - EDGE_LENGTH)
        CGContextAddLineToPoint(ctx, minX, maxY)
        CGContextAddLineToPoint(ctx, minX +  EDGE_LENGTH, maxY)
        
        // top right
        CGContextMoveToPoint(ctx, maxX - EDGE_LENGTH, minY)
        CGContextAddLineToPoint(ctx, maxX, minY)
        CGContextAddLineToPoint(ctx, maxX, minY +  EDGE_LENGTH)
        
        // bottom right
        CGContextMoveToPoint(ctx, maxX - EDGE_LENGTH, maxY)
        CGContextAddLineToPoint(ctx, maxX, maxY)
        CGContextAddLineToPoint(ctx, maxX, maxY - EDGE_LENGTH)
        
        CGContextStrokePath(ctx)
    }
}
