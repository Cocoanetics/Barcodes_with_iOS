//
//  AppDelegate.m
//  LocalImageProtocol
//
//  Created by Oliver Drobnik on 23.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "AppDelegate.h"
#import "LocalImageProtocol.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   // register for global NSURLRequests
   [NSURLProtocol registerClass:[LocalImageProtocol class]];
   
   // Override point for customization after application launch.
   return YES;
}

@end
