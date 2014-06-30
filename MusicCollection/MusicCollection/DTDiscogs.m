//
//  DTDiscogs.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTDiscogs.h"
#import "DTOAuthClient.h"

#define API_ENDPOINT @"http://api.discogs.com"
#define URLENC(string) [string \
   stringByAddingPercentEncodingWithAllowedCharacters:\
	[NSCharacterSet URLQueryAllowedCharacterSet]];

NSString * const DTDiscogsErrorDomain = @"DTDiscogs";

@implementation DTDiscogs
{
   NSURLSession *_session;
   NSURLSessionConfiguration *_configuration;
}

- (instancetype)initWithSessionConfiguration:
                            (NSURLSessionConfiguration *)configuration {
   self = [super init];
   
   if (self) {
      _configuration = configuration;
   }
   
   return self;
}

// designated initializer
- (instancetype)init {
   // use ephemeral config, we need no caching
   NSURLSessionConfiguration *config =
              [NSURLSessionConfiguration ephemeralSessionConfiguration];
   return [self initWithSessionConfiguration:config];
}

// constructs the path for a method call
- (NSURL *)_methodURLForPath:(NSString *)path
						parameters:(NSDictionary *)parameters {
   // turns the API_ENDPOINT into NSURL
   NSURL *endpointURL = [NSURL URLWithString:API_ENDPOINT];
   
	if ([parameters count])
	{
		// sort keys to get same order every time
		NSArray *sortedKeys =
                  [[parameters allKeys]
                   sortedArrayUsingSelector:@selector(compare:)];
		
		// construct query string
		NSMutableArray *tmpArray = [NSMutableArray array];
	
		for (NSString *key in sortedKeys) {
			NSString *value = parameters[key];
			
			// URL-encode
			NSString *encKey = URLENC(key);
			NSString *encValue = URLENC(value);
			
			// combine into pairs
			NSString *tmpStr = [NSString stringWithFormat:@"%@=%@",
                             encKey, encValue];
			[tmpArray addObject:tmpStr];
		}
		
		// append query to path
		path = [path stringByAppendingFormat:@"?%@",
              [tmpArray componentsJoinedByString:@"&"]];
	}
	
   return [NSURL URLWithString:path
                 relativeToURL:endpointURL];
}

// construct a suitable error
- (NSError *)_errorWithCode:(NSUInteger)code
                          message:(NSString *)message {
   NSDictionary *userInfo;
   
   if (message) {
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
   NSURL *methodURL = [self _methodURLForPath:path
                                   parameters:parameters];
   NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:methodURL];
	
	// add OAuth authorization header
	if ([self.oauthClient isAuthenticated])
	{
		NSString *authHeader = [self.oauthClient authenticationHeaderForRequest:request];
		[request addValue:authHeader forHTTPHeaderField:@"Authorization"];
	}
	
   NSURLSessionDataTask *task = [[self session]
                                 dataTaskWithRequest:request
                                 completionHandler:^(NSData *data,
                                                NSURLResponse *response,
                                                     NSError *error) {
      NSError *retError = error;
      id result = nil;
      
      // check for transport error, e.g. no network connection
      if (retError) {
         
         completion(nil, retError);
         return;
      }
      
      // check if we stayed on API endpoint (invalid host might be redirected via OpenDNS)
      NSString *calledHost = [methodURL host];
      NSString *responseHost = [response.URL host];
      
      if (![responseHost isEqualToString:calledHost]) {
         NSString *msg = [NSString stringWithFormat:
                          @"Expected result host to be '%@' but was '%@'",
                          calledHost, responseHost];
			retError = [self _errorWithCode:999 message:msg];
         completion(nil, retError);
         return;
      }
      
      /*
       // save response into a data file for unit testing
      NSArray *writablePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *documentsPath = [writablePaths lastObject];
      NSString *fileInDocuments = [documentsPath stringByAppendingPathComponent:@"data.txt"];
      
      [data writeToFile:fileInDocuments atomically:NO];
      NSLog(@"output at %@", fileInDocuments);
      */
      // needs to be a HTTP response to get the content type and status
      if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
         NSString *msg = @"Response is not an NSHTTPURLResponse";
         retError = [self _errorWithCode:999 message:msg];
         completion(nil, retError);
         return;
      }
      
      // check for protocol error
      NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
      NSDictionary *headers = [httpResp allHeaderFields];
      NSString *contentType = headers[@"Content-Type"];
      
      if ([contentType isEqualToString:@"application/json"]) {
         // parse either way, also API errors return a JSON response
         result = [NSJSONSerialization JSONObjectWithData:data
                                                  options:0
                                                    error:&retError];
      }
      
      if (httpResp.statusCode >= 400) {
         NSString *message = result[@"message"];
         
         retError = [self _errorWithCode:httpResp.statusCode
                                 message:message];
         
         // wipe result, we have the message already in NSError
         result = nil;
      }
      
      completion(result, retError);
   }];
   
   // tasks are created suspended, this starts it
   [task resume];
}

- (void)searchForGTIN:(NSString *)gtin
           completion:(DTDiscogsCompletion)completion {
	// assert that all parameters are not nil
   NSParameterAssert(gtin);
   NSParameterAssert(completion);
   
   // convert EAN-13 to UPC if leading 0
   if ([gtin length]==13 && [gtin hasPrefix:@"0"]) {
      gtin = [gtin substringFromIndex:1];
   }

	NSString *functionPath = @"/database/search";
	NSDictionary *params = @{@"type": @"release",
									 @"barcode": gtin};
	
   [self _performMethodCallWithPath:functionPath
								 parameters:params
								 completion:completion];
}


// lazy initializer for URL session
- (NSURLSession *)session {
   if (!_session) {
      _session = [NSURLSession sessionWithConfiguration:_configuration];
   }
   
   return _session;
}

- (DTOAuthClient *)oauthClient
{
	if (!_oauthClient)
	{
		_oauthClient = [[DTOAuthClient alloc] initWithConsumerKey:@"mDOdjNkiAPSklsVSIrbF" consumerSecret:@"UvXUCTOgyHKCFEnZpzDThOofaDsZQMyA"];
		
		// set up URLs
		_oauthClient.requestTokenURL = [NSURL URLWithString:@"http://api.discogs.com/oauth/request_token"];
		_oauthClient.userAuthorizeURL = [NSURL URLWithString:@"http://www.discogs.com/oauth/authorize"];
		_oauthClient.accessTokenURL = [NSURL URLWithString:@"http://api.discogs.com/oauth/access_token"];
	}
	
	return _oauthClient;
}

@end
