//
//  PersonCell.m
//  iosapp
//
//  Created by ChanAetern on 1/7/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "PersonCell.h"
#import "Utils.h"

@implementation PersonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor themeColor];
        
        [self initSubviews];
        [self setLayout];
        
        UIView *selectedBackground = [UIView new];
        selectedBackground.backgroundColor = [UIColor colorWithHex:0xF5FFFA];
        [self setSelectedBackgroundView:selectedBackground];
    }
    
    return self;
}

- (void)initSubviews
{
    _portrait = [UIImageView new];
    _portrait.contentMode = UIViewContentModeScaleAspectFit;
    [_portrait setCornerRadius:5.0];
    [self.contentView addSubview:_portrait];
    
    _nameLabel = [UILabel new];
    _nameLabel.numberOfLines = 0;
    _nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _nameLabel.font = [UIFont systemFontOfSize:16];
    _nameLabel.textColor = [UIColor nameColor];
    [self.contentView addSubview:_nameLabel];
    
    _infoLabel = [UILabel new];
    _infoLabel.numberOfLines = 0;
    _infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _infoLabel.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:_infoLabel];
}

- (void)setLayout
{
    for (UIView *view in self.contentView.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_portrait, _nameLabel, _infoLabel);
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-8-[_portrait(36)]-8-[_nameLabel]-8-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_portrait(36)]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_nameLabel]-2-[_infoLabel]-8-|"
                                                                             options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];
}


@end
