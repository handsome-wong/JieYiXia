//
//  UserDetailsViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 11/5/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "UserDetailsViewController.h"
#import "OSCUser.h"
#import "Utils.h"
#import "Config.h"
#import "BlogsViewController.h"
#import "SwipableViewController.h"
#import "FriendsViewController.h"
#import "OSCEvent.h"
#import "EventCell.h"
#import "UserHeaderCell.h"
#import "UserOperationCell.h"
#import "BlogsViewController.h"
#import "BubbleChatViewController.h"
#import "LoginViewController.h"

#import <MBProgressHUD.h>

@interface UserDetailsViewController ()

@property (nonatomic, strong) OSCUser *user;

@property (nonatomic, strong) UIImageView *portrait;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIButton *followButton;

@end

@implementation UserDetailsViewController


#pragma mark - init method

- (instancetype)initWithUserID:(int64_t)userID
{
    self = [super initWithUserID:userID];
    self.hidesBottomBarWhenPushed = YES;
    if (!self) {return self;}
    
    __weak UserDetailsViewController *weakSelf = self;
    self.parseExtraInfo = ^(ONOXMLDocument *XML) {
        ONOXMLElement *userXML = [XML.rootElement firstChildWithTag:@"user"];
        weakSelf.user = [[OSCUser alloc] initWithXML:userXML];
    };
    
    return self;
}

- (instancetype)initWithUserName:(NSString *)userName
{
    self = [super initWithUserName:userName];
    self.hidesBottomBarWhenPushed = YES;
    if (!self) {return self;}
    
    __weak UserDetailsViewController *weakSelf = self;
    self.parseExtraInfo = ^(ONOXMLDocument *XML) {
        ONOXMLElement *userXML = [XML.rootElement firstChildWithTag:@"user"];
        weakSelf.user = [[OSCUser alloc] initWithXML:userXML];
    };
    
    return self;
}



#pragma mark - life cycle

- (void)viewDidLoad {
    self.needRefreshAnimation = NO;
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.title = @"用户中心";
    self.tableView.bounces = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}




#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    self.tableView.separatorColor = [UIColor separatorColor];
    
    return section == 0? 2 : self.objects.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 158;
        } else {
            return 105;
        }
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UserHeaderCell *cell = [UserHeaderCell new];
            
            [cell setContentWithUser:_user];
            
            cell.followsButton.tag = 0;
            cell.fansButton.tag = 1;
            
            [cell.followsButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
            [cell.fansButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
            
            return cell;
        } else {
            UserOperationCell *cell = [UserOperationCell new];
            if (_user) {
                cell.loginTimeLabel.text = [NSString stringWithFormat:@"上次登录：%@", [_user.latestOnlineTime timeAgoSinceNow]];
                [cell setFollowButtonByRelationship:_user.relationship];
                [cell.followButton addTarget:self action:@selector(updateRelationship) forControlEvents:UIControlEventTouchUpInside];
                [cell.blogsButton addTarget:self action:@selector(pushBlogsVC) forControlEvents:UIControlEventTouchUpInside];
                [cell.messageButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
                [cell.informationButton addTarget:self action:@selector(showUserInformation) forControlEvents:UIControlEventTouchUpInside];
            }
            
            return cell;
        }
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {return;}
    else {[super tableView:tableView didSelectRowAtIndexPath:indexPath];}
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}




#pragma mark - 处理页面跳转

- (void)pushFriendsSVC:(UIButton *)button
{
    SwipableViewController *friendsSVC = [[SwipableViewController alloc] initWithTitle:@"关注/粉丝"
                                                                          andSubTitles:@[@"关注", @"粉丝"]
                                                                        andControllers:@[
                                                                                         [[FriendsViewController alloc] initWithUserID:_user.userID andFriendsRelation:1],
                                                                                         [[FriendsViewController alloc] initWithUserID:_user.userID andFriendsRelation:0]
                                                                                         ]];
    
    if (button.tag == 1) {
        [friendsSVC scrollToViewAtIndex:1];
    }
    
    [self.navigationController pushViewController:friendsSVC animated:YES];
}


- (void)updateRelationship
{
    if ([Config getOwnID] == 0) {
        [self.navigationController pushViewController:[LoginViewController new] animated:YES];
    } else {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
        
        [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_USER_UPDATERELATION]
           parameters:@{
                        @"uid":             @([Config getOwnID]),
                        @"hisuid":          @(_user.userID),
                        @"newrelation":     _user.relationship <= 2? @(0) : @(1)
                        }
              success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDoment) {
                  ONOXMLElement *result = [responseDoment.rootElement firstChildWithTag:@"result"];
                  int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
                  NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
                  
                  if (errorCode == 1) {
                      _user.relationship = [[[responseDoment.rootElement firstChildWithTag:@"relation"] numberValue] intValue];
                      dispatch_async(dispatch_get_main_queue(), ^{
                          [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
                                                withRowAnimation:UITableViewRowAnimationNone];
                      });
                  } else {
                      MBProgressHUD *HUD = [Utils createHUD];
                      HUD.mode = MBProgressHUDModeCustomView;
                      HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                      HUD.labelText = errorMessage;
                      
                      [HUD hide:YES afterDelay:1];
                  }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                MBProgressHUD *HUD = [Utils createHUD];
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                HUD.labelText = @"网络异常，操作失败";
                
                [HUD hide:YES afterDelay:1];
            }];
    }
}

- (void)pushBlogsVC
{
    [self.navigationController pushViewController:[[BlogsViewController alloc] initWithUserID:_user.userID]
                                         animated:YES];
}

- (void)sendMessage
{
    if ([Config getOwnID] == 0) {
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeText;
        HUD.labelText = @"请先登录";
        [HUD hide:YES afterDelay:0.5];
    } else {
        [self.navigationController pushViewController:[[BubbleChatViewController alloc] initWithUserID:_user.userID andUserName:_user.name]
                                             animated:YES];
    }
}

- (void)showUserInformation
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.color = [UIColor colorWithHex:0xEEEEEE];
    
    UILabel *detailsLabel = [HUD valueForKey:@"detailsLabel"];
    detailsLabel.textAlignment = NSTextAlignmentLeft;
    detailsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName:[UIColor grayColor]};
    
    NSArray *title = @[@"加入时间：", @"所在地区：", @"开发平台：", @"专长领域："];
    NSString *joinTime = [_user.joinTime timeAgoSinceNow];
    NSArray *content = @[joinTime, _user.location, _user.developPlatform, _user.expertise];
    
    NSMutableAttributedString *userInformation = [NSMutableAttributedString new];
    for (int i = 0; i < 4; ++i) {
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title[i]
                                                                                           attributes:titleAttributes];
        if (i  < 3) {
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", content[i]]]];
        } else {
            [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", content[i]]]];
        }
        
        [userInformation appendAttributedString:attributedText];
    }
    
    HUD.detailsLabelColor = [UIColor blackColor];
    HUD.detailsLabelFont = [UIFont systemFontOfSize:14];
    detailsLabel.attributedText = userInformation;
    
    [HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideHUD:)]];
}

- (void)hideHUD:(UITapGestureRecognizer *)recognizer
{
    [(MBProgressHUD *)recognizer.view hide:YES];
}




@end
