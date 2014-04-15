//
//  DTURLProtocolResponse.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 08.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "DTURLProtocolResponse.h"

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#endif

@interface DTURLProtocolResponse ()

@property (nonatomic, copy) NSData *data;
@property (nonatomic, assign) NSUInteger statusCode;
@property (nonatomic, copy) NSDictionary *headers;
@property (nonatomic, copy) NSError *error;

@end


@implementation DTURLProtocolResponse
{
   NSData *_data;
   NSUInteger _statusCode;
   NSDictionary *_headers;
   NSError *_error;
}

+ (instancetype)responseWithData:(NSData *)data statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers
{
   DTURLProtocolResponse *response = [[DTURLProtocolResponse alloc] init];
   
   // make mutable to add content length
   NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:headers];
   
   if ([data length])
   {
      NSString *lengthStr = [@([data length]) description];
      tmpDict[@"Content-Length" ] = lengthStr;
   }
   
   response.data = data;
   response.statusCode = statusCode;
   response.headers = tmpDict;
   
   return response;
}

+ (instancetype)responseWithFile:(NSString *)path statusCode:(NSUInteger)statusCode headers:(NSDictionary *)headers
{
   NSData *data = [NSData dataWithContentsOfFile:path];

   NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:headers];

   if ([data length])
   {
      NSString *extension = [path pathExtension];
      NSString *contentType;
      
      if (extension)
      {
         // ask for MIME type for the extension
         CFStringRef typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL);
         contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(typeForExt, kUTTagClassMIMEType);
         CFRelease(typeForExt);
      }
      
      if ([data length] && !contentType)
      {
         contentType = @"application/octet-stream";
      }
      
      tmpDict[@"Content-Type"] = contentType;
   }
   
   return [self responseWithData:data statusCode:statusCode headers:tmpDict];
}

+ (instancetype)responseWithError:(NSError *)error
{
   DTURLProtocolResponse *response = [[DTURLProtocolResponse alloc] init];
   response.error = error;
   return response;
}

@end
