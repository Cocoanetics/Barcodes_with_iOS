//
//  ViewController.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "MapViewController.h"
#import "SalePlacemark.h"
#import "YardSaleManager.h"

@interface MapViewController () <MKMapViewDelegate>

@end

@implementation MapViewController


- (void)viewDidLoad
{
   [super viewDidLoad];
   
   // get all annotations from manager
   NSArray *annotations = _yardSaleManager.annotations;
   
   // add annotations to map
   [self.mapView addAnnotations:annotations];
   
   // zoom to fit all annoations
   [self.mapView showAnnotations:annotations animated:YES];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
   
   if ([annotation isKindOfClass:[MKUserLocation class]])
   {
      return nil;
   }
   
   MKPinAnnotationView *pav = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
   pav.canShowCallout = YES;
   
   UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
   pav.rightCalloutAccessoryView=detailButton;
   pav.enabled = YES;
   return pav;
}

//-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
//{
//   NSLog(@"Title:%@",[view.annotation description]);
//}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
   // hide the bubble
   [mapView deselectAnnotation:view.annotation animated:YES];
}


@end
