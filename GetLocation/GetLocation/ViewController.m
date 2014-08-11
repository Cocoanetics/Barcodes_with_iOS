//
//  ViewController.m
//  GetLocationTest
//
//  Created by Oliver Drobnik on 15.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <CLLocationManagerDelegate>

@end

@implementation ViewController
{
   CLLocationManager *_locationMgr;
   CLLocation *_mostRecentLoc;
   CLGeocoder *_geoCoder;
   
   NSDictionary *_addressDictionary;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
   // initialize geo coder
   _geoCoder = [[CLGeocoder alloc] init];
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:animated];
   
   [self _enableLocationUpdatesIfAuthorized];
}

- (void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_enableLocationUpdatesIfAuthorized
{
   CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
   
   switch (authStatus)
   {
      default: // also handles iOS 8 status codes
      case kCLAuthorizationStatusNotDetermined:
      case kCLAuthorizationStatusAuthorized:
      {
         NSLog(@"authorized or not determined");
         
         // initialize location manager
         if (!_locationMgr)
         {
            _locationMgr = [[CLLocationManager alloc] init];
            _locationMgr.delegate = self;

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
            // on iOS 8 you need to explicitly request authorization
            if ([_locationMgr respondsToSelector:@selector(requestWhenInUseAuthorization)])
            {
               [_locationMgr requestWhenInUseAuthorization];
            }
#endif
            
            [_locationMgr startUpdatingLocation];
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

#pragma mark - Helpers

- (void)_updateLatLongLabelsWithLocation:(CLLocation *)location
{
   dispatch_async(dispatch_get_main_queue(), ^{
      self.latitudeLabel.text = [NSString stringWithFormat:@"%f", location.coordinate.latitude];
      self.longitudeLabel.text = [NSString stringWithFormat:@"%f", location.coordinate.longitude];
   });
}

- (void)_updateAddressLabelWithPlacemark:(CLPlacemark *)placemark
{
   dispatch_async(dispatch_get_main_queue(), ^{
      _addressDictionary = placemark.addressDictionary;
      NSString *addressStr = ABCreateStringWithAddressDictionary(_addressDictionary, YES);
      self.addressTextView.text = addressStr;
   });
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
   CLLocation *location = [locations lastObject];
   
   if (location.coordinate.longitude != _mostRecentLoc.coordinate.longitude ||
       location.coordinate.latitude != _mostRecentLoc.coordinate.latitude)
   {
      [self _updateLatLongLabelsWithLocation:location];
      
      [_geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
         if (placemarks)
         {
            CLPlacemark *placemark = [placemarks firstObject];
            [self _updateAddressLabelWithPlacemark:placemark];
         }
         else
         {
            NSLog(@"Error from geocoder: %@", [error localizedDescription]);
         }
      }];
      
      _mostRecentLoc = [locations lastObject];
   }
}

#pragma mark - Notifications

// when app comes into foreground and also following the initial authorization dialog
- (void)didBecomeActive:(NSNotification *)notification
{
   [self _enableLocationUpdatesIfAuthorized];
}

#pragma mark - Actions

- (IBAction)copyAddress:(id)sender
{
   ABRecordRef record = ABPersonCreate();
   
   ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)(@"My Location"), nil);
   
   ABMutableMultiValueRef multiHome = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
   
   bool didAddHome = ABMultiValueAddValueAndLabel(multiHome, (__bridge CFTypeRef)(_addressDictionary), kABHomeLabel, NULL);
   
   if(didAddHome)
   {
      ABRecordSetValue(record, kABPersonAddressProperty, multiHome, NULL);
      
      NSLog(@"Address saved.");
   }
   
   NSString *mapString = [NSString stringWithFormat:@"http://maps.apple.com/?q=%f,%f&sspn=0.002828,0.006132&sll=%f,%f", _mostRecentLoc.coordinate.latitude, _mostRecentLoc.coordinate.longitude, _mostRecentLoc.coordinate.latitude, _mostRecentLoc.coordinate.longitude];
   
   // Adding url
   ABMutableMultiValueRef urlMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
   ABMultiValueAddValueAndLabel(urlMultiValue, (__bridge CFTypeRef)(mapString), (__bridge CFTypeRef)@"Map URL", NULL);
   ABRecordSetValue(record, kABPersonURLProperty, urlMultiValue, nil);
   CFRelease(urlMultiValue);
   
   CFArrayRef people = CFArrayCreate(NULL, &record, 1, NULL);
   
   NSData *data = CFBridgingRelease(ABPersonCreateVCardRepresentationWithPeople(people));
   CFRelease(people);
   CFRelease(record);
   
   NSString* vcardString;
   vcardString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
   NSLog(@"%@",vcardString);
   
   
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
   NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
   
   NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"pin.loc.vcf"];
   [vcardString writeToFile:filePath
                 atomically:YES encoding:NSUTF8StringEncoding error:NULL];
   
   NSURL *url =  [NSURL fileURLWithPath:filePath];
   NSLog(@"url> %@ ", [url absoluteString]);
   
   
   // Share Code //
   NSArray *itemsToShare = [[NSArray alloc] initWithObjects: url, nil] ;
   UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
   activityVC.excludedActivityTypes = @[UIActivityTypePrint,
                                        UIActivityTypeCopyToPasteboard,
                                        UIActivityTypeAssignToContact,
                                        UIActivityTypeSaveToCameraRoll,
                                        UIActivityTypePostToWeibo];
   
   if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
   {
      [self presentViewController:activityVC animated:YES completion:nil];
   }
}


@end
