//
//  ViewController.m
//  SimpleDownload
//
//  Created by Oliver Drobnik on 16.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (IBAction)download:(id)sender {
   // configure the session
   NSURLSessionConfiguration *conf = [NSURLSessionConfiguration
                                      defaultSessionConfiguration];
   NSURLSession *session = [NSURLSession sessionWithConfiguration:conf];
   
   // create the request
   NSURL *URL = [NSURL URLWithString:self.urlField.text];
   NSURLRequest *request = [NSURLRequest requestWithURL:URL];
   
   // create the task with completion handler
   NSURLSessionDownloadTask *task =
      [session downloadTaskWithRequest:request
         completionHandler:^(NSURL *location,
                             NSURLResponse *response,
                             NSError *error) {
      
      if (error)
      {
         NSLog(@"download error: %@", [error localizedDescription]);
         return;
      }
      
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
      
      if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
         NSLog(@"Not a HTTP response!");
         return;
      }
            
      NSDictionary *headers = [httpResponse allHeaderFields];
      NSString *contentType = headers[@"Content-Type"];
            
      if (![contentType hasPrefix:@"image"]) {
         NSLog(@"Not an image!");
         return;
      }
         
      // load data right away because file will be deleted at end of block
      NSData *data = [NSData dataWithContentsOfURL:location];
      
      // back to main thread
      dispatch_async(dispatch_get_main_queue(), ^{
         UIImage *image = [UIImage imageWithData:data];
         self.imageView.image = image;
      });
   }];
   
   
   // all tasks are created suspended, start it
   [task resume];
}

@end
