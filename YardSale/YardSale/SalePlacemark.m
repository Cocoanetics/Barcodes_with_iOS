//
//  SalePlacemark.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "SalePlacemark.h"

@implementation SalePlacemark
{
   NSString *_name;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
   CLLocationCoordinate2D coord;
   coord.latitude = [dictionary[@"Latitude"] floatValue];
   coord.longitude = [dictionary[@"Longitude"] floatValue];

   SalePlacemark *mark = [super initWithCoordinate:coord addressDictionary:nil];
   
   if (mark)
   {
      mark->_name = dictionary[@"Name"];
   }
   
   return self;
}

- (NSString *)title
{
   return [NSString stringWithFormat:@"%@'s Yard Sale", _name];
}

- (NSString *)subtitle
{
   return @"Cool Offers";
}

@end
