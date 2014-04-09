//
//  DiscogsQueryTests.m
//  DiscogsQueryTests
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "DTDiscogs.h"
//#import "MockedURLProtocol.h"

#import "DTURLProtocolStub.h"


@interface DTDiscogs (test)

- (void)_performMethodCallWithPath:(NSString *)path
								parameters:(NSDictionary *)parameters
                        completion:(DTDiscogsCompletion)completion;

@end


@interface DiscogsQueryTests : XCTestCase

@property (nonatomic, strong) DTDiscogs *discogs;

@end

@implementation DiscogsQueryTests


- (NSData *)_dataForBundleFile:(NSString *)file
{
   NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:nil];
   return [NSData dataWithContentsOfFile:path];
}

- (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type
{
   return [[NSBundle bundleForClass:[self class]] pathForResource:resource ofType:type];
}

- (NSURLSessionConfiguration *)_mockedSessionConfiguration
{
   NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
   config.protocolClasses = @[[DTURLProtocolStub class]];

   // configure stubbed responses
   NSString *path = [self pathForResource:@"query1_response" ofType:@"json"];

   [DTURLProtocolStub addResponseWithFile:path
               forRequestPassingTest:^BOOL(NSURLRequest *request) {
                  
                  if (![request.URL.host isEqualToString:@"api.discogs.com"])
                  {
                     return NO;
                  }
                  
                  if (![request.URL.path isEqualToString:@"/database/search"])
                  {
                     return NO;
                  }
                  
                  NSArray *queryParams = [request.URL.query componentsSeparatedByString:@"&"];
                  
                  if (![queryParams containsObject:@"barcode=077774620420"])
                  {
                     return NO;
                  }
                  
                  return YES;
               }];
   
   // after all other evaluators we return 404
   [DTURLProtocolStub addResponse:[DTURLProtocolResponse responseWithData:nil statusCode:404 headers:nil]
               forRequestPassingTest:^BOOL(NSURLRequest *request) {
                  
                  return YES;
               }];
  
   return config;
}

- (void)setUp
{
   [super setUp];
   
   self.discogs = [[DTDiscogs alloc] initWithSessionConfiguration:[self _mockedSessionConfiguration]];
}


- (void)testInvalidMethod
{
   dispatch_semaphore_t sema = dispatch_semaphore_create(0);
   
   [self.discogs _performMethodCallWithPath:@"bla" parameters:nil completion:^(id result, NSError *error) {
      
      XCTAssertNil(result, @"There should be no result");
      XCTAssertNotNil(error, @"There should an error");
      
      dispatch_semaphore_signal(sema);
   }];
   
   dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)testSearchQueen
{
   dispatch_semaphore_t sema = dispatch_semaphore_create(0);
   
   [self.discogs searchForGTIN:@"077774620420" completion:^(id result, NSError *error) {
      
      XCTAssertNil(error, @"There should be no error");
      XCTAssertNotNil(result, @"There should be a response");
      XCTAssertTrue([result isKindOfClass:[NSDictionary class]], @"Result should be a dictionary");
      
      NSArray *results = result[@"results"];
      
      XCTAssertEqual([results count], 1, @"There should be exactly one result");
      
      NSString *title = results[0][@"title"];
      
      XCTAssertEqualObjects(title, @"Queen - Queen", @"Title is wrong");
      
      dispatch_semaphore_signal(sema);
   }];
 
   dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)testSearchNotFound
{
   dispatch_semaphore_t sema = dispatch_semaphore_create(0);
   
   [self.discogs searchForGTIN:@"077774620421" completion:^(id result, NSError *error) {
      
      XCTAssertNotNil(error, @"There should be an error");
      XCTAssertEqualObjects(error.domain, DTDiscogsErrorDomain, @"Error domain should be DTDiscogsErrorDomain");
      
      XCTAssertEqual(error.code, 404, @"Should be a 404");
      
      dispatch_semaphore_signal(sema);
   }];
   
   dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

@end
