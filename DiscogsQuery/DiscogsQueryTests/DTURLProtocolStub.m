//
//  DTMockedServer.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTURLProtocolStub.h"

static NSMutableArray *_evaluators = nil;

// internal block that evaluates an NSURLRequest and returns an DTMockedServerResponse
typedef DTURLProtocolResponse *(^DTMockedServerRequestEvaluator)(NSURLRequest *request);


@implementation DTURLProtocolStub

// override all requests
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
   NSString *scheme = request.URL.scheme;
   
   if ([scheme isEqualToString:@"http"])
   {
      return YES;
   }

   if ([scheme isEqualToString:@"https"])
   {
      return YES;
   }

   return NO;
}

// no need to change request to be canonical
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
   return theRequest;
}

- (void)startLoading
{
   DTURLProtocolResponse *stubResponse = [self _stubbedResponseForRequest:self.request];
   
   // create HTTP response
   NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
                                  initWithURL:self.request.URL
                                  statusCode:stubResponse.statusCode
                                  HTTPVersion:@"1.1"
                                  headerFields:stubResponse.headers];
   
   [self.client URLProtocol:self
         didReceiveResponse:response
         cacheStoragePolicy:NSURLCacheStorageNotAllowed];
   
   if ([stubResponse.data length])
   {
      [self.client URLProtocol:self didLoadData:stubResponse.data];
   }
   
   [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{
   // nothing to do
}

#pragma mark - Helpers

- (DTURLProtocolResponse *)_stubbedResponseForRequest:(NSURLRequest *)request
{
   __block DTURLProtocolResponse *stubResponse = nil;
   
   [_evaluators enumerateObjectsUsingBlock:^(DTMockedServerRequestEvaluator evaluator, NSUInteger idx, BOOL *stop) {
      
      stubResponse = evaluator(self.request);
      
      // first evaluator with success wins
      if (stubResponse)
      {
         *stop = YES;
      }
   }];
   
   return stubResponse;
}


#pragma mark - Public API

+ (void)addResponse:(DTURLProtocolResponse *)response forRequestPassingTest:(DTMockedServerRequestTest)test
{
   if (!_evaluators)
   {
      _evaluators = [NSMutableArray array];
   }
   
   DTMockedServerRequestEvaluator evaluator = ^(NSURLRequest *request) {
      
      // execute test block
      BOOL passesTest = test(request);
      
      if (passesTest)
      {
         return response;
      }
      
      return (DTURLProtocolResponse *)nil;
   };
   
   [_evaluators addObject:[evaluator copy]];
}

+ (void)addResponseWithFile:(NSString *)path forRequestPassingTest:(DTMockedServerRequestTest)test
{
   NSFileManager *fileManager = [NSFileManager defaultManager];
   NSUInteger statusCode = 200;
   
   if (![fileManager fileExistsAtPath:path])
   {
      statusCode = 404;
   }
   
   DTURLProtocolResponse *response = [DTURLProtocolResponse responseWithFile:path statusCode:statusCode headers:nil];
   [self addResponse:response forRequestPassingTest:test];
}

@end
