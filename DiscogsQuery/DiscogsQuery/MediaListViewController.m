//
//  MediaListViewController.m
//  DiscogsQuery
//
//  Created by Oliver Drobnik on 10.04.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import "MediaListViewController.h"
#import "DTCameraPreviewController.h"
#import "Release.h"
#import "DTDiscogs.h"

@interface MediaListViewController () <NSFetchedResultsControllerDelegate, DTCameraPreviewControllerDelegate>

@end

@implementation MediaListViewController
{
   NSManagedObjectContext *_managedObjectContext;
   NSFetchedResultsController *_fetchedResultsController;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   self.navigationItem.rightBarButtonItem = self.editButtonItem;
   

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
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


 // Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
   if (editingStyle == UITableViewCellEditingStyleDelete) {
      NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
      [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
      
      NSError *error = nil;
      if (![context save:&error]) {
         NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
         abort();
      }
   }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
   return sectionInfo.name;
}

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
   Release *release = [_fetchedResultsController objectAtIndexPath:indexPath];
   
   if (release.title)
   {
      cell.textLabel.text = release.title;
      cell.detailTextLabel.text = release.format;
   }
   else
   {
      // don't have infos yet
      cell.textLabel.text = release.barcode;
      cell.detailTextLabel.text = @"No Infos found.";
   }
}

#pragma mark - Fetched Results Controller

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
   [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
   switch(type) {
      case NSFetchedResultsChangeInsert:
         [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      case NSFetchedResultsChangeDelete:
         [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
         break;
   }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
   UITableView *tableView = self.tableView;
   
   switch(type) {
      case NSFetchedResultsChangeInsert:
         [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      case NSFetchedResultsChangeDelete:
         [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      case NSFetchedResultsChangeUpdate:
         [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
         break;
         
      case NSFetchedResultsChangeMove:
         [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
         [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
         break;
   }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
   [self.tableView endUpdates];
}

- (NSFetchedResultsController *)fetchedResultsController
{
   if (!_fetchedResultsController)
   {
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
      _fetchedResultsController.delegate = self;
      
    	NSError *error = nil;
      if (![_fetchedResultsController performFetch:&error]) {
         NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
         abort();
      }
   }
   
   return _fetchedResultsController;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
   if ([segue.identifier isEqualToString:@"showScanner"])
   {
      UINavigationController *nav =  (UINavigationController *)segue.destinationViewController;
      DTCameraPreviewController *preview = (DTCameraPreviewController *)nav.viewControllers[0];
      preview.delegate = self;
   }
}


- (IBAction)unwindFromScannerViewController:(UIStoryboardSegue *)unwindSegue
{
}

- (void)previewController:(DTCameraPreviewController *)previewController didScanCode:(NSString *)code ofType:(NSString *)type
{
   NSEntityDescription *entity = [[_fetchedResultsController fetchRequest] entity];
   Release *release = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:_managedObjectContext];
   
   release.barcode = code;
   release.genre = @"Unknown";
   
   // Save the context.
   NSError *error = nil;
   if (![_managedObjectContext save:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
   }
   
   // dismiss scanner
   [previewController performSegueWithIdentifier:@"unwind" sender:self];
   
   
   DTDiscogs *discogs = [[DTDiscogs alloc] init];
   
   [discogs searchForGTIN:code completion:^(id result, NSError *error) {
      
      if (error)
      {
         return;
      }
      
      if (![result isKindOfClass:[NSDictionary class]])
      {
         return;
      }
      
      NSDictionary *dict = (NSDictionary *)result;
      NSArray *results = dict[@"results"];
      
      if ([results count]<1)
      {
         return;
      }
      
      // always use first result
      NSDictionary *theResult = results[0];
      
      // create temporary context
      NSManagedObjectContext *tmpContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
      tmpContext.parentContext = _managedObjectContext;
      
      // get version of the Release for this context
      Release *updatedRelease = (Release *)[tmpContext objectWithID:release.objectID];
      
      // update values
      updatedRelease.title = theResult[@"title"];
      updatedRelease.genre = [theResult[@"genre"] firstObject];
      updatedRelease.style = [theResult[@"style"] firstObject];
      updatedRelease.format = [theResult[@"format"] firstObject];
      updatedRelease.year = @([theResult[@"year"] integerValue]);
      
      // save, pushes changes up to main MOC
      [tmpContext save:NULL];
   }];
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
