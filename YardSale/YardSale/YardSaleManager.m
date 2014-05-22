//
//  YardSaleManager.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "YardSaleManager.h"
#import "SalePlace.h"

@implementation YardSaleManager
{
   NSArray *_annotations;
}

- (instancetype)init
{
   self = [super init];
   
   if (self)
   {
      [self _loadAnnotations];
   }
   
   return self;
}

- (void)_loadAnnotations
{
   NSString *path =[[NSBundle mainBundle] pathForResource:@"Locations"
                                                   ofType:@"plist"];
   NSArray *locs = [NSArray arrayWithContentsOfFile:path];
   NSMutableArray *tmpArray = [NSMutableArray array];
   for (NSDictionary *oneLoc in locs)
   {
      SalePlace *place = [[SalePlace alloc] initWithDictionary:oneLoc];
      [tmpArray addObject:place];
   }
   
   _annotations = [tmpArray copy];
}

- (NSArray *)annotationsClosestToLocation:(CLLocation *)location
{
   NSArray *sorted = [[self annotations] sortedArrayUsingComparator:
      ^NSComparisonResult(SalePlace *pl1, SalePlace *pl2) {
         CLLocationDistance dist1 = [location distanceFromLocation:pl1.location];
         CLLocationDistance dist2 = [location distanceFromLocation:pl2.location];
         
         return [@(dist1) compare:@(dist2)];
   }];
   
   NSRange range = NSMakeRange(0, MIN(10, [sorted count]));
   return [sorted subarrayWithRange:range];
}

#pragma mark - Properties

- (NSArray *)annotations
{
   if (!_annotations)
   {
      [self _loadAnnotations];
   }
   
   return _annotations;
}

@end
