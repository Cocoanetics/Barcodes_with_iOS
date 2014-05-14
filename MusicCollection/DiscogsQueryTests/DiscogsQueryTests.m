//
//  DiscogsQueryTests.m
//  DiscogsQueryTests
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "DTDiscogs.h"
#import "DTURLProtocolStub.h"

#define API_HOST @"api.discogs.com"


// expose internal method so that we can test it
@interface DTDiscogs (test)

- (void)_performMethodCallWithPath:(NSString *)path
								parameters:(NSDictionary *)parameters
                        completion:(DTDiscogsCompletion)completion;

@end


@interface DiscogsQueryTests : XCTestCase

@end

@implementation DiscogsQueryTests
{
   DTDiscogs *_discogs;
   NSMutableArray *_recordedRequests;
   dispatch_semaphore_t _requestSemaphore;
}

// called before each -test...
- (void)setUp {
   [super setUp];

   // warn us if no response is configured for a request
   [DTURLProtocolStub setMissingResponseBlock:^(NSURLRequest *request) {
      XCTFail(@"No response configured for request to %@", request.URL);
      
      return (NSError *)nil;
   }];
   
   // record requests to IVAR
   _recordedRequests = [NSMutableArray array];
   
   [DTURLProtocolStub setBeforeRequestBlock:^(NSURLRequest *request) {
      [_recordedRequests addObject:request];
   }];

   // create a web service that uses stubbed protocol
   NSURLSessionConfiguration *config = [self _testSessionConfiguration];
   _discogs = [[DTDiscogs alloc] initWithSessionConfiguration:config];
   
   // remove responses left over from previous test case setUp
   [DTURLProtocolStub removeAllResponses];
   
   // semaphore for waiting for end of request
   _requestSemaphore = dispatch_semaphore_create(0);
   
   // for demo: alsxo register protocol stub for normal NSURLConnections
   [NSURLProtocol registerClass:[DTURLProtocolStub class]];
}

#pragma mark - Setup & Helpers

// session config that stubs the HTTP/S protocol
- (NSURLSessionConfiguration *)_testSessionConfiguration {
   NSURLSessionConfiguration *config = [NSURLSessionConfiguration
                                        ephemeralSessionConfiguration];
   config.protocolClasses = @[[DTURLProtocolStub class]];
   
   return config;
}

// returns if the protocol stub is active
- (BOOL)_protocolStubIsRegistered {
   return ([_discogs.session.configuration.protocolClasses
            containsObject:[DTURLProtocolStub class]]);
}

// divides a query string into a dictionary
- (NSDictionary *)_dictionaryFromQueryParams:(NSString *)query {
   NSArray *queryParams = [query
                           componentsSeparatedByString:@"&"];
   
   NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
   
   for (NSString *oneKeyValue in queryParams)
   {
      NSRange rangeOfEqual = [oneKeyValue rangeOfString:@"="];
      
      if (rangeOfEqual.location != NSNotFound)
      {
         NSString *key = [oneKeyValue substringToIndex:
                          rangeOfEqual.location];
         NSString *value = [oneKeyValue substringFromIndex:
                            rangeOfEqual.location+1];
         
         // URL-decode
         key = [key stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding];
         value = [value stringByReplacingPercentEscapesUsingEncoding:
                  NSUTF8StringEncoding];
         
         tmpDict[key] = value;
      }
      
   }
   
   return [tmpDict copy];
}


- (void)_setupProtocolStubForSearch {
   // configure stubbed responses
   NSString *path = [self _pathForResource:@"search_success"
                                    ofType:@"json"];
   
   [DTURLProtocolStub addResponseWithFile:path statusCode:200
    forRequestPassingTest:^BOOL(NSURLRequest *request) {
       if (![request.URL.path isEqualToString:@"/database/search"])
       {
          return NO;
       }
       
       NSArray *queryParams = [request.URL.query
                               componentsSeparatedByString:@"&"];
       
       if (![queryParams containsObject:@"barcode=077774620420"])
       {
          return NO;
       }
       
       return YES;
    }];
   
   // all other searches return no results
   path = [self _pathForResource:@"search_not_found"
                          ofType:@"json"];
   
   [DTURLProtocolStub addResponseWithFile:path statusCode:200
    forRequestPassingTest:^BOOL(NSURLRequest *request) {
                       
       if ([request.URL.path isEqualToString:@"/database/search"])
       {
          return YES;
       }
       
       return NO;
    }];
   
   
   // all other requests are assumed to be a 404
   path = [self _pathForResource:@"resource_not_found"
                          ofType:@"json"];
   
   [DTURLProtocolStub addResponseWithFile:path statusCode:404
                    forRequestPassingTest:NULL];
}

- (NSString *)_pathForResource:(NSString *)resource
                        ofType:(NSString *)type {
   return [[NSBundle bundleForClass:[self class]]
           pathForResource:resource ofType:type];
}

- (void)_expectOneRequestToAPIHost {
   if (![self _protocolStubIsRegistered])
   {
      // stub not registered, nothing recorded
      return;
   }

   NSUInteger requests = [_recordedRequests count];
   XCTAssertEqual(requests, 1, @"There should be only one request");
   
   NSURLRequest *lastRequest = [_recordedRequests lastObject];
   NSString *host = lastRequest.URL.host;
   XCTAssertEqualObjects(host, API_HOST, @"Incorrect host");
}

- (void)_expectSearchRequest {
   if (![self _protocolStubIsRegistered])
   {
      // stub not registered, nothing recorded
      return;
   }
   
   NSURLRequest *lastRequest = [_recordedRequests lastObject];
   
   if (![lastRequest.URL.path isEqualToString:@"/database/search"])
   {
      XCTFail(@"Request was not to search API");
   }
   
   NSDictionary *params = [self _dictionaryFromQueryParams:
                           lastRequest.URL.query];
   
   XCTAssertNotNil(params[@"barcode"], @"query param missing");
}


#pragma mark - Async Helpers

// halts current thread until request signals that it is done
- (void)_waitForRequestToFinish {
   dispatch_semaphore_wait(_requestSemaphore, DISPATCH_TIME_FOREVER);
}

// call at end of async block to unlock the semaphore
- (void)_signalThatRequestIsDone {
   dispatch_semaphore_signal(_requestSemaphore);
}

#pragma mark - Tests

- (void)testInvalidMethod {
   [self _setupProtocolStubForSearch];

   [_discogs _performMethodCallWithPath:@"bla"
                             parameters:nil
      completion:^(id result, NSError *error) {
      
         XCTAssertNil(result, @"There should be no result");
         XCTAssertNotNil(error, @"There should an error");
         XCTAssertEqual(error.code, 404, @"Should be code 404");
         
         [self _signalThatRequestIsDone];
      }];
   
   [self _waitForRequestToFinish];
   [self _expectOneRequestToAPIHost];
}

- (void)testSearchQueen {
   [self _setupProtocolStubForSearch];

   [_discogs searchForGTIN:@"077774620420"
      completion:^(id result, NSError *error) {
         XCTAssertNil(error, @"There should be no error");
         XCTAssertNotNil(result, @"There should be a response");
         XCTAssertTrue([result isKindOfClass:[NSDictionary class]],
                       @"Result should be a dictionary");
         
         NSArray *results = result[@"results"];
         
         XCTAssertEqual([results count], 1, @"One result expected");
         
         NSDictionary *lastResult = [results lastObject];
         NSString *title = lastResult[@"title"];
         
         XCTAssertEqualObjects(title, @"Queen - Queen",
                               @"Title is wrong");
         
         [self _signalThatRequestIsDone];
      }];
   
   [self _waitForRequestToFinish];
   [self _expectOneRequestToAPIHost];
   [self _expectSearchRequest];
}

- (void)testSearchGTINWithCharactersRequiringEncoding {
   [self _setupProtocolStubForSearch];
   NSString *gtin = @"123 = 456";
   
   [_discogs searchForGTIN:gtin
      completion:^(id result, NSError *error) {
         XCTAssertNil(error, @"There should be no error");
         XCTAssertNotNil(result, @"There should be a response");
         XCTAssertTrue([result isKindOfClass:[NSDictionary class]],
                       @"Result should be a dictionary");
         
         NSArray *results = result[@"results"];
         
         XCTAssertEqual([results count], 0, @"No result expected");
         
         [self _signalThatRequestIsDone];
      }];
   
   [self _waitForRequestToFinish];
   [self _expectOneRequestToAPIHost];
   [self _expectSearchRequest];
   
   if ([self _protocolStubIsRegistered]) {
      NSURLRequest *lastRequest = [_recordedRequests lastObject];
      NSDictionary *params = [self _dictionaryFromQueryParams:
                              lastRequest.URL.query];
      
      NSString *searchedGTIN = params[@"barcode"];
      
      XCTAssertEqualObjects(gtin, searchedGTIN, @"gtin should be same");
   }
}

- (void)testSearchNotFound
{
   [self _setupProtocolStubForSearch];
   
   [_discogs searchForGTIN:@"077774620421"
      completion:^(id result, NSError *error) {
      
         XCTAssertNil(error, @"There should be no error");
         XCTAssertNotNil(result, @"There should be a response");
         XCTAssertTrue([result isKindOfClass:[NSDictionary class]],
                       @"Result should be a dictionary");
         
         NSArray *results = result[@"results"];
         
         XCTAssertEqual([results count], 0, @"No result expected");
         [self _signalThatRequestIsDone];
      }];
   
   [self _waitForRequestToFinish];
   [self _expectOneRequestToAPIHost];
   [self _expectSearchRequest];
}


# pragma mark - Demonstrate Unit-Testing NSURLConnection

- (void)testFakeApple {
   NSString *string = @"Hello, I am Apple. Really! ;-)";
   [DTURLProtocolStub addPlainTextResponse:string statusCode:200
                     forRequestPassingTest:^BOOL(NSURLRequest *request) {
                        NSString *host = request.URL.host;
                        
                        if ([host isEqualToString:@"www.apple.com"])
                        {
                           return YES;
                        }
                        
                        return NO;
                     }];

   NSURL *URL = [NSURL URLWithString:@"http://www.apple.com"];
   NSURLRequest *request = [NSURLRequest requestWithURL:URL];
   NSHTTPURLResponse *response;
   NSError *error;
   NSData *data = [NSURLConnection sendSynchronousRequest:request
                                        returningResponse:&response
                                                    error:&error];
   NSString *responseString =
   [[NSString alloc] initWithData:data
                         encoding:NSUTF8StringEncoding];
   
   NSString *contentType = response.allHeaderFields[@"Content-Type"];
   
   XCTAssertEqualObjects(string, responseString,
                         @"wrong response string");
   XCTAssertEqual(response.statusCode, 200,
                  @"Status should be 200");
   XCTAssertEqualObjects(contentType, @"text/plain",
                         @"wrong content type");
}


- (void)testURLConnection404 {
   NSString *string = @"404 Not Found";
   [DTURLProtocolStub addPlainTextResponse:string statusCode:404
                     forRequestPassingTest:NULL];
   
   NSURL *URL = [NSURL URLWithString:@"http://www.apple.com"];
   NSURLRequest *request = [NSURLRequest requestWithURL:URL];
   NSHTTPURLResponse *response;
   NSError *error;
   NSData *data = [NSURLConnection sendSynchronousRequest:request
                                        returningResponse:&response
                                                    error:&error];
   NSString *responseString =
      [[NSString alloc] initWithData:data
                            encoding:NSUTF8StringEncoding];
   
   NSString *contentType = response.allHeaderFields[@"Content-Type"];
   
   XCTAssertEqualObjects(string, responseString,
                         @"wrong response string");
   XCTAssertEqual(response.statusCode, 404,
                  @"Status should be 404");
   XCTAssertEqualObjects(contentType, @"text/plain",
                         @"wrong content type");
}

- (void)testURLConnectionOffline
{
   // simulate offline connection
   NSError *offlineError = [NSError errorWithDomain:@"NSURLErrorDomain"
                                               code:-1009
                                           userInfo:nil];
   
   [DTURLProtocolStub addErrorResponse:offlineError
                 forRequestPassingTest:NULL];
   
   NSURL *URL = [NSURL URLWithString:@"http://www.apple.com"];
   NSURLRequest *request = [NSURLRequest requestWithURL:URL];
   NSHTTPURLResponse *response;
   NSError *error;
   
   // convert response data to string
   NSData *data = [NSURLConnection sendSynchronousRequest:request
                                        returningResponse:&response
                                                    error:&error];
   XCTAssertNil(data, @"There should be no data");
   XCTAssertEqual(error.code, offlineError.code, @"Incorrect error");
   XCTAssertEqualObjects(error.domain, offlineError.domain, @"Incorrect error");
}
@end
