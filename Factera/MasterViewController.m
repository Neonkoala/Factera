//
//  MasterViewController.m
//  Factera
//
//  Created by Nick Dawson on 07/02/2015.
//  Copyright (c) 2015 Nick Dawson. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

#import "NetworkManager.h"

#import "Fact.h"
#import "Title.h"

#import "FactCell.h"

@interface MasterViewController ()

@property (nonatomic, strong) NSOperationQueue *imageQueue;

@end

@implementation MasterViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if(self = [super initWithStyle:style]) {
        _imageCache = [[NSCache alloc] init];
        _imageCache.countLimit = 100;
        _imageQueue = [NSOperationQueue mainQueue];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.preferredContentSize = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Start loading the feed
    [[NetworkManager sharedManager] updateFacts];
    
    // Setup the table view
    self.tableView.rowHeight = 80;
    self.tableView.separatorColor = [UIColor clearColor];
    [self.tableView registerClass:[FactCell class] forCellReuseIdentifier:@"Cell"];

    // Pull to refresh
    self.refreshControl = [[[UIRefreshControl alloc] init] autorelease];
    [self.refreshControl addTarget:self action:@selector(refreshTriggered:) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl beginRefreshing];
    
    [self updateTitle];
    
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // Listen for network operations
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(factsDidUpdate:) name:NetworkFactsUpdateComplete object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(factsDidFailToUpdate:) name:NetworkFactsUpdateFailed object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NetworkFactsUpdateComplete object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NetworkFactsUpdateFailed object:nil];
    
    [_imageCache release];
    [_imageQueue release];
    [_detailViewController release];
    [_fetchedResultsController release];
    [_managedObjectContext release];
    
    [super dealloc];
}

#pragma mark - Interface

- (void)updateTitle {
    // Fetch the title from Core Data
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Title"];
    NSArray *titles = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error) {
        NSLog(@"Error fetching titles: %@", error.localizedDescription);
    }
    if(titles.count) {
        Title *title = titles.firstObject;
        self.navigationItem.title = title.title;
    } else {
        self.navigationItem.title = @"Factera";
    }
}

#pragma mark - User Interaction

- (void)refreshTriggered:(id)sender {
    [[NetworkManager sharedManager] updateFacts];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (void)loadImage:(UIImage *)image forCellAtIndexPath:(NSIndexPath *)indexPath {
    __block FactCell *cell = (FactCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if(cell) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FactCell *cell = (FactCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if(cell) {
                cell.thumbnailImageView.image = image;
            }
        });
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(FactCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Fact *fact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.titleLabel.text = fact.title;
    cell.detailLabel.text = fact.details;
    cell.thumbnailImageView.image = nil;
    
    // Check if we have a cached image in memory or load it asynchronously
    if(fact.imageUrl) {
        UIImage *image = [self.imageCache objectForKey:fact.imageUrl];
        if(image) {
            cell.thumbnailImageView.image = image;
        } else {
            NSURL *imageURL = [NSURL URLWithString:fact.imageUrl];
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageURL];
            [NSURLConnection sendAsynchronousRequest:imageRequest queue:self.imageQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if(connectionError) {
                    // Fail silently
                    NSLog(@"Error fetching image at %@ : %@", imageURL.absoluteString, connectionError.localizedDescription);
                } else {
                    // Add the image data to the cache
                    UIImage *image = [UIImage imageWithData:data];
                    if(image) {
                        [self.imageCache setObject:image forKey:fact.imageUrl];
                    
                        [self loadImage:image forCellAtIndexPath:indexPath];
                    }
                }
            }];
        }
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Fact" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:NO] autorelease];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

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
            
        default:
            return;
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
            [self configureCell:(FactCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

#pragma mark - Notifications

- (void)factsDidUpdate:(NSNotification *)notification {
    // Make sure we update UI on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        
        [self updateTitle];
    });
}

- (void)factsDidFailToUpdate:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
        
        NSError *error = notification.userInfo[NetworkErrorKey];
        if(error) {
            [[[UIAlertView alloc] initWithTitle:@"Error updating facts" message:error.localizedDescription delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
            
        }
    });
}

@end
