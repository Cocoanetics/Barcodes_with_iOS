//
//  DiscogsQueryTests.m
//  DiscogsQueryTests
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "DTDiscogs.h"
#import "MockedURLProtocol.h"


@interface DTDiscogs (test)

- (void)_performMethodCallWithPath:(NSString *)path
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

- (NSURLSessionConfiguration *)_mockedSessionConfiguration
{
   NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
   config.protocolClasses = @[[MockedURLProtocol class]];

   NSData *data = [self _dataForBundleFile:@"query1_response.json"];
   NSURL *URL = [NSURL URLWithString:@"http://api.discogs.com/database/search?type=release&barcode=077774620420"];
   [MockedURLProtocol registerResponseData:data forURL:URL];
  
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
   
   [self.discogs _performMethodCallWithPath:@"bla" completion:^(id result, NSError *error) {
      
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

@end
