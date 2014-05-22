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

- (BOOL)application:(UIApplication *)application
             didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   // create sale manager
   _saleManager = [YardSaleManager new];
   
   // pass it to root map view
   MapViewController *vc =
      (MapViewController *)self.window.rootViewController;
   NSAssert([vc isKindOfClass:[MapViewController class]],
            @"Root VC is not a MapViewController!");
   vc.yardSaleManager = _saleManager;
   
   // create location manager
   [self _enableLocationUpdatesIfAuthorized];
   
   return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   // update monitored regions when app becomes active
   if (_mostRecentLoc)
   {
      [self _updateMonitoredRegionsForLocation:_mostRecentLoc];
   }
}

// received after the user reacts to the local notification action or if the app is in foreground during receipt of the notification
- (void)application:(UIApplication *)application
         didReceiveLocalNotification:(UILocalNotification *)notification
{
   SalePlacemark *salePlace =
      [self _salePlaceForIdentifier:notification.userInfo[@"SaleID"]];
   NSString *msg = [NSString stringWithFormat:@"Welcome to %@",
                    salePlace.title];
   
   UIAlertView *alert = [[UIAlertView alloc]
                         initWithTitle:@"Glad to see you!"
                         message:msg
                         delegate:nil
                         cancelButtonTitle:@"Ok"
                         otherButtonTitles:nil];
   [alert show];
}

#pragma mark - Helpers

- (void)_enableLocationUpdatesIfAuthorized
{
   CLAuthorizationStatus authStatus =
      [CLLocationManager authorizationStatus];
   
   switch (authStatus)
   {
      case kCLAuthorizationStatusNotDetermined:
      case kCLAuthorizationStatusAuthorized:
      {
         // initialize location manager
         if (!_locationMgr)
         {
            _locationMgr = [[CLLocationManager alloc] init];
            _locationMgr.delegate = self;
            
            // used for normal operation, only interested if there is a significant change in location
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
   NSArray *sales = [_saleManager annotationsClosestToLocation:loc];
   
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
      CLLocationDistance dist =
         [loc distanceFromLocation:onePlace.location];
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
      region.notifyOnExit = NO; // don't care
      [_locationMgr startMonitoringForRegion:region];
   }
   
   // update deferred updates to half of max distance
   [_locationMgr
    allowDeferredLocationUpdatesUntilTraveled:maxDistance/2.0
    timeout:CLTimeIntervalMax];
   
   // requires slight delay, fails otherwise if a region was unmonitored
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                (int64_t)(0.2 * NSEC_PER_SEC)),
                  dispatch_get_main_queue(), ^{
                     for (CLRegion *oneRegion in
                          _locationMgr.monitoredRegions)
                     {
                        [_locationMgr requestStateForRegion:oneRegion];
                     }
                  });
}

// sends a local notification for a Yard Sale Place
- (void)_sendLocalNoteForSalePlace:(SalePlacemark *)place
                     afterDuration:(NSTimeInterval)duration
{
   NSString *msg = [NSString stringWithFormat:@"%@ is closeby!",
                    place.title];
   
   UILocalNotification *note = [[UILocalNotification alloc] init];
   note.alertAction = @"Visit";
   note.alertBody = msg;
   note.fireDate = [[NSDate date] dateByAddingTimeInterval:duration];
   note.soundName = UILocalNotificationDefaultSoundName;
   note.userInfo = @{@"SaleID": place.identifier};
   
   [[UIApplication sharedApplication] scheduleLocalNotification:note];
}

- (SalePlacemark *)_salePlaceForIdentifier:(NSString *)identifier
{
   NSPredicate *predicate =
   [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
   NSArray *matches =
   [[_saleManager annotations] filteredArrayUsingPredicate:predicate];
   return [matches firstObject];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
   CLLocation *location = [locations lastObject];
   
   if (location.coordinate.longitude
       != _mostRecentLoc.coordinate.longitude ||
       location.coordinate.latitude
       != _mostRecentLoc.coordinate.latitude)
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
         
         SalePlacemark *salePlace =
         [self _salePlaceForIdentifier:region.identifier];
         [self _sendLocalNoteForSalePlace:salePlace
                            afterDuration:0];
         
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
   NSLog(@"Monitoring failure: %@", [error localizedDescription]);
}

@end
