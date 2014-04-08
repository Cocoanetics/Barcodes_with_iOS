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
#define URLENC(string) [string \
   stringByAddingPercentEncodingWithAllowedCharacters:\
	NSCharacterSet.URLQueryAllowedCharacterSet];


NSString * const DTDiscogsErrorDomain = @"DTDiscogs";

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
						parameters:(NSDictionary *)parameters
{
	if ([parameters count])
	{
		// sort keys to get same order every time
		NSArray *sortedKeys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
		
		// construct query string
		NSMutableArray *tmpArray = [NSMutableArray array];
	
		for (NSString *key in sortedKeys)
		{
			NSString *value = parameters[key];
			
			// URL-encode
			NSString *encKey = URLENC(key);
			NSString *encValue = URLENC(value);
			
			// combine into pairs
			NSString *tmpStr = [NSString stringWithFormat:@"%@=%@", encKey, encValue];
			[tmpArray addObject:tmpStr];
			
		}
		
		// append query to path
		path = [path stringByAppendingFormat:@"?%@", [tmpArray componentsJoinedByString:@"&"]];
	}
	
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
   
   return [NSError errorWithDomain:DTDiscogsErrorDomain
                                  code:code
                              userInfo:userInfo];
}

// internal method that executes actual API calls
- (void)_performMethodCallWithPath:(NSString *)path
								parameters:(NSDictionary *)parameters
                        completion:(DTDiscogsCompletion)completion
{
   NSURL *methodURL = [self _methodURLForPath:path parameters:parameters];
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
			retError = [self _errorWithCode:999 message:msg];
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
	// assert that all parameters are not nil
   NSParameterAssert(gtin);
   NSParameterAssert(completion);
   
   NSString *functionPath = @"/database/search";
	NSDictionary *params = @{@"type": @"release",
									 @"barcode": gtin};
   
   [self _performMethodCallWithPath:functionPath
								 parameters:params
								 completion:completion];
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
