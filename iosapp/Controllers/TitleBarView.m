//
//  TitleBarView.m
//  iosapp
//
//  Created by chenhaoxiang on 14-10-20.
//  Copyright (c) 2014年 oschina. All rights reserved.
//

#import "TitleBarView.h"
#import "UIColor+Util.h"

@interface TitleBarView ()

@end

@implementation TitleBarView
- (instancetype)initWithFrame:(CGRect)frame andTitles:(NSArray *)titles
{
    return [self initWithFrame:frame andTitles:titles currenIndex:0];
}
- (instancetype)initWithFrame:(CGRect)frame andTitles:(NSArray *)titles currenIndex:(NSInteger)currenIndex
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _currentIndex = currenIndex;
        //_currentIndex = 0;
        _titleButtons = [NSMutableArray new];
        _underlineButtons = [NSMutableArray new];
        
        CGFloat buttonWidth = frame.size.width / titles.count;
        CGFloat buttonHeight = frame.size.height;
        
        [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.backgroundColor = [UIColor titleBarColor];
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            [button setTitleColor:[UIColor colorWithHex:0x909090] forState:UIControlStateNormal];
            [button setTitle:title forState:UIControlStateNormal];
            
            button.frame = CGRectMake(buttonWidth * idx, 0, buttonWidth, buttonHeight-3);
            button.tag = idx;
            [button addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
            
            [_titleButtons addObject:button];
            [self addSubview:button];
            [self sendSubviewToBack:button];
            
            UIButton *ulbutton = [UIButton buttonWithType:UIButtonTypeCustom];
            ulbutton.backgroundColor = [UIColor titleBarColor];
            ulbutton.frame = CGRectMake(buttonWidth * idx, buttonHeight-3, buttonWidth, 2);
            ulbutton.tag = idx;
            [_underlineButtons addObject:ulbutton];
            [self addSubview:ulbutton];
            [self sendSubviewToBack:ulbutton];
        }];
        
        self.contentSize = CGSizeMake(frame.size.width, 25);
        self.showsHorizontalScrollIndicator = NO;
        UIButton *firstTitle = _titleButtons[_currentIndex];
        [firstTitle setTitleColor:[UIColor colorWithHex:0x8bcf32] forState:UIControlStateNormal];
        UIButton *firstulButton = _underlineButtons[_currentIndex];
        [firstulButton setBackgroundColor:[UIColor colorWithHex:0x8bcf32]];
        //firstTitle.transform = CGAffineTransformMakeScale(1.15, 1.15);
    }
    
    return self;
}


- (void)onClick:(UIButton *)button
{
    if (_currentIndex != button.tag) {
        UIButton *preTitle = _titleButtons[_currentIndex];
        
        [preTitle setTitleColor:[UIColor colorWithHex:0x909090] forState:UIControlStateNormal];
        //preTitle.transform = CGAffineTransformIdentity;
        
        [button setTitleColor:[UIColor colorWithHex:0x8bcf32] forState:UIControlStateNormal];
        //button.transform = CGAffineTransformMakeScale(1.2, 1.2);
        
        UIButton *preButton = _underlineButtons[_currentIndex];
        
        [preButton setBackgroundColor:[UIColor titleBarColor]];
        //preTitle.transform = CGAffineTransformIdentity;
        
        
        _currentIndex = button.tag;
        _titleButtonClicked(button.tag);
        
        UIButton *curButton = _underlineButtons[_currentIndex];
        
        [curButton setBackgroundColor:[UIColor colorWithHex:0x8bcf32]];

        
    }
    
}

- (void)setTitleButtonsColor
{
    for (UIButton *button in self.subviews) {
        button.backgroundColor = [UIColor titleBarColor];
    }
}

@end
