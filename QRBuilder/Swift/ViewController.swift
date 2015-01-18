//
//  ViewController.swift
//  QRBuilder
//
//  Created by Geoffry Breemer on 7/01/2015.
//  Copyright (c) 2015 Cocoanetics. All rights reserved.
//

import Foundation
import UIKit

@objc(ViewController) class ViewController : UIViewController, UIPrintInteractionControllerDelegate
{
    
    @IBOutlet var imageView: UIImageView?
    @IBOutlet var slider: UISlider?
    @IBOutlet var textField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self._updateBarcodePreview()
    }
    
    func _scaledImageFromCIImage(image: CIImage, withScale scale: CGFloat) -> UIImage
    {
        let ciContext: CIContext = CIContext(options: nil)
        let cgImage: CGImageRef = ciContext.createCGImage(image, fromRect:image.extent())
        
        let size: CGSize = CGSizeMake(image.extent().size.width * scale, image.extent().size.height * scale)
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        
        let context: CGContextRef  = UIGraphicsGetCurrentContext()
        
        // We don't want to interpolate
        CGContextSetInterpolationQuality(context, kCGInterpolationNone)
        
        // flip coordinates so that upper side of QR codes has two boxes
        let flip: CGAffineTransform = CGAffineTransformMake(1, 0, 0, -1, 0,
            size.height)
        CGContextConcatCTM(context, flip)
        
        let bounds: CGRect = CGContextGetClipBoundingBox(context)
        CGContextDrawImage(context, bounds, cgImage)
        let scaledImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func _updateBarcodePreview()
    {
        let text: NSString = self.textField!.text
        let data: NSData = text.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var code: CIFilter =  CIFilter(name:"CIQRCodeGenerator")
        code.setValue(data, forKey:"inputMessage")
        
        let errorCorrLevel: UInt = UInt(roundf(self.slider!.value))
        
        switch (errorCorrLevel)
        {
        case 0:
            code.setValue("L", forKey:"inputCorrectionLevel")
        case 2:
            code.setValue("Q", forKey:"inputCorrectionLevel")
        case 3:
            code.setValue("H", forKey:"inputCorrectionLevel")
        default:
            code.setValue("M", forKey:"inputCorrectionLevel")
        }
        
        let originalSize: CGSize = code.outputImage.extent().size
        let maxSize: CGSize = self.imageView!.bounds.size
        
        let scale: NSInteger = NSInteger(truncf(min(Float(maxSize.width/originalSize.width), Float(maxSize.height/originalSize.height))))
        let scaledImage: UIImage = self._scaledImageFromCIImage(code.outputImage, withScale:CGFloat(scale))
        
        self.imageView!.image = scaledImage
    }
    
    
    // MARK: - UIPrintInteractionControllerDelegate
    func printInteractionController(printInteractionController: UIPrintInteractionController,
        choosePaper papers: [AnyObject]) -> UIPrintPaper?
    {
        let requiredSize: CGSize = CGSizeMake(8.5 * 72, 11 * 72)
        return UIPrintPaper.bestPaperForPageSize(requiredSize, withPapersFromArray: papers)
    }
    
    // MARK: - Actions
    
    @IBAction func sliderChanged(sender: UISlider)
    {
        self._updateBarcodePreview()
    }
    
    @IBAction func textFieldChanged(sender: UITextField)
    {
        self._updateBarcodePreview()
    }
    
    @IBAction func print(sender: UIButton)
    {
        var printInfo: UIPrintInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = UIPrintInfoOutputType.Grayscale
        printInfo.jobName = "QR Codes"
        printInfo.duplex = UIPrintInfoDuplex.None
        
        var renderer: QRCodeSheetRenderer = QRCodeSheetRenderer()
        renderer.image = self.imageView!.image
        
        var printController: UIPrintInteractionController = UIPrintInteractionController.sharedPrintController()!
        printController.printInfo = printInfo
        printController.showsPageRange = false
        printController.printPageRenderer = renderer
        printController.delegate = self
        
        printController.presentAnimated(true, completionHandler: { (printController: UIPrintInteractionController!, completed: Bool, error: NSError!) -> Void in
            if (completed == false && error != nil)
            {
                println("FAILED! due to error in domain \(error.domain) with error code \(error.code)")
            }
            
        })
    }
}