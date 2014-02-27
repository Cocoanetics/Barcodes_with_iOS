//
//  BarCodeStickerRenderer.h
//  SerialSticker
//
//  Created by Oliver Drobnik on 27.02.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BarCodeStickerRenderer : UIPrintPageRenderer

@property (nonatomic, strong) BCKCode *barcode;


- (CGFloat)cutLengthForRollWidth:(CGFloat)width;

@end
