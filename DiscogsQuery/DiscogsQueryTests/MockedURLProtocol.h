//
//  MockedURLProtocol.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MockedURLProtocol : NSURLProtocol

// register a response body for a call URL
+ (void)registerResponseData:(NSData *)data forURL:(NSURL *)URL;

@end
