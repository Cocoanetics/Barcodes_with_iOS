//
//  DTMockedServer.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTURLProtocolResponse.h"

// block that evaluates an URL request if a response should be given
typedef BOOL (^DTMockedServerRequestTest)(NSURLRequest *request);

/*
 A protocol for stubbing web server responses. Overrides all HTTP and HTTPS requests.
 */
@interface DTURLProtocolStub : NSURLProtocol

// adds a response for HTTP requests passing a certain test.
+ (void)addResponse:(DTURLProtocolResponse *)response forRequestPassingTest:(DTMockedServerRequestTest)test;

// convenience for adding a response for HTTP request that comes from a file.
+ (void)addResponseWithFile:(NSString *)path forRequestPassingTest:(DTMockedServerRequestTest)test;

@end
