//
//  ViewController.h
//  YardSale
//
//  Created by Oliver Drobnik on 21.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

@class YardSaleManager, SalePlace;

@interface MapViewController : UIViewController

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, strong) YardSaleManager *yardSaleManager;

- (void)showInStoreUIForSalePlace:(SalePlace *)place;

@end
