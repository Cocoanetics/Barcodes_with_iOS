//
//  YardSaleManager.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "YardSaleManager.h"
#import "SalePlacemark.h"

@implementation YardSaleManager

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
      SalePlacemark *place = [[SalePlacemark alloc] initWithDictionary:oneLoc];
      [tmpArray addObject:place];
   }
   
   _annotations = [tmpArray copy];
}

@end
