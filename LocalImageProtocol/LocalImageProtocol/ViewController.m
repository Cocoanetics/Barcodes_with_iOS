//
//  ViewController.m
//  LocalImageProtocol
//
//  Created by Oliver Drobnik on 23.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   NSString *html = @"<p>Hello I am Oliver</p>"
      "<img src=\"foobar:Oliver.jpg\" />"
      "<p>This is a nice picture of myself</p>";
   
   [self.webView loadHTMLString:html baseURL:nil];
}

@end
