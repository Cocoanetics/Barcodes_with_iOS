//
//  MockedURLProtocol.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "MockedURLProtocol.h"

static NSMutableDictionary *_registeredResponses = nil;


@implementation MockedURLProtocol

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
   NSURL *URL = [self.request URL];
   NSString *key = [self.request.URL absoluteString];
   NSData *data = _registeredResponses[key];
   
   // create HTTP response
   NSInteger statusCode = data?200:404;
   NSString *lengthStr = [@([data length]) description];
   NSDictionary *headers = @{@"Content-Type": @"application/json",
                             @"Content-Length": lengthStr};
   NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
                                  initWithURL:URL
                                  statusCode:statusCode
                                  HTTPVersion:@"1.1"
                                  headerFields:headers];
   
   [self.client URLProtocol:self
         didReceiveResponse:response
         cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  
   if (data)
   {
      [self.client URLProtocol:self didLoadData:data];
   }
   
   [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{
   // nothing to do
}

#pragma mark - Public Methods

+ (void)registerResponseData:(NSData *)data forURL:(NSURL *)URL
{
   if (!_registeredResponses)
   {
      // first call creates static lookup dictionary
      _registeredResponses = [[NSMutableDictionary alloc] init];
   }
   
   NSString *key = [URL absoluteString];
   _registeredResponses[key] = data;
}


@end
