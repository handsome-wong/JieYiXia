//
//  TweetDetailsWithBottomBarViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 1/14/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "TweetDetailsWithBottomBarViewController.h"
#import "TweetDetailsViewController.h"
#import "CommentsViewController.h"
#import "UserDetailsViewController.h"
#import "ImageViewerController.h"
#import "OSCTweet.h"
#import "OSCComment.h"
#import "TweetDetailsCell.h"
#import "Config.h"
#import "Utils.h"

#import <objc/runtime.h>
#import <MBProgressHUD.h>


@interface TweetDetailsWithBottomBarViewController () <UIWebViewDelegate>

@property (nonatomic, strong) TweetDetailsViewController *tweetDetailsVC;
@property (nonatomic, assign) int64_t tweetID;
@property (nonatomic, assign) BOOL isReply;

@end

@implementation TweetDetailsWithBottomBarViewController

- (instancetype)initWithTweetID:(int64_t)tweetID
{
    self = [super initWithModeSwitchButton:NO];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        
        _tweetID = tweetID;
        
        _tweetDetailsVC = [[TweetDetailsViewController alloc] initWithTweetID:tweetID];
        [self addChildViewController:_tweetDetailsVC];
        
        [self setUpBlock];
    }
    
    return self;
}

- (void)setUpBlock
{
    __weak TweetDetailsWithBottomBarViewController *weakSelf = self;
    
    _tweetDetailsVC.didCommentSelected = ^(OSCComment *comment) {
        NSString *authorString = [NSString stringWithFormat:@"@%@ ", comment.author];
        
        if ([weakSelf.editingBar.editView.text rangeOfString:authorString].location == NSNotFound) {
            [weakSelf.editingBar.editView replaceRange:weakSelf.editingBar.editView.selectedTextRange withText:authorString];
            [weakSelf.editingBar.editView becomeFirstResponder];
        }
    };
    
    _tweetDetailsVC.didScroll = ^ {
        [weakSelf.editingBar.editView resignFirstResponder];
        [weakSelf hideEmojiPageView];
    };
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setLayout
{
    [self.view addSubview:_tweetDetailsVC.view];
    
    for (UIView *view in self.view.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    NSDictionary *views = @{@"tableView": _tweetDetailsVC.view, @"editingBar": self.editingBar};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][editingBar]"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil views:views]];
}


- (void)sendContent
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.labelText = @"评论发送中";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_COMMENT_PUB]
       parameters:@{
                    @"catalog": @(3),
                    @"id": @(_tweetID),
                    @"uid": @([Config getOwnID]),
                    @"content": [Utils convertRichTextToRawText:self.editingBar.editView],
                    @"isPostToMyZone": @(0)
                    }
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
              NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
              
              HUD.mode = MBProgressHUDModeCustomView;
              
              if (errorCode == 1) {
                  self.editingBar.editView.text = @"";
                  [self updateInputBarHeight];
                  
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                  HUD.labelText = @"评论发表成功";
                  
                  [_tweetDetailsVC.tableView setContentOffset:CGPointZero animated:NO];
                  [_tweetDetailsVC refresh];
              } else {
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
              }
              
              [HUD hide:YES afterDelay:1];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              HUD.mode = MBProgressHUDModeCustomView;
              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              HUD.labelText = @"网络异常，动弹发送失败";
              
              [HUD hide:YES afterDelay:1];
          }];
}








@end
