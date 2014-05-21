//
//  ViewController.m
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "MapViewController.h"
#import "SalePlacemark.h"

@interface MapViewController () <MKMapViewDelegate>

@end

@implementation MapViewController
{
   NSArray *_annotations;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   [self _loadAnnotations];
   
   // add annotations to map
   [self.mapView addAnnotations:_annotations];
   
   // zoom to fit all annoations
   [self.mapView showAnnotations:_annotations animated:YES];
}

#pragma mark - Helpers

- (void)_loadAnnotations
{
   NSString *path =[[NSBundle mainBundle] pathForResource:@"Locations"
                                                   ofType:@"plist"];
   NSArray *locs = [NSArray arrayWithContentsOfFile:path];
   NSMutableArray *tmpArray = [NSMutableArray array];
   for (NSDictionary *oneLoc in locs)
   {
      SalePlacemark *place = [[SalePlacemark alloc] initWithDictionary:oneLoc];
      [tmpArray addObject:place];
   }
   _annotations = [tmpArray copy];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
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
