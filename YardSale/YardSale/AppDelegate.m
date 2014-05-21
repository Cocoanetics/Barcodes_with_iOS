//
//  AppDelegate.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "AppDelegate.h"
#import "YardSaleManager.h"
#import "MapViewController.h"
#import "SalePlacemark.h"

@interface AppDelegate () <CLLocationManagerDelegate>

@end

@implementation AppDelegate
{
   YardSaleManager *_saleManager;
   CLLocationManager *_locationMgr;
   CLLocation *_mostRecentLoc;
   NSString *_lastNotifiedSaleID;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   // create sale manager
   _saleManager = [YardSaleManager new];
   
   // pass it to root map view
   MapViewController *vc = (MapViewController *)self.window.rootViewController;
   NSAssert([vc isKindOfClass:[MapViewController class]],
            @"Root VC is not a MapViewController!");
   vc.yardSaleManager = _saleManager;
   
   // create location manager
   [self _enableLocationUpdatesIfAuthorized];
   
   return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
   // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
   // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
   // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   
   if (_mostRecentLoc)
   {
      [self _updateMonitoredRegionsForLocation:_mostRecentLoc];
   }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// received after the user reacts to the local notification action or if the app is in foreground during receipt of the notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
   SalePlacemark *salePlace = [self _salePlaceForIdentifier:notification.userInfo[@"SaleID"]];
   NSString *msg = [NSString stringWithFormat:@"Welcome to %@", salePlace.title];
   
   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Glad to see you!" message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
   [alert show];
}

#pragma mark - Helpers

- (void)_enableLocationUpdatesIfAuthorized
{
   CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
   
   switch (authStatus)
   {
      case kCLAuthorizationStatusNotDetermined:
      case kCLAuthorizationStatusAuthorized:
      {
         NSLog(@"authorized or not determined");
         
         // initialize location manager
         if (!_locationMgr)
        {
            _locationMgr = [[CLLocationManager alloc] init];
            _locationMgr.delegate = self;
           
//           [_locationMgr allowDeferredLocationUpdatesUntilTraveled:_locationMgr.maximumRegionMonitoringDistance/2.0 timeout:CLTimeIntervalMax];
           
            [_locationMgr startMonitoringSignificantLocationChanges];
           
           
           // used for testing because simulator does not send updates for significant location change monitoring
           
           /*
           _locationMgr.distanceFilter = 1000;
           _locationMgr.desiredAccuracy = kCLLocationAccuracyKilometer;
           [_locationMgr startUpdatingLocation];
            */
         }
         break;
      }
         
      case kCLAuthorizationStatusDenied:
      case kCLAuthorizationStatusRestricted:
      {
         NSLog(@"policy has restricted location updates or user denied it");
         
         _locationMgr = nil;
         break;
      }
   }
}

// after this only the 10 closest regions will be monitored
- (void)_updateMonitoredRegionsForLocation:(CLLocation *)loc
{
   if (![CLLocationManager isMonitoringAvailableForClass:
         [CLCircularRegion class]])
   {
      NSLog(@"Monitoring not available for CLCircularRegion");
      return;
   }
   
   // get closest 10 yard sales
   NSMutableArray *sales = [[_saleManager
                         annotationsClosestToLocation:loc] mutableCopy];
   
   // IDs to monitor
   NSMutableArray *identsToMonitor =
    [[sales valueForKeyPath:@"@unionOfObjects.identifier"] mutableCopy];
   
   for (CLRegion *region in _locationMgr.monitoredRegions)
   {
      if ([identsToMonitor containsObject:region.identifier])
      {
         // already monitoring this, remove it from to-do list
         [identsToMonitor removeObject:region.identifier];
      }
      else
      {
         // not interested in this any more
         [_locationMgr stopMonitoringForRegion:region];
      }
   }
   
   // add remaining Yard Sales to be monitored
   CLLocationDistance maxDistance = 0;
   
   for (SalePlacemark *onePlace in sales)
   {
      CLLocationDistance dist = [loc distanceFromLocation:onePlace.location];
      maxDistance = MAX(dist, maxDistance);
      
      if (![identsToMonitor containsObject:onePlace.identifier])
      {
         // not interested in this one
         continue;
      }
      
      CLCircularRegion *region =
      [[CLCircularRegion alloc] initWithCenter:onePlace.coordinate
                                        radius:100
                                    identifier:onePlace.identifier];
      [_locationMgr startMonitoringForRegion:region];
   }
   
   // update deferred updates to half of max distance
   [_locationMgr allowDeferredLocationUpdatesUntilTraveled:maxDistance/2.0
                                                   timeout:CLTimeIntervalMax];

   // requires slight delay, fails otherwise if a region was unmonitored
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                (int64_t)(0.2 * NSEC_PER_SEC)),
                  dispatch_get_main_queue(), ^{
      for (CLRegion *oneRegion in _locationMgr.monitoredRegions)
      {
         [_locationMgr requestStateForRegion:oneRegion];
      }
   });
}

- (void)_sendLocalNoteAfterDuration:(NSTimeInterval)duration message:(NSString *)msg soundName:(NSString *)sound userInfo:(NSDictionary *)userInfo
{
   UILocalNotification *note = [[UILocalNotification alloc] init];
   note.alertAction = @"Visit";
   note.alertBody = msg;
   note.fireDate = [[NSDate date] dateByAddingTimeInterval:duration];
   note.soundName = sound;
   note.userInfo = userInfo;
   
   [[UIApplication sharedApplication] scheduleLocalNotification:note];
}

- (SalePlacemark *)_salePlaceForIdentifier:(NSString *)identifier
{
   NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
   NSArray *matches = [[_saleManager annotations] filteredArrayUsingPredicate:predicate];
   return [matches firstObject];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   
   CLLocation *location = [locations lastObject];
   
   if (location.coordinate.longitude != _mostRecentLoc.coordinate.longitude ||
       location.coordinate.latitude != _mostRecentLoc.coordinate.latitude)
   {
      _mostRecentLoc = [locations lastObject];
      
      [self _updateMonitoredRegionsForLocation:location];
   }
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
   switch (state)
   {
      case CLRegionStateUnknown:
      {
         NSLog(@"Unknown %@", region.identifier);
         
         break;
      }
         
      case CLRegionStateInside:
      {
         NSLog(@"Inside %@", region.identifier);
         
         if ([_lastNotifiedSaleID isEqualToString:region.identifier])
         {
            // already notified this one
            return;
         }
         
         SalePlacemark *salePlace = [self _salePlaceForIdentifier:region.identifier];
         NSString *msg = [NSString stringWithFormat:@"%@ is closeby!", salePlace.title];
         NSDictionary *userInfo = @{@"SaleID": region.identifier};
         [self _sendLocalNoteAfterDuration:5 message:msg soundName:UILocalNotificationDefaultSoundName userInfo:userInfo];
         
         _lastNotifiedSaleID = region.identifier;
         
         break;
      }
         
      case CLRegionStateOutside:
      {
         NSLog(@"Outside %@", region.identifier);
         
         break;
      }
   }
}

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error
{
   NSLog(@"%@", error);
}

@end
