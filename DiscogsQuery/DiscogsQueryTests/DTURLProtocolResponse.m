//
//  DTMockedServerResponse.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTURLProtocolResponse.h"

@interface DTURLProtocolResponse ()

@property (nonatomic, copy) NSData *data;
@property (nonatomic, assign) NSUInteger statusCode;
@property (nonatomic, copy) NSDictionary *headers;

@end


@implementation DTURLProtocolResponse
{
   NSData *_data;
   NSUInteger _statusCode;
   NSDictionary *_headers;
}

+ (instancetype)responseWithData:(NSData *)data statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers
{
   DTURLProtocolResponse *response = [[DTURLProtocolResponse alloc] init];
   
   response.data = data;
   response.statusCode = statusCode;
   response.headers = headers;
   
   return response;
}

+ (instancetype)responseWithFile:(NSString *)path statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers
{
   NSData *data = [NSData dataWithContentsOfFile:path];
   
   NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:headers];
   
   NSString *extension = [path pathExtension];
   NSString *contentType = @"application/octet-stream";
   
   if ([extension isEqualToString:@"json"])
   {
      contentType = @"application/json";
   }
   
   tmpDict[@"Content-Type"] = contentType;
   
   return [self responseWithData:data statusCode:statusCode headers:tmpDict];
}

//+ (instancetype)JSONResponseWithObject:(id)object statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers
//{
//   if (![NSJSONSerialization isValidJSONObject:object])
//   {
//      NSLog(@"Cannot encode passed object in JSON");
//      return nil;
//   }
//   
//   NSMutableDictionary *tmpHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
//   
//   // add JSON
//   
//   
//   
//}

@end
