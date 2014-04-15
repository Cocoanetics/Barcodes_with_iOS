//
//  DTURLProtocolStub.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTURLProtocolResponse.h"

// block that evaluates an URL request if a response should be given
typedef BOOL (^DTURLProtocolStubRequestTest)(NSURLRequest *request);

// block that gets executed before a request
typedef void (^DTURLProtocolStubBeforeRequestHandler)(NSURLRequest *request);

// block that gets executed if no stubbed response is found for a request, the returned error gets sent to the URL connection
typedef NSError *(^DTURLProtocolStubMissingResponseHandler)(NSURLRequest *request);

/*
 A protocol for stubbing web server responses. Overrides all HTTP and HTTPS requests.
 
 The tests for the registered responses are tried in the same order they were added.
 */
@interface DTURLProtocolStub : NSURLProtocol

// adds a response for HTTP requests passing a certain test.
+ (void)addResponse:(DTURLProtocolResponse *)response forRequestPassingTest:(DTURLProtocolStubRequestTest)test;

// convenience for adding a response for HTTP request that comes from a file.
+ (void)addResponseWithFile:(NSString *)path statusCode:(NSUInteger)statusCode forRequestPassingTest:(DTURLProtocolStubRequestTest)test;

// returns a response with no body
+ (void)addEmptyResponseWithStatusCode:(NSUInteger)statusCode forRequestPassingTest:(DTURLProtocolStubRequestTest)test;

// returns a string with content type text/plain
+ (void)addPlainTextResponse:(NSString *)string statusCode:(NSUInteger)statusCode forRequestPassingTest:(DTURLProtocolStubRequestTest)test;

// returns a connection error for requests passing the test
+ (void)addErrorResponse:(NSError *)error forRequestPassingTest:(DTURLProtocolStubRequestTest)test;

// clears the list of all stored responses
+ (void)removeAllResponses;

// block that gets executed before a request is handled
+ (void)setBeforeRequestBlock:(DTURLProtocolStubBeforeRequestHandler)block;

// block that gets executed if no stubbed response was found
+ (void)setMissingResponseBlock:(DTURLProtocolStubMissingResponseHandler)block;

@end
