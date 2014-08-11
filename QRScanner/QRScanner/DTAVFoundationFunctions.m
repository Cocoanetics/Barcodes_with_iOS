#import "DTAVFoundationFunctions.h"

// helper function to convert interface orienation to correct video capture orientation
AVCaptureVideoOrientation
DTAVCaptureVideoOrientationForUIInterfaceOrientation(
                            UIInterfaceOrientation interfaceOrientation)
{
	switch (interfaceOrientation)
	{
		case UIInterfaceOrientationLandscapeLeft:
		{
			return AVCaptureVideoOrientationLandscapeLeft;
		}
			
		case UIInterfaceOrientationLandscapeRight:
		{
			return AVCaptureVideoOrientationLandscapeRight;
		}
			
      default:
		case UIInterfaceOrientationPortrait:
		{
			return AVCaptureVideoOrientationPortrait;
		}
			
		case UIInterfaceOrientationPortraitUpsideDown:
		{
			return AVCaptureVideoOrientationPortraitUpsideDown;
		}
	}
}

CGPathRef DTAVMetadataMachineReadableCodeObjectCreatePathForCorners(
                               AVCaptureVideoPreviewLayer *previewLayer,
                     AVMetadataMachineReadableCodeObject *barcodeObject)
{
   AVMetadataMachineReadableCodeObject *transformedObject =
   (AVMetadataMachineReadableCodeObject *)
   [previewLayer
    transformedMetadataObjectForMetadataObject:barcodeObject];
	
	// new mutable path
   CGMutablePathRef path = CGPathCreateMutable();
	
	// first point
   CGPoint point;
   CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)
                                           transformedObject.corners[0],
                                           &point);
   CGPathMoveToPoint(path, NULL, point.x, point.y);
	
	// second point
   CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)
                                           transformedObject.corners[1],
                                           &point);
   CGPathAddLineToPoint(path, NULL, point.x, point.y);
	
	// third point
   CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)
                                           transformedObject.corners[2],
                                           &point);
   CGPathAddLineToPoint(path, NULL, point.x, point.y);
	
	// fourth point
   CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)
                                           transformedObject.corners[3],
                                           &point);
   CGPathAddLineToPoint(path, NULL, point.x, point.y);
	
	// and back to first point
   CGPathCloseSubpath(path);
	
   return path;
}
