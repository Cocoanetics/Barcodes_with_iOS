//
//  DTDiscogs.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTDiscogs.h"

#define API_ENDPOINT @"http://api.discogs.com"

@interface DTDiscogs () // private

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation DTDiscogs
{
   NSURLSession *_session;
}


// turns the API_ENDPOINT into NSURL
- (NSURL *)_endpointURL
{
   return [NSURL URLWithString:API_ENDPOINT];
}

// constructs the path for a method call
- (NSURL *)_methodURLForPath:(NSString *)path
{
   return [NSURL URLWithString:path
                 relativeToURL:[self _endpointURL]];
}

// internal method that executes actual API calls
- (void)_performMethodCallWithPath:(NSString *)path
                        completion:(DTDiscogsCompletion)completion
{
   NSURL *methodURL = [self _methodURLForPath:path];
   NSURLRequest *request = [NSURLRequest requestWithURL:methodURL];
   
   NSURLSessionDataTask *task = [self.session
                                 dataTaskWithRequest:request
                                 completionHandler:^(NSData *data,
                                                NSURLResponse *response,
                                                     NSError *error) {
      
      NSError *retError = error;
      id result = nil;
      
      // check for transport error, e.g. no network
      if (retError)
      {
         
         completion(nil, retError);
         return;
      }
      
      // check if we stayed on API endpoint (invalid host might be redirected via OpenDNS)
      NSString *host = [request.URL host];
      
      if (![[methodURL host] isEqualToString:host])
      {
         NSString *msg = [NSString stringWithFormat:
                          @"Invalid API Endpoint '%@'",
                          API_ENDPOINT];
         NSDictionary *userInfo = @{NSLocalizedDescriptionKey: msg};
         retError = [NSError errorWithDomain:@"DTDiscogs" code:999
                                    userInfo:userInfo];
         completion(nil, retError);
         
         return;
      }
      
      // parse either way, also API errors return a JSON response
      result = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:&retError];
      // check for protocol error
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
      
      if (httpResponse.statusCode >= 400)
      {
         NSDictionary *userInfo;
         NSString *message = result[@"message"];
         
         if (message)
         {
            userInfo = @{NSLocalizedDescriptionKey : message};
         }
         
         retError = [NSError errorWithDomain:@"DTDiscogs"
                                        code:httpResponse.statusCode
                                    userInfo:userInfo];
         result = nil;
      }
      
      completion(result, retError);
   }];
   
   // tasks are created suspended, this starts it
   [task resume];
}

- (void)searchForGTIN:(NSString *)gtin
           completion:(DTDiscogsCompletion)completion
{
   NSParameterAssert(gtin);
   NSParameterAssert(completion);
   
   NSString *path = [NSString stringWithFormat:
                     @"/database/search?type=release&barcode=%@", gtin];
   
   [self _performMethodCallWithPath:path completion:completion];
}


// lazy initializer for URL session
- (NSURLSession *)session
{
   if (!_session)
   {
      // make it ephemeral, we need no caching
      NSURLSessionConfiguration *conf = [NSURLSessionConfiguration
                                         ephemeralSessionConfiguration];
      _session = [NSURLSession sessionWithConfiguration:conf];
   }
   
   return _session;
}

@end
