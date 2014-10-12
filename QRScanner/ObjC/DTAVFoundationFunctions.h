// helper function to convert interface orienation to correct video capture orientation
AVCaptureVideoOrientation
   DTAVCaptureVideoOrientationForUIInterfaceOrientation(
                           UIInterfaceOrientation interfaceOrientation);

// creates a CGPath for the cornder of a barcode object
CGPathRef DTAVMetadataMachineReadableCodeObjectCreatePathForCorners(
                               AVCaptureVideoPreviewLayer *previewLayer,
                    AVMetadataMachineReadableCodeObject *barcodeObject);
