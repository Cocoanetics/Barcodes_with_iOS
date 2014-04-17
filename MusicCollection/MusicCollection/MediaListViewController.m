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
#import "ReleaseCell.h"
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
   
   // show edit button
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
   ReleaseCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReleaseCell" forIndexPath:indexPath];
   
   [self configureCell:cell atIndexPath:indexPath];
   
   return cell;
}

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

- (NSString *)tableView:(UITableView *)tableView
                              titleForHeaderInSection:(NSInteger)section
{
   id <NSFetchedResultsSectionInfo> sectionInfo =
      [self.fetchedResultsController sections][section];
   return sectionInfo.name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
                                                (NSIndexPath *)indexPath
{
   [tableView deselectRowAtIndexPath:indexPath animated:YES];
   
   Release *release = [_fetchedResultsController
                       objectAtIndexPath:indexPath];
   
   if (!release.uri)
   {
      return;
   }
   
   NSString *URLstr = [@"http://www.discogs.com"
                       stringByAppendingPathComponent:release.uri];
   NSURL *URL = [NSURL URLWithString:URLstr];
   
   [[UIApplication sharedApplication] openURL:URL];
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

- (void)configureCell:(ReleaseCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
   Release *release = [_fetchedResultsController objectAtIndexPath:indexPath];
   
   if (release.title)
   {
      cell.titleLabel.text = release.title;
      cell.artistLabel.text = release.artist;
      
      if ([release.year integerValue])
      {
         cell.yearLabel.text = [release.year description];
      }
      else
      {
         cell.yearLabel.text = nil;
      }
      
      cell.formatLabel.text = release.format;
   }
   else
   {
      // don't have infos yet
      cell.titleLabel.text = release.barcode;
      cell.artistLabel.text = @"No Infos found.";
      cell.yearLabel.text = nil;
      cell.formatLabel.text = nil;
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
         [self configureCell:(ReleaseCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

// lazy initializer for fetched results controller
- (NSFetchedResultsController *)fetchedResultsController
{
   if (!_fetchedResultsController)
   {
      NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
      // Edit the entity name as appropriate.
      NSEntityDescription *entity = [NSEntityDescription entityForName:@"Release" inManagedObjectContext:[self managedObjectContext]];
      [fetch setEntity:entity];
      
      NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"genre" ascending:YES];
      NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
      NSSortDescriptor *sort3 = [NSSortDescriptor sortDescriptorWithKey:@"artist" ascending:YES];
      
      fetch.sortDescriptors = @[sort1, sort2, sort3];
      
      _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch
                                                                      managedObjectContext:[self managedObjectContext]
                                                                        sectionNameKeyPath:@"genre"
                                                                                 cacheName:@"genre_title_artist"];
      _fetchedResultsController.delegate = self;
      
    	NSError *error = nil;
      if (![_fetchedResultsController performFetch:&error]) {
         NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
         abort();
      }
   }
   
   return _fetchedResultsController;
}

// lazy initializer for MOC
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
   if ([segue.identifier isEqualToString:@"showScanner"]) {
      UINavigationController *nav =  (UINavigationController *)segue.destinationViewController;
      DTCameraPreviewController *preview = (DTCameraPreviewController *)nav.viewControllers[0];
      preview.delegate = self;
   }
}


- (IBAction)unwindFromScannerViewController:(UIStoryboardSegue *)unwindSegue {
   // intentionally left black
}

- (void)previewController:(DTCameraPreviewController *)previewController
              didScanCode:(NSString *)code ofType:(NSString *)type
{
   Release *release = [NSEntityDescription
                       insertNewObjectForEntityForName:@"Release"
                       inManagedObjectContext:_managedObjectContext];
   
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
   
   // retrieve more info via Discogs
   DTDiscogs *discogs = [[DTDiscogs alloc] init];
   [discogs searchForGTIN:code completion:^(id result, NSError *error) {
      
      if (error) {
         return;
      }
      
      if (![result isKindOfClass:[NSDictionary class]]) {
         return;
      }
      
      NSDictionary *dict = (NSDictionary *)result;
      NSArray *results = dict[@"results"];
      
      if ([results count]<1) {
         return;
      }
      
      // always use first result
      NSDictionary *theResult = results[0];
      
      [self _performDatabaseUpdatesAndSave:^(NSManagedObjectContext *context) {
         // get version of the Release for this context
         Release *updatedRelease = (Release *)[context objectWithID:release.objectID];
         
         NSString *title = theResult[@"title"];
         NSString *artist = nil;
         NSRange rangeOfDash = [title rangeOfString:@"-"];
         
         if (rangeOfDash.location != NSNotFound) {
            artist = [[title substringToIndex:rangeOfDash.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            title = [[title substringFromIndex:rangeOfDash.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
         }
         
         // update values
         updatedRelease.title = title;
         updatedRelease.artist = artist;
         updatedRelease.genre = [theResult[@"genre"] firstObject];
         updatedRelease.style = [theResult[@"style"] firstObject];
         updatedRelease.format = [theResult[@"format"] firstObject];
         updatedRelease.year = @([theResult[@"year"] integerValue]);
         updatedRelease.uri = theResult[@"uri"];
      }];
   }];
}

// convenience that creates a tmp context and saves it asynchronously
- (void)_performDatabaseUpdatesAndSave:
                        (void (^)(NSManagedObjectContext *context))block
{
   NSParameterAssert(block);
   
   // create temporary context
   NSManagedObjectContext *tmpContext = [[NSManagedObjectContext alloc]
                 initWithConcurrencyType:NSPrivateQueueConcurrencyType];
   tmpContext.parentContext = _managedObjectContext;
   
   // private context needs updates on its own queue
   [tmpContext performBlock:^{
      block(tmpContext);
      
      // save, pushes changes up to main MOC
      if ([tmpContext hasChanges])
      {
         NSError *error;
         if ([tmpContext save:&error])
         {
            // main MOC saving needs to be on main queue
            dispatch_async(dispatch_get_main_queue(), ^{
               
               NSError *error;
               if (![_managedObjectContext save:&error])
               {
                  NSLog(@"Error saving main context: %@",
                        [error localizedDescription]);
               };
            });
         }
         else
         {
            NSLog(@"Error saving tmp context: %@",
                  [error localizedDescription]);
         }
      }
   }];
}


@end
