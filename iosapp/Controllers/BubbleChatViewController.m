//
//  BubbleChatViewController.m
//  iosapp
//
//  Created by ChanAetern on 2/15/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "BubbleChatViewController.h"
#import "MessageBubbleViewController.h"
#import "Config.h"
#import "Utils.h"

#import <MBProgressHUD.h>

@interface BubbleChatViewController ()

@property (nonatomic, assign) int64_t userID;
@property (nonatomic, strong) MessageBubbleViewController *messageBubbleVC;

@end

@implementation BubbleChatViewController

- (instancetype)initWithUserID:(int64_t)userID andUserName:(NSString *)userName
{
    self = [super initWithModeSwitchButton:NO];
    if (self) {
        self.navigationItem.title = userName;
        
        _userID = userID;
        _messageBubbleVC = [[MessageBubbleViewController alloc] initWithUserID:userID andUserName:userName];
        [self addChildViewController:_messageBubbleVC];
        
        [self setUpBlock];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setUpBlock
{
    __weak BubbleChatViewController *weakSelf = self;
    
    _messageBubbleVC.didScroll = ^ {
        [weakSelf.editingBar.editView resignFirstResponder];
        [weakSelf hideEmojiPageView];
    };
}


- (void)setLayout
{
    [self.view addSubview:_messageBubbleVC.view];
    
    for (UIView *view in self.view.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    NSDictionary *views = @{@"messageBubbleTableView": _messageBubbleVC.view, @"editingBar": self.editingBar};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[messageBubbleTableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[messageBubbleTableView][editingBar]"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil views:views]];
}


- (void)sendContent
{
    [self.editingBar.editView resignFirstResponder];
    
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.labelText = @"私信发送中";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_MESSAGE_PUB]
       parameters:@{
                    @"uid":      @([Config getOwnID]),
                    @"receiver": @(_userID),
                    @"content":  [Utils convertRichTextToRawText:self.editingBar.editView]
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
                  HUD.labelText = @"发送私信成功";
              } else {
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
              }
              
              [HUD hide:YES afterDelay:1];
              
              [_messageBubbleVC.tableView setContentOffset:CGPointZero animated:NO];
              [_messageBubbleVC refresh];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              HUD.mode = MBProgressHUDModeCustomView;
              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              HUD.labelText = @"网络异常，私信发送失败";
              
              [HUD hide:YES afterDelay:1];
          }];
}




@end
