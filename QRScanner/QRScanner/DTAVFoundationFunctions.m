#import "DTAVFoundationFunctions.h"

// helper function to convert interface orienation to correct video capture orientation
AVCaptureVideoOrientation DTAVCaptureVideoOrientationForUIInterfaceOrientation(UIInterfaceOrientation interfaceOrientation)
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