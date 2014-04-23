//
//  LocalImageProtocol.m
//  LocalImageProtocol
//
//  Created by Oliver Drobnik on 23.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "LocalImageProtocol.h"

@implementation LocalImageProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
   if ([request.URL.scheme isEqualToString:@"foobar"]) {
      return YES;
   }
   
   return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
   // no need to change request to be canonical
   return request;
}

- (void)startLoading
{
   NSString *fileName = [self.request.URL resourceSpecifier];
   
   NSBundle *bundle = [NSBundle mainBundle];
   NSString *imagePath = [bundle pathForResource:fileName ofType:nil];
   
   if (imagePath) {
      // create HTTP response
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
                                     initWithURL:self.request.URL
                                     statusCode:200
                                     HTTPVersion:@"1.1"
                                     headerFields:nil];
      
      // send response to client
      [self.client URLProtocol:self
            didReceiveResponse:response
            cacheStoragePolicy:NSURLCacheStorageNotAllowed];
      
      // get file data and send it to client
      NSData *data = [NSData dataWithContentsOfFile:imagePath];
      
      if ([data length]) {
         [self.client URLProtocol:self didLoadData:data];
      }
      
      // tell client that we're done
      [self.client URLProtocolDidFinishLoading:self];
      
   }
   else {
      // send error to client
      NSDictionary *info = @{NSLocalizedDescriptionKey:
                                @"Cannot find file in app bundle"};
      NSError *error = [NSError
                        errorWithDomain:NSStringFromClass([self class])
                        code:999 userInfo:info];
      
      [self.client URLProtocol:self
              didFailWithError:error];
   }
}

- (void)stopLoading {
   // nothing to do, but still needs to be implemented
}

@end
