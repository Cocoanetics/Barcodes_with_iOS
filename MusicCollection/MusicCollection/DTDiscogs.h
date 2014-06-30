//
//  DTDiscogs.h
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 03.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

extern NSString * const DTDiscogsErrorDomain;

@class DTOAuthClient;

/*
 Completion handler for Discogs API calls
 */
typedef void (^DTDiscogsCompletion)(id result, NSError *error);

/**
 Wrapper for API calls to Discogs service
 */
@interface DTDiscogs : NSObject

// designated initializer
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 Search for releases on the Discogs database for a GTIN
 */
- (void)searchForGTIN:(NSString *)gtin completion:(DTDiscogsCompletion)completion;

- (NSURLSession *)session;

@property (nonatomic, strong) DTOAuthClient *oauthClient;

@end
