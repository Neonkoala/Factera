//
//  DetailViewController.h
//  Factera
//
//  Created by Nick Dawson on 07/02/2015.
//  Copyright (c) 2015 Nick Dawson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Fact;

@interface DetailViewController : UIViewController

@property (nonatomic, assign) Fact *fact;
@property (nonatomic, assign) NSCache *imageCache;

@end

