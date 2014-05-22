//
//  YardSaleManager.h
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

@interface YardSaleManager : NSObject

@property (nonatomic, readonly) NSArray *annotations;

// returns the 10 clostest annotations
- (NSArray *)annotationsClosestToLocation:(CLLocation *)location;

@end
