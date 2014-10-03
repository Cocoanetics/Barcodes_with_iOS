//
//  DTBarcodeImageView.m
//  QRBuilder
//
//  Created by Oliver Drobnik on 17.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTBarcodeImageView.h"

@implementation DTBarcodeImageView

- (instancetype)initWithFrame:(CGRect)frame
{
   self = [super initWithFrame:frame];
   
   if (self) {
      [self _commonSetup];
   }
   
   return self;
}

- (void)awakeFromNib {
   [self _commonSetup];
}

#pragma mark - Helpers

- (void)_commonSetup
{
   UILongPressGestureRecognizer *longPress =
   [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                    action:@selector(handleLongPress:)];
   [self addGestureRecognizer:longPress];
   
   self.userInteractionEnabled = YES;
}

- (BOOL)_hasBarcodeSet {
   if (self.image)
   {
      return YES;
   }
   
   return NO;
}

#pragma mark - First Responder

- (BOOL)canBecomeFirstResponder
{
   return [self _hasBarcodeSet];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
   if (action == @selector(copy:))
   {
      return [self _hasBarcodeSet];
   }
   
   return [super canPerformAction:action withSender:sender];
}

#pragma mark - Actions


- (void)copy:(id)sender {
   [[UIPasteboard generalPasteboard] setImage:self.image];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
   if (gesture.state == UIGestureRecognizerStateBegan)
   {
      if (![self _hasBarcodeSet])
      {
         return;
      }
      
      [self becomeFirstResponder];
      
      UIMenuController *menu = [UIMenuController sharedMenuController];
      
      [menu setTargetRect:self.bounds inView:self];
      [menu setArrowDirection:UIMenuControllerArrowLeft];
      [menu setMenuVisible:YES animated:YES];
   }
}

@end
