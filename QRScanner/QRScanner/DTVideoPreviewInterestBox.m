//
//  DTVideoPreviewInterestBox.m
//  QRScanner
//
//  Created by Oliver Drobnik on 11/12/13.
//  Copyright (c) 2013 Oliver Drobnik. All rights reserved.
//

#import "DTVideoPreviewInterestBox.h"

#define EDGE_LENGTH 10.0

@implementation DTVideoPreviewInterestBox

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[[UIColor redColor] setStroke];
	
	CGFloat lineWidth=3;
	CGRect drawRect = CGRectInset(self.bounds, lineWidth/2.0, lineWidth/2.0);
	
	CGContextSetLineWidth(ctx, lineWidth);
	
	CGFloat minX = CGRectGetMinX(drawRect);
	CGFloat minY = CGRectGetMinY(drawRect);
	
	CGFloat maxX = CGRectGetMaxX(drawRect);
	CGFloat maxY = CGRectGetMaxY(drawRect);
	
	// top left
	CGContextMoveToPoint(ctx, minX, minY + EDGE_LENGTH);
	CGContextAddLineToPoint(ctx, minX, minY);
	CGContextAddLineToPoint(ctx, minX +  EDGE_LENGTH, minY);

	// bottom left
	CGContextMoveToPoint(ctx, minX, maxY - EDGE_LENGTH);
	CGContextAddLineToPoint(ctx, minX, maxY);
	CGContextAddLineToPoint(ctx, minX +  EDGE_LENGTH, maxY);
	
	// top right
	CGContextMoveToPoint(ctx, maxX - EDGE_LENGTH, minY);
	CGContextAddLineToPoint(ctx, maxX, minY);
	CGContextAddLineToPoint(ctx, maxX, minY +  EDGE_LENGTH);
	
	// bottom right
	CGContextMoveToPoint(ctx, maxX - EDGE_LENGTH, maxY);
	CGContextAddLineToPoint(ctx, maxX, maxY);
	CGContextAddLineToPoint(ctx, maxX, maxY -  EDGE_LENGTH);

	CGContextStrokePath(ctx);
}

@end
