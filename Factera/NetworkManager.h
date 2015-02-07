//
//  NetworkManager.h
//  Factera
//
//  Created by Nick Dawson on 07/02/2015.
//  Copyright (c) 2015 Nick Dawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString *const NetworkErrorKey;
extern NSString *const NetworkFactsUpdateComplete;
extern NSString *const NetworkFactsUpdateFailed;

@interface NetworkManager : NSObject <NSURLConnectionDelegate>

@property (nonatomic, strong) NSManagedObjectContext *moc;

+ (instancetype)sharedManager;

- (void)updateFacts;

@end
