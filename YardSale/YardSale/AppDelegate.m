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
#import "SalePlace.h"

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

   // create location manager or show alerts with insufficient authorization
   [self _enableLocationUpdatesIfAuthorized];
   
   // ask for local notification permission
   [self _authorizeLocalNotifications];
   
   return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
   // create location manager or show alerts with insufficient authorization
   [self _enableLocationUpdatesIfAuthorized];

   // update monitored regions when app becomes active
   if (_mostRecentLoc) {
      [self _updateMonitoredRegionsForLocation:_mostRecentLoc];
   }
}

// received after the user reacts to the local notification action or if the app is in foreground during receipt of the notification
- (void)application:(UIApplication *)application
       didReceiveLocalNotification:(UILocalNotification *)notification {
   NSString *saleID = notification.userInfo[@"SaleID"];
   [self _showSalePlaceForIdentifier:saleID];
}

// on iOS 8 this is called instead if the app is in background
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
- (void)application:(UIApplication *)application
        handleActionWithIdentifier:(NSString *)identifier
        forLocalNotification:(UILocalNotification *)notification
        completionHandler:(void(^)())completionHandler {
   NSString *saleID = notification.userInfo[@"SaleID"];
   [self _showSalePlaceForIdentifier:saleID];
   
   completionHandler();
}
#endif

// on iOS 8 this is called as soon as the user taps on a button on the notification authorization alert
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
 - (void)application:(UIApplication *)application
         didRegisterUserNotificationSettings:
         (UIUserNotificationSettings *)notificationSettings {
   if (!notificationSettings.types) {
      // nothing allowed
      return;
   }
   
   // update monitored regions when notification settings registered
   if (_mostRecentLoc) {
      [self _updateMonitoredRegionsForLocation:_mostRecentLoc];
   }
}
#endif

#pragma mark - Helpers

- (void)_showSalePlaceForIdentifier:(NSString *)identifier {
   MapViewController *vc =
                    (MapViewController *)self.window.rootViewController;
   
   if (vc.presentedViewController) {
      // In-Store VC already showing
      return;
   }
   
   SalePlace *salePlace =
   [_saleManager salePlaceForIdentifier:identifier];
   NSString *msg = [NSString stringWithFormat:@"Welcome to %@",
                    salePlace.title];
   UIAlertView *alert = [[UIAlertView alloc]
                         initWithTitle:@"Glad to see you!"
                         message:msg
                         delegate:nil
                         cancelButtonTitle:@"Ok"
                         otherButtonTitles:nil];
   [alert show];
   
   [vc showInStoreUIForSalePlace:salePlace];
}

- (void)_informUserAboutNoAuthorization
{
   NSString *title = @"Location Updates disabled";
   NSString *msg = @"YardSale cannot access to your location." \
   @"Because of this it cannot alert you to close by yard sales " \
   @"or show your location on the map";
   
   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:msg
                                                      delegate:nil
                                             cancelButtonTitle:@"Ok"
                                             otherButtonTitles:nil];
   
   [alertView show];
}

- (void)_informUserAboutBackgroundAuthorization
{
   NSString *title = @"Location Updates too restrictive";
   NSString *msg = @"YardSale cannot access to your location " \
   @"while the app is not active. Without your authorization " \
   @"we cannot alert you about close by yard sales if you come " \
   @"close to one.\n\n" \
   @"Please go into your privacy " \
   @"settings to authorize background access as well";
   
   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:msg
                                                      delegate:nil
                                             cancelButtonTitle:@"Ok"
                                             otherButtonTitles:nil];
   
   [alertView show];
}

- (void)_enableLocationUpdatesIfAuthorized {
   CLAuthorizationStatus authStatus =
      [CLLocationManager authorizationStatus];
   
   // if denied or restricted all we can do is to tell user
   if (authStatus == kCLAuthorizationStatusRestricted ||
       authStatus == kCLAuthorizationStatusDenied) {
      [self _informUserAboutNoAuthorization];
      _locationMgr = nil;
      return;
   }
   
   // on iOS 8 we might have too restricted location updates
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
   if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
      [self _informUserAboutBackgroundAuthorization];
   }
#endif
   
   // initialize location manager
   if (!_locationMgr) {
      _locationMgr = [[CLLocationManager alloc] init];
      _locationMgr.delegate = self;
      
      // iOS 8: always request, gets ignored if already authorized
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
      if ([_locationMgr
           respondsToSelector:@selector(requestAlwaysAuthorization)]) {
         [_locationMgr requestAlwaysAuthorization];
      }
#endif
      
      // used for normal operation, only interested if there is a significant change in location
      [_locationMgr startMonitoringSignificantLocationChanges];
      
      // used for testing because simulator does not send updates for significant location change monitoring
      
      /*
       _locationMgr.distanceFilter = 1000;
       _locationMgr.desiredAccuracy = kCLLocationAccuracyKilometer;
       [_locationMgr startUpdatingLocation];
       */
   }
}

- (void)_authorizeLocalNotifications {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
   UIApplication *app = [UIApplication sharedApplication];
   if ([app respondsToSelector:
        @selector(registerUserNotificationSettings:)])
   {
      UIUserNotificationSettings *settings =
      [UIUserNotificationSettings settingsForTypes:
       UIUserNotificationTypeAlert|UIUserNotificationTypeSound
                                        categories:nil];
     [app registerUserNotificationSettings:settings];
   }
#endif
}

// after this only the 10 closest regions will be monitored
- (void)_updateMonitoredRegionsForLocation:(CLLocation *)loc
{
   if (![CLLocationManager isMonitoringAvailableForClass:
         [CLCircularRegion class]]) {
      NSLog(@"Monitoring not available for CLCircularRegion");
      return;
   }
   
   // get closest 10 yard sales
   NSArray *sales = [_saleManager annotationsClosestToLocation:loc];
   
   // IDs to monitor
   NSMutableArray *identsToMonitor =
   [[sales valueForKeyPath:@"@unionOfObjects.identifier"] mutableCopy];
   
   for (CLRegion *region in _locationMgr.monitoredRegions) {
      if ([identsToMonitor containsObject:region.identifier]) {
         // already monitoring this, remove it from to-do list
         [identsToMonitor removeObject:region.identifier];
      }
      else {
         // not interested in this any more
         [_locationMgr stopMonitoringForRegion:region];
      }
   }
   
   // add remaining Yard Sales to be monitored
   CLLocationDistance maxDistance = 0;
   
   for (SalePlace *onePlace in sales) {
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
- (void)_sendLocalNoteForSalePlace:(SalePlace *)place
                     afterDuration:(NSTimeInterval)duration {
   if ([_lastNotifiedSaleID isEqualToString:place.identifier]) {
      // already notified this one
      return;
   }
   
   UIApplication *app = [UIApplication sharedApplication];
   
   BOOL shouldAddMsg = YES;
   BOOL shouldAddSound = YES;
   
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
   if ([app respondsToSelector:
        @selector(currentUserNotificationSettings)]) {
      UIUserNotificationSettings *settings =
      [app currentUserNotificationSettings];
      
      if (!settings.types) {
         // we'll come back here in the callback to registering
         return;
      }
      
      if (!(settings.types & UIUserNotificationTypeAlert)) {
         shouldAddMsg = NO;
      }
      
      if (!(settings.types & UIUserNotificationTypeSound)) {
         shouldAddSound = NO;
      }
   }
#endif
   
   NSString *msg = [NSString stringWithFormat:@"%@ is close by!",
                    place.title];
   
   UILocalNotification *note = [[UILocalNotification alloc] init];
   note.alertAction = @"Visit";
   
   if (shouldAddMsg) {
      note.alertBody = msg;
   }
   
   if (shouldAddSound) {
      note.soundName = UILocalNotificationDefaultSoundName;
   }
   
   note.fireDate = [[NSDate date] dateByAddingTimeInterval:duration];
   note.userInfo = @{@"SaleID": place.identifier};
   
   _lastNotifiedSaleID = place.identifier;
   [app scheduleLocalNotification:note];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
   CLLocation *location = [locations lastObject];
   
   if (location.coordinate.longitude
       != _mostRecentLoc.coordinate.longitude ||
       location.coordinate.latitude
       != _mostRecentLoc.coordinate.latitude) {
      _mostRecentLoc = [locations lastObject];
      
      [self _updateMonitoredRegionsForLocation:location];
   }
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region {
   switch (state) {
      case CLRegionStateUnknown: {
         NSLog(@"Unknown %@", region.identifier);
         break;
      }
         
      case CLRegionStateInside: {
         NSLog(@"Inside %@", region.identifier);
         
         // The book only features the ELSE of this IF
         if ([UIApplication sharedApplication].applicationState
                                      == UIApplicationStateBackground) {
            // in background schedule a local notification
            SalePlace *salePlace =
            [_saleManager salePlaceForIdentifier:region.identifier];
            [self _sendLocalNoteForSalePlace:salePlace
                               afterDuration:5];  // set duration to e.g. 5 secs for testing
         }
         else {
            // in foreground open in-store UI right away
            [self _showSalePlaceForIdentifier:region.identifier];
         }
         
         break;
      }
         
      case CLRegionStateOutside: {
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
