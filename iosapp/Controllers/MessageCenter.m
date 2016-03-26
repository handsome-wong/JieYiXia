//
//  MessageCenter.m
//  iosapp
//
//  Created by chenhaoxiang on 3/1/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "MessageCenter.h"
#import "Config.h"
#import "OSCObjsViewController.h"
#import "EventsViewController.h"
#import "FriendsViewController.h"
#import "MessagesViewController.h"
#import "MyTweetLikeListViewController.h"

#import "UIButton+Badge.h"
#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>


@interface MessageCenter ()

@property (nonatomic, strong) NSArray *noticesCount;

@property (nonatomic, strong) NSMutableArray *viewAppeared;
@property (nonatomic, strong) NSMutableArray *viewRefreshed;

@end

@implementation MessageCenter

- (instancetype)initWithNoticeCounts:(NSArray *)noticeCounts
{
    self = [super initWithTitle:@"消息中心"
                   andSubTitles:@[@"@我", @"评论", @"私信", @"粉丝", @"赞过我"]
                 andControllers:@[
                                  [[EventsViewController alloc] initWithCatalog:2],
                                  [[EventsViewController alloc] initWithCatalog:3],
                                  [MessagesViewController new],
                                  [[FriendsViewController alloc] initWithUserID:[Config getOwnID] andFriendsRelation:0],
                                  [MyTweetLikeListViewController new]
                                  ]];
    
    if (self) {
        _viewAppeared  = [NSMutableArray arrayWithArray:@[@(NO), @(NO), @(NO), @(NO), @(NO)]];
        _viewRefreshed = [NSMutableArray arrayWithArray:@[@(NO), @(NO), @(NO), @(NO), @(NO)]];
        
        __weak MessageCenter *weakSelf = self;
        [self.viewPager.controllers enumerateObjectsUsingBlock:^(OSCObjsViewController *vc, NSUInteger idx, BOOL *stop) {
            vc.didRefreshSucceed = ^ {
                UIButton *titleButton = weakSelf.titleBar.titleButtons[idx];
                if ([titleButton.badgeValue isEqualToString:@"0"]) {return;}
                
                weakSelf.viewRefreshed[idx] = @(YES);
                if ([weakSelf.viewAppeared[idx] boolValue] && [weakSelf.viewRefreshed[idx] boolValue]) {
                    [weakSelf markAsReaded:idx];
                }
            };
        }];
        
        self.viewPager.viewDidAppear = ^ (NSInteger index) {
            UIButton *titleButton = weakSelf.titleBar.titleButtons[index];
            if ([titleButton.badgeValue isEqualToString:@"0"]) {return;}
            
            weakSelf.viewAppeared[index] = @(YES);
            if ([weakSelf.viewAppeared[index] boolValue] && [weakSelf.viewRefreshed[index] boolValue]) {
                [weakSelf markAsReaded:index];
            }
        };
        
        [self dealWithNotices:noticeCounts autoScroll:YES];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeUpdateHandler:) name:OSCAPI_USER_NOTICE object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - 处理消息通知

#pragma mark 处理badge

- (void)setBadgeValue:(NSString *)badgeValue forButton:(UIButton *)button
{
#if 1
    if ([badgeValue isEqualToString:@"0"]) {
        [button setTitle:[NSString stringWithFormat:@"%@", [button.titleLabel.text substringToIndex:2]] forState:UIControlStateNormal];
        return;
    }
    [button setTitle:[NSString stringWithFormat:@"%@(%@)", [button.titleLabel.text substringToIndex:2], badgeValue] forState:UIControlStateNormal];
#else
    if ([badgeValue isEqualToString:@"0"]) {
        button.badge.hidden = YES;
        return;
    }
    
    CGSize size = [button.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    button.badgeValue = badgeValue;
    button.badgeOriginX = (button.frame.size.width + size.width) / 2;
    button.badgeOriginY = (button.frame.size.height - button.badge.frame.size.height) / 2;
    button.badgeBGColor = [UIColor redColor];
    button.badgeTextColor = [UIColor whiteColor];
#endif
}


#pragma mark 处理提示

- (void)dealWithNotices:(NSArray *)noticeCounts autoScroll:(BOOL)needAutoScroll
{
    __block BOOL scrolled = NO;
    __block int sumOfCount = 0;
    
//    [self.titleBar.titleButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
//        [self setBadgeValue:[noticeCounts[idx] stringValue] forButton:button];
//        sumOfCount += [noticeCounts[idx] intValue];
//        
//        if (needAutoScroll && [noticeCounts[idx] intValue] && !scrolled) {
//            [self scrollToViewAtIndex:idx];
//            scrolled = YES;
//        }
//    }];
    [noticeCounts enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        [self setBadgeValue:[number stringValue] forButton:self.titleBar.titleButtons[idx]];
        sumOfCount += [number intValue];
        
        if (needAutoScroll && [number intValue] && !scrolled) {
            [self scrollToViewAtIndex:idx];
            scrolled = YES;
        }
    }];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:sumOfCount];
}


#pragma mark 处理系统通知

- (void)noticeUpdateHandler:(NSNotification *)notification
{
    NSArray *noticeCounts = [notification object];
    
    [self dealWithNotices:noticeCounts autoScroll:NO];
}


- (void)markAsReaded:(NSInteger)idx
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_NOTICE_CLEAR]
       parameters:@{@"uid":@([Config getOwnID]),
                    @"type":@[@(1), @(3), @(2), @(4), @(5)][idx]}
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
              
              if (errorCode == 1) {
                  UIButton *button = self.titleBar.titleButtons[idx];
                  button.badge.hidden = YES;
                  
                  _viewAppeared[idx] = @(NO);
                  _viewRefreshed[idx] = @(NO);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
          }];
}




@end
