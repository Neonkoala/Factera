//
//  NetworkManager.m
//  Factera
//
//  Created by Nick Dawson on 07/02/2015.
//  Copyright (c) 2015 Nick Dawson. All rights reserved.
//

#import "NetworkManager.h"

#import "Fact.h"
#import "Title.h"

NSString *const FactsDetailKey = @"description";
NSString *const FactsImageKey = @"imageHref";
NSString *const FactsRowKey = @"rows";
NSString *const FactsTitleKey = @"title";
NSString *const FactsURLString = @"https://dl.dropboxusercontent.com/u/746330/facts.json";

NSString *const NetworkErrorKey = @"NetworkErrorKey";
NSString *const NetworkFactsUpdateComplete = @"NetworkFactsUpdateComplete";
NSString *const NetworkFactsUpdateFailed = @"NetworkFactsUpdateFailed";

@interface NetworkManager()

@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation NetworkManager

+ (instancetype)sharedManager {
    static NetworkManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [self new];
    });
    return sharedMyManager;
}

- (instancetype)init {
    if(self = [super init]) {
        _queue = [NSOperationQueue mainQueue];
    }
    return self;
}

- (void)updateFacts {
    NSURL *factsURL = [NSURL URLWithString:FactsURLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:factsURL];
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError) {
            NSLog(@"Error loading facts: %@", connectionError.localizedDescription);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NetworkFactsUpdateFailed object:self userInfo:@{NetworkErrorKey: connectionError}];
        } else {
            if(data.length) {
                [self parseFacts:data];
            }
        }
    }];
}

- (void)parseFacts:(NSData *)rawData {
    NSError *error;
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:&error];
    if(error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NetworkFactsUpdateFailed object:self userInfo:@{NetworkErrorKey: error}];
    } else {
        // Save the title
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Title"];
        NSArray *titles = [self.moc executeFetchRequest:fetchRequest error:&error];
        if(error) {
            NSLog(@"Error fetching title: %@", error.localizedDescription);
            return;
        }
        Title *title = nil;
        if(titles.count) {
            title = titles.firstObject;
        } else {
            title = [NSEntityDescription insertNewObjectForEntityForName:@"Title" inManagedObjectContext:self.moc];
        }
        title.title = jsonResponse[FactsTitleKey];
        
        // Update facts
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        NSArray *rows = [jsonResponse[rows] sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSMutableArray *keys = [NSMutableArray arrayWithCapacity:rows.count];
        for(NSDictionary *row in rows) {
            // Check for a title as we use this as the identifier
            if(!row[FactsTitleKey]) {
                continue;
            }
            [keys addObject:row[FactsTitleKey]];
        }
        
        // Fetch all existing Fact objects
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Fact"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"title IN %@", keys];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        NSArray *existingRows = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"Error fetching existing facts: %@", error.localizedDescription);
            return;
        }
        
        // Update or create facts
        NSUInteger existingCount = 0;
        for (NSDictionary *row in rows) {
            NSString *rowTitle = row[FactsTitleKey];
            if(!rowTitle) {
                continue;
            }
            
            Fact *fact = nil;
            if(existingCount < existingRows.count) {
                fact = [existingRows objectAtIndex:existingCount];
            }
            
            if(!fact || ![fact.title isEqualToString:rowTitle]) {
                fact = [NSEntityDescription insertNewObjectForEntityForName:@"Fact" inManagedObjectContext:self.moc];
                fact.title = rowTitle;
            } else {
                existingCount++;
            }
            
            fact.details = row[FactsDetailKey];
            fact.imageUrl = row[FactsImageKey];
        }
        
        // Find and delete old facts
        fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Fact"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"title IN %@", keys];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        NSArray *obsoleteFacts = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"Error fetching old facts: %@", error.localizedDescription);
            return;
        }
        
        for (Fact *fact in obsoleteFacts) {
            [self.moc deleteObject:fact];
        }
        
        // Save to Core Data and notify
        __block NSError *saveError;
        [self.moc performBlockAndWait:^{
            [self.moc save:&saveError];
        }];
        
        if(error) {
            NSLog(@"Error saving updated facts: %@", error.localizedDescription);
            [[NSNotificationCenter defaultCenter] postNotificationName:NetworkFactsUpdateFailed object:self userInfo:@{NetworkErrorKey: error}];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:NetworkFactsUpdateComplete object:self];
        }
    }
}

@end