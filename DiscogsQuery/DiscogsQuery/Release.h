//
//  Release.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 10.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Release : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * style;
@property (nonatomic, retain) NSString * barcode;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) NSString * format;

@end
