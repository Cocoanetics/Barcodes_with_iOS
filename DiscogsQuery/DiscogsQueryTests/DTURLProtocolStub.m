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
   return YES;
}

// no need to change request to be canonical
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
   return theRequest;
}

- (void)startLoading
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
   
   NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:stubResponse.headers];

   BOOL hasData = [stubResponse.data length];
   
   // only add length header if there is data
   if (hasData)
   {
      NSString *lengthStr = [@([stubResponse.data length]) description];
      tmpDict[@"Content-Length" ] = lengthStr;
   }
   
   // create HTTP response
   NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
                                  initWithURL:self.request.URL
                                  statusCode:stubResponse.statusCode
                                  HTTPVersion:@"1.1"
                                  headerFields:tmpDict];
   
   [self.client URLProtocol:self
         didReceiveResponse:response
         cacheStoragePolicy:NSURLCacheStorageNotAllowed];
   
   if (hasData)
   {
      [self.client URLProtocol:self didLoadData:stubResponse.data];
   }
   
   [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{
   // nothing to do
}

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

@end
