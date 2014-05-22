//
//  YardSaleTableViewController.h
//  YardSale
//
//  Created by Oliver Drobnik on 22.05.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

@class SalePlace;

@interface InStoreViewController : UITableViewController

@property (nonatomic, strong) SalePlace *salePlace;
@property (nonatomic, assign) BOOL showWelcomeAlert;

@end
