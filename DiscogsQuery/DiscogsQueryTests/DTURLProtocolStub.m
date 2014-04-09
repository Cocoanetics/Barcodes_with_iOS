//
//  DTURLProtocolStub.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTURLProtocolStub.h"

static NSMutableArray *_evaluators = nil;
static DTURLProtocolStubBeforeRequestHandler _beforeRequestHandler = NULL;
static DTURLProtocolStubMissingResponseHandler _noResponseHandler = NULL;

// internal block that evaluates an NSURLRequest and returns a DTURLProtocolResponse
typedef DTURLProtocolResponse *(^DTURLProtocolStubRequestEvaluator)(NSURLRequest *request);


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
   
   if (_beforeRequestHandler)
   {
      _beforeRequestHandler(self.request);
   }
   
   if (stubResponse)
   {
      if (stubResponse.error)
      {
         [self.client URLProtocol:self
                 didFailWithError:stubResponse.error];
         return;
      }
      
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
   else
   {
      NSError *error = nil;
      
      // deal with missing response for request
      if (_noResponseHandler)
      {
         error = _noResponseHandler(self.request);
      }
      
      // need to always send an error, otherwise crash
      if (!error)
      {
         NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"No response stubbed, sending error"};
         error = [NSError errorWithDomain:NSStringFromClass([self class]) code:999 userInfo:userInfo];
      }
      
      [self.client URLProtocol:self didFailWithError:error];
   }
}

- (void)stopLoading
{
   // nothing to do
}

#pragma mark - Helpers

- (DTURLProtocolResponse *)_stubbedResponseForRequest:(NSURLRequest *)request
{
   __block DTURLProtocolResponse *stubResponse = nil;
   
   [_evaluators enumerateObjectsUsingBlock:^(DTURLProtocolStubRequestEvaluator evaluator, NSUInteger idx, BOOL *stop) {
      
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

+ (void)addResponse:(DTURLProtocolResponse *)response forRequestPassingTest:(DTURLProtocolStubRequestTest)test
{
   if (!_evaluators)
   {
      _evaluators = [NSMutableArray array];
   }
   
   DTURLProtocolStubRequestEvaluator evaluator = ^(NSURLRequest *request) {
      
      // execute test block
      BOOL passesTest;
      
      if (test)
      {
         passesTest = test(request);
      }
      else
      {
         // no test means it always passes
         passesTest = YES;
      }
      
      if (passesTest)
      {
         return response;
      }
      
      return (DTURLProtocolResponse *)nil;
   };
   
   [_evaluators addObject:[evaluator copy]];
}

+ (void)addResponseWithFile:(NSString *)path statusCode:(NSUInteger)statusCode forRequestPassingTest:(DTURLProtocolStubRequestTest)test
{
   DTURLProtocolResponse *response = [DTURLProtocolResponse responseWithFile:path statusCode:statusCode headers:nil];
   [self addResponse:response forRequestPassingTest:test];
}

+ (void)addEmptyResponseWithStatusCode:(NSUInteger)statusCode forRequestPassingTest:(DTURLProtocolStubRequestTest)test
{
   [self addResponseWithFile:nil statusCode:statusCode forRequestPassingTest:test];
}

+ (void)addPlainTextResponse:(NSString *)string statusCode:(NSUInteger)statusCode forRequestPassingTest:(DTURLProtocolStubRequestTest)test
{
   NSData *strData = [string dataUsingEncoding:NSUTF8StringEncoding];
   NSDictionary *headers = @{@"Content-Type": @"text/plain"};
   DTURLProtocolResponse *stubResponse = [DTURLProtocolResponse responseWithData:strData statusCode:statusCode headers:headers];
   
   [self addResponse:stubResponse forRequestPassingTest:test];
}

+ (void)addErrorResponse:(NSError *)error forRequestPassingTest:(DTURLProtocolStubRequestTest)test
{
   DTURLProtocolResponse *response = [DTURLProtocolResponse responseWithError:error];
   [self addResponse:response forRequestPassingTest:test];
}

+ (void)setBeforeRequestBlock:(DTURLProtocolStubBeforeRequestHandler)block
{
   _beforeRequestHandler = [block copy];
}

+ (void)setMissingResponseBlock:(DTURLProtocolStubMissingResponseHandler)block
{
   _noResponseHandler = [block copy];
}

+ (void)removeAllResponses
{
   [_evaluators removeAllObjects];
}

@end
