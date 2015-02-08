//
//  FactCell.m
//  Factera
//
//  Created by Nick Dawson on 07/02/2015.
//  Copyright (c) 2015 Nick Dawson. All rights reserved.
//

#import "FactCell.h"

@interface FactCell()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation FactCell

- (instancetype)init {
    if(self = [super init]) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Gradient background
    _gradientLayer = [[CAGradientLayer layer] retain];
    _gradientLayer.colors = @[(id)[UIColor whiteColor].CGColor, (id)[UIColor colorWithWhite:0.92 alpha:1.0].CGColor];
    _gradientLayer.frame = self.contentView.bounds;
    
    self.backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
    [self.backgroundView.layer addSublayer:_gradientLayer];
    
    // Labels
    _titleLabel = [[[UILabel alloc] init] retain];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = FALSE;
    _titleLabel.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:18.0];
    _titleLabel.textColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.45 alpha:1.0];
    _titleLabel.numberOfLines = 1;
    
    [self.contentView addSubview:_titleLabel];
    
    _detailLabel = [[[UILabel alloc] init] retain];
    _detailLabel.translatesAutoresizingMaskIntoConstraints = FALSE;
    _detailLabel.textColor = [UIColor blackColor];
    _detailLabel.font = [UIFont systemFontOfSize:10.0];
    _detailLabel.numberOfLines = 3;
    
    [self.contentView addSubview:_detailLabel];
    
    _thumbnailImageView = [[[UIImageView alloc] init] retain];
    _thumbnailImageView.translatesAutoresizingMaskIntoConstraints = FALSE;
    _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    _thumbnailImageView.clipsToBounds = TRUE;
    
    [self.contentView addSubview:_thumbnailImageView];
    
    NSDictionary *views = @{@"detailLabel": _detailLabel,
                            @"titleLabel": _titleLabel,
                            @"imageView": _thumbnailImageView};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[titleLabel]-5-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[detailLabel]-10-[imageView(80)]-5-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[titleLabel(20)]-3-[detailLabel(40)]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleLabel]-0-[imageView(50)]" options:0 metrics:nil views:views]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.gradientLayer setFrame:self.backgroundView.bounds];
}

- (void)dealloc {
    [_detailLabel release];
    [_titleLabel release];
    [_thumbnailImageView release];
    [_gradientLayer release];
    
    [super dealloc];
}

@end
