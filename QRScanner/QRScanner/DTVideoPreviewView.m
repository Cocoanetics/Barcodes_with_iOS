//
//  DTCodeScannerPreviewView.m
//  TagScan
//
//  Created by Oliver Drobnik on 8/20/13.
//  Copyright (c) 2013 Oliver Drobnik. All rights reserved.
//

#import "DTVideoPreviewView.h"

@implementation DTVideoPreviewView

// Designated initializer for views
- (id)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
	
   if (self)
	{
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight |
      UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor blackColor];
   }
	
   return self;
}

// Specifies to use the preview layer class
+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

#pragma mark - Properties

// Passthrough typecast for convenient access
- (AVCaptureVideoPreviewLayer *)previewLayer
{
	return (AVCaptureVideoPreviewLayer *)self.layer;
}

@end
