//
//  YardSaleTableViewController.m
//  YardSale
//
//  Created by Oliver Drobnik on 22.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "InStoreViewController.h"
#import "SalePlace.h"
#import "DTCameraPreviewController.h"

#define NUMBER_TABLES 5

@interface InStoreViewController () <CLLocationManagerDelegate,
                                     DTCameraPreviewControllerDelegate>

@end

@implementation InStoreViewController
{
   CLLocationManager *_beaconManager;
   CLBeaconRegion *_inStoreRegion;
   NSInteger _filteredTable;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"C70EEE03-8E77-4A57-B462-13CB0A3ED97E"];
   _inStoreRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"In-Store"];
   
   // default is to show all products
   _filteredTable = -1;
}

- (void)viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:animated];
   
   // set title to show that this is a specific store
   self.navigationItem.title = self.salePlace.title;
   
   if (![CLLocationManager isRangingAvailable])
   {
      NSLog(@"Ranging not available");
      return;
   }
   
   // create dedicated beacon ranging manager
   _beaconManager = [[CLLocationManager alloc] init];
   _beaconManager.delegate = self;
   [_beaconManager startRangingBeaconsInRegion:_inStoreRegion];
}

- (void)viewWillDisappear:(BOOL)animated
{
   // clean up beacon ranging
   [_beaconManager stopMonitoringForRegion:_inStoreRegion];
   _beaconManager.delegate = nil;
   _beaconManager = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   // Return the number of sections.
   return NUMBER_TABLES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if (_filteredTable == -1 || section == _filteredTable)
   {
      return 10;
   }
   
   // hide table
   return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
   cell.textLabel.text = [NSString stringWithFormat:@"Product %ld on table %ld", (long)indexPath.row+1, (long)indexPath.section+1];
   
   return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   if (_filteredTable == -1 || section == _filteredTable)
   {
      return [NSString stringWithFormat:@"Table %ld", (long)section+1];
   }
   
   // hide table section header
   return nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
   // remove beacons that have disappeared
   NSPredicate *pred = [NSPredicate predicateWithFormat:@"rssi < 0 AND proximity > 0"];
   beacons = [beacons filteredArrayUsingPredicate:pred];
   
   if (![beacons count])
   {
      // no beacons, show all tables
      [self setFilteredTable:-1];
      return;
   }
   
   // sort beacons by signal strength
   NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"rssi" ascending:NO];
   beacons = [beacons sortedArrayUsingDescriptors:@[sort]];
   
   // get first beacon, this is the closest
   CLBeacon *beacon = [beacons firstObject];
   NSInteger closestTable = [beacon.minor integerValue];
   
   // filter products to only show this table
   [self setFilteredTable:closestTable];
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error
{
   NSLog(@"%@", [error localizedDescription]);
   
   // show all tables/sections
   [self setFilteredTable:-1];
}

#pragma mark - Navigation

- (IBAction)unwindFromScannerViewController:(UIStoryboardSegue *)segue {
   // intentionally left black
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
   if ([segue.identifier isEqualToString:@"ShowScanner"])
   {
      UINavigationController *nav = [segue destinationViewController];
      DTCameraPreviewController *vc = nav.viewControllers[0];
      vc.delegate = self;
   }
}

- (void)previewController:(DTCameraPreviewController *)previewController
              didScanCode:(NSString *)code ofType:(NSString *)type
{
   // dismiss scanner
   [previewController performSegueWithIdentifier:@"unwind" sender:self];
   
   NSString *msg;
   
   if (_filteredTable>=0)
   {
      msg = [NSString stringWithFormat:@"Scanned '%@' "
             "from table %ld "
             "%@", code, (long)_filteredTable+1,
             _salePlace.title];
   }
   else
   {
      msg = [NSString stringWithFormat:@"Scanned '%@' "
             "at %@", code,
             _salePlace.title];
   }


   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Scanned!"
                                                   message:msg
                                                  delegate:nil
                                         cancelButtonTitle:@"Ok"
                                         otherButtonTitles:nil];
   [alert show];
}

#pragma mark - Properties

- (void)setFilteredTable:(NSInteger)table
{
   if (table != _filteredTable)
   {
      _filteredTable = table;
      
      // refresh table sections with animation
      NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, NUMBER_TABLES)];
      [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
   }
}

@end
