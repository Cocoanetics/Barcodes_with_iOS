//
//  DTBarcodeImageView.swift
//  QRBuilder
//
//  Created by Geoffry Breemer on 7/01/2015.
//  Copyright (c) 2015 Cocoanetics. All rights reserved.
//

import Foundation
import UIKit

@objc(DTBarcodeImageView) class DTBarcodeImageView : UIImageView
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        _commonSetup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        _commonSetup()
    }
    
    // MARK: - Helpers
    
    func _commonSetup()
    {
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        self.addGestureRecognizer(longPress)
        
        self.userInteractionEnabled = true
    }
    
    func _hasBarcodeSet() -> Bool
    {
        if (self.image != nil)
        {
            return true
        }
        
        return false
    }
    
    // MARK: - First Responder
    
    override func canBecomeFirstResponder() -> Bool
    {
        return self._hasBarcodeSet()
    }
    
    override func canPerformAction(action: Selector,
        withSender sender: AnyObject?) -> Bool
    {
        if (action == "copy:")
        {
            return self._hasBarcodeSet()
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    // MARK: - Actions
    
    override func copy(sender: AnyObject?)
    {
        UIPasteboard.generalPasteboard().image = self.image
    }
    
    func handleLongPress(gesture: UILongPressGestureRecognizer)
    {
        if (gesture.state == UIGestureRecognizerState.Began)
        {
            if (!self._hasBarcodeSet())
            {
                return
            }
            
            self.becomeFirstResponder()
            
            let menu: UIMenuController = UIMenuController.sharedMenuController()
            
            menu.setTargetRect(self.bounds, inView:self)
            menu.arrowDirection = UIMenuControllerArrowDirection.Left
            menu.setMenuVisible(true, animated:true)
        }
    }
}
