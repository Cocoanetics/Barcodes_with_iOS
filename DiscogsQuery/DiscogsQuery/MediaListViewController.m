//
//  MediaListViewController.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 10.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "MediaListViewController.h"

@interface MediaListViewController ()

@end

@implementation MediaListViewController
{
   NSManagedObjectContext *_managedObjectContext;
   NSFetchedResultsController *_fetchedResultsController;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
   
   
   NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
   // Edit the entity name as appropriate.
   NSEntityDescription *entity = [NSEntityDescription entityForName:@"Release" inManagedObjectContext:[self managedObjectContext]];
   [fetch setEntity:entity];
   
   NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
   
   fetch.sortDescriptors = @[sort];
   
   _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch
                                                                   managedObjectContext:[self managedObjectContext]
                                                                     sectionNameKeyPath:@"genre"
                                                                              cacheName:@"genre"];
   
   // do initial fetch
   NSError *error;
	NSArray *results = [_managedObjectContext executeFetchRequest:fetch error:&error];
	
	if (!results)
	{
		NSLog(@"error occured fetching %@", [error localizedDescription]);
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   id <NSFetchedResultsSectionInfo> sectionInfo = [_fetchedResultsController sections][section];
   return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReleaseCell" forIndexPath:indexPath];
   
   [self configureCell:cell atIndexPath:indexPath];
   
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
   NSManagedObject *object = [_fetchedResultsController objectAtIndexPath:indexPath];
   cell.textLabel.text = [object valueForKey:@"title"];
   cell.detailTextLabel.text = [object valueForKey:@"format"];
}

#pragma mark - Properties

- (NSManagedObjectContext *)managedObjectContext
{
   if (!_managedObjectContext)
   {
      NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DiscogsModel" withExtension:@"momd"];
      NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
      
      // store DB in Documents
      NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
      NSString *storePath = [docPath stringByAppendingPathComponent:@"Discogs.db"];
      
      // setup persistent store coordinator
      NSURL *storeURL = [NSURL fileURLWithPath:storePath];
      
      NSError *error = nil;
      NSPersistentStoreCoordinator *store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
      
      if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
      {
         // inconsistent model/store
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
         
         // retry once
         if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
         {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
         }
      }
      
      // MOC suitable for interaction with UIKit
      _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
      _managedObjectContext.persistentStoreCoordinator = store;
   }
   
   return _managedObjectContext;
}

@end
