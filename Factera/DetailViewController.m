//
//  DetailViewController.m
//  Factera
//
//  Created by Nick Dawson on 07/02/2015.
//  Copyright (c) 2015 Nick Dawson. All rights reserved.
//

#import "DetailViewController.h"

#import "AppDelegate.h"

#import "Fact.h"

@interface DetailViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *detailDescriptionLabel;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setFact:(Fact *)fact {
    if (_fact != fact) {
        [_fact release];
        _fact = [fact retain];
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.fact) {
        self.navigationItem.title = self.fact.title;
        self.detailDescriptionLabel.text = self.fact.details;
        
        UIImage *image = [self.imageCache objectForKey:self.fact.imageUrl];
        if(image) {
            self.imageView.image = image;
        } else {
            self.imageView.image = nil;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.detailDescriptionLabel = [[[UILabel alloc] init] autorelease];
    self.detailDescriptionLabel.translatesAutoresizingMaskIntoConstraints = FALSE;
    self.detailDescriptionLabel.textColor = [UIColor blackColor];
    self.detailDescriptionLabel.font = [UIFont systemFontOfSize:13.0];
    self.detailDescriptionLabel.numberOfLines = 0;
    
    self.imageView = [[[UIImageView alloc] init] autorelease];
    self.imageView.translatesAutoresizingMaskIntoConstraints = FALSE;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = TRUE;
    
    [self.view addSubview:self.detailDescriptionLabel];
    [self.view addSubview:self.imageView];
    
    
    NSDictionary *views = nil;
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        views = @{@"detailDescriptionLabel": self.detailDescriptionLabel,
                  @"imageView": self.imageView,
                  @"topLayoutGuide": self.topLayoutGuide};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide]-10-[imageView(180)]-10-[detailDescriptionLabel]" options:0 metrics:nil views:views]];
    } else {
        views = @{@"detailDescriptionLabel": self.detailDescriptionLabel,
                  @"imageView": self.imageView};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[imageView(180)]-10-[detailDescriptionLabel]" options:0 metrics:nil views:views]];
    }
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageView]-10-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[detailDescriptionLabel]-10-|" options:0 metrics:nil views:views]];
    
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_imageView release];
    [_detailDescriptionLabel release];
    [_fact release];
    
    [super dealloc];
}

@end
