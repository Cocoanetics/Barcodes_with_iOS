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

// block that gets executed if no evaluator exists for a request
typedef void (^DTMockedServerNoEvaluatorBlock)(NSURLRequest *request);


/*
 A protocol for mocking server responses
 */
@interface DTURLProtocolStub : NSURLProtocol

// adds a response for HTTP requests passing a certain test.
+ (void)addResponse:(DTURLProtocolResponse *)response forRequestPassingTest:(DTMockedServerRequestTest)test;

//+ (void)addResponseFromFileAtPath:(NSString *)path forRequestPassingTest:(DTMockedServerRequestTest)test;

@property (nonatomic, copy) DTMockedServerNoEvaluatorBlock noEvaluatorFoundBlock;

@end
