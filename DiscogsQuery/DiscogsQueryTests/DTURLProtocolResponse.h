//
//  DTMockedServerResponse.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

/*
 A DTMockedServer returns data, headers and a status code.
 */
@interface DTURLProtocolResponse : NSObject

// data to return
@property (nonatomic, readonly) NSData *data;

// HTTP status code to return
@property (nonatomic, readonly) NSUInteger statusCode;

// Headers to return (optional)
@property (nonatomic, readonly) NSDictionary *headers;

// constructor for generic responses
+ (instancetype)responseWithData:(NSData *)data statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers;

// convenience constructor for files. Sets content type.
+ (instancetype)responseWithFile:(NSString *)path statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers;

@end
