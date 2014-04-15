//
//  DTURLProtocolResponse.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

/*
 A DTURLProtocolResponse returns data, headers and a status code. Or alternatively the an error.
 */
@interface DTURLProtocolResponse : NSObject

// data to return
@property (nonatomic, readonly) NSData *data;

// HTTP status code to return
@property (nonatomic, readonly) NSUInteger statusCode;

// Headers to return (optional)
@property (nonatomic, readonly) NSDictionary *headers;

// error to return
@property (nonatomic, readonly) NSError *error;

// constructor for generic responses
+ (instancetype)responseWithData:(NSData *)data statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers;

// convenience constructor for files. Sets content type header in addition to passed headers from extension.
+ (instancetype)responseWithFile:(NSString *)path statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers;

// response that simulates a connection error by returning the error parameter
+ (instancetype)responseWithError:(NSError *)error;

@end
