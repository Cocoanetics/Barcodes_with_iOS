//
//  ViewController.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "MapViewController.h"
#import "InStoreViewController.h"

#import "SalePlace.h"
#import "YardSaleManager.h"

@interface MapViewController () <MKMapViewDelegate>

@end

@implementation MapViewController


- (void)viewDidLoad {
   [super viewDidLoad];
   
   // get all annotations from manager
   NSArray *annotations = _yardSaleManager.annotations;
   
   // add annotations to map
   [self.mapView addAnnotations:annotations];
   
   // zoom to fit all annoations
   [self.mapView showAnnotations:annotations animated:YES];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation {
   if ([annotation isKindOfClass:[MKUserLocation class]]) {
      return nil;
   }
   
   MKPinAnnotationView *pav =
      [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                      reuseIdentifier:nil];
   // otherwise no callout is shown on selection
   pav.canShowCallout = YES;
   
   UIButton *detailButton =
      [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
   pav.rightCalloutAccessoryView=detailButton;
   return pav;
}

- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)view
 calloutAccessoryControlTapped:(UIControl *)control {
//   // hide the bubble
   [mapView deselectAnnotation:view.annotation animated:YES];
   
   // show in-store UI
   [self performSegueWithIdentifier:@"ShowSalePlace" sender:view];
}

#pragma mark - Navigation

- (void)showInStoreUIForSalePlace:(SalePlace *)place {
   MKAnnotationView *view = [self.mapView viewForAnnotation:place];
   [self performSegueWithIdentifier:@"ShowSalePlace" sender:view];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   if ([segue.identifier isEqualToString:@"ShowSalePlace"]) {
      UINavigationController *nav = [segue destinationViewController];
      InStoreViewController *vc = nav.viewControllers[0];
      vc.salePlace = [sender annotation];
   }
}

- (IBAction)unwindFromStoreDetail:(UIStoryboardSegue *)segue {
   // dummy, nothing to do here
}

@end
