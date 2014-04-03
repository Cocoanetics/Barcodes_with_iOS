//
//  DTDiscogs.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTDiscogs.h"
#import "MockedURLProtocol.h"

#define API_ENDPOINT @"http://api.discogs.com"

@interface DTDiscogs () // private

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation DTDiscogs
{
   NSURLSession *_session;
   NSURLSessionConfiguration *_configuration;
}

- (instancetype)initWithSessionConfiguration:
                              (NSURLSessionConfiguration *)configuration
{
   self = [super init];
   
   if (self)
   {
      _configuration = configuration;
   }
   
   return self;
}

- (instancetype)init
{
   // use ephemeral config, we need no caching
   NSURLSessionConfiguration *config =
              [NSURLSessionConfiguration ephemeralSessionConfiguration];
   return [self initWithSessionConfiguration:config];
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

// construct a suitable error
- (NSError *)_errorWithCode:(NSUInteger)code
                          message:(NSString *)message
{
   NSDictionary *userInfo;
   
   if (message)
   {
      userInfo = @{NSLocalizedDescriptionKey : message};
   }
   
   return [NSError errorWithDomain:@"DTDiscogs"
                                  code:code
                              userInfo:userInfo];
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
                                                     NSError *error)
   {
      NSError *retError = error;
      id result = nil;
      
      // check for transport error, e.g. no network
      if (retError)
      {
         
         completion(nil, retError);
         return;
      }
      
      // check if we stayed on API endpoint (invalid host might be redirected via OpenDNS)
      NSString *calledHost = [methodURL host];
      NSString *responseHost = [response.URL host];
      
      if (![responseHost isEqualToString:calledHost])
      {
         NSString *msg = [NSString stringWithFormat:
                          @"Expected result host to be '%@' but was '%@'",
                          calledHost, responseHost];
         NSDictionary *userInfo = @{NSLocalizedDescriptionKey: msg};
         retError = [NSError errorWithDomain:@"DTDiscogs" code:999
                                    userInfo:userInfo];
         completion(nil, retError);
         
         return;
      }
                                    
//      NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//      NSString *documentsPath = [writablePaths lastObject];
//      NSString *fileInDocuments = [documentsPath stringByAppendingPathComponent:@"data.txt"];
//      
//      [data writeToFile:fileInDocuments atomically:NO];
      
      // needs to be a HTTP response to get the content type and status
      if ([response isKindOfClass:[NSHTTPURLResponse class]])
      {
         // check for protocol error
         NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
         NSDictionary *headers = [httpResp allHeaderFields];
         NSString *contentType = headers[@"Content-Type"];
         
         if ([contentType isEqualToString:@"application/json"])
         {
            // parse either way, also API errors return a JSON response
            result = [NSJSONSerialization JSONObjectWithData:data
                                                     options:0
                                                       error:&retError];
         }
         else
         {
            NSString *msg = [NSString stringWithFormat:
                             @"Incorrect response with type '%@'",
                             contentType];
            retError = [self _errorWithCode:999 message:msg];
         }
         
         if (httpResp.statusCode >= 400)
         {
            NSString *message = result[@"message"];
            
            retError = [self _errorWithCode:httpResp.statusCode
                                    message:message];
            
            // wipe result, we have the message already in NSError
            result = nil;
         }
         
      }
      else
      {
         NSString *msg = @"Response is not an NSHTTPURLResponse";
         retError = [self _errorWithCode:999 message:msg];
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
      _session = [NSURLSession sessionWithConfiguration:_configuration];
   }
   
   return _session;
}

@end
