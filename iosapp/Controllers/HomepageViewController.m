//
//  HomepageViewController.m
//  iosapp
//
//  Created by AeternChan on 7/18/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "HomepageViewController.h"
#import "Utils.h"
#import "Config.h"
#import "OSCAPI.h"
#import "OSCUser.h"
#import "BlogsViewController.h"
#import "SwipableViewController.h"
#import "FriendsViewController.h"
#import "FavoritesViewController.h"
#import "MessageCenter.h"
#import "LoginViewController.h"
#import "MyBasicInfoViewController.h"
#import "AppDelegate.h"

#import "UIScrollView+ScalableCover.h"
#import "UIFont+FontAwesome.h"
#import "NSString+FontAwesome.h"

#import <MBProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <MJRefresh.h>

@interface HomepageViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *portrait;
@property (nonatomic, weak) IBOutlet UIButton *QRCodeButton;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UIView *separator;

@property (nonatomic, weak) IBOutlet UIButton *creditButton;
@property (nonatomic, weak) IBOutlet UIButton *collectionButton;
@property (nonatomic, weak) IBOutlet UIButton *followingButton;
@property (nonatomic, weak) IBOutlet UIButton *fanButton;

@property (nonatomic, strong) UIImageView *myQRCodeImageView;

@property (nonatomic, assign) int64_t myID;
@property (nonatomic, strong) OSCUser *myProfile;
@property (nonatomic, strong) NSMutableArray *noticeCounts;
@property (nonatomic, assign) int badgeValue;

@end

@implementation HomepageViewController

- (void)dawnAndNightMode
{
    self.tableView.backgroundColor = [UIColor themeColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.refreshControl.tintColor = [UIColor refreshControlColor];
    
    [self refreshHeaderView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeUpdateHandler:) name:OSCAPI_USER_NOTICE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRefreshHandler:)  name:@"userRefresh"     object:nil];
    
    _noticeCounts = [NSMutableArray arrayWithArray:@[@(0), @(0), @(0), @(0), @(0)]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
//    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
//    [self.navigationController.navigationBar setTranslucent:YES];
    
    
    self.tableView.backgroundColor = [UIColor themeColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [self setUpSubviews];
    
    _myID = [Config getOwnID];
    [self refreshHeaderView];
    
    [self refresh];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refresh
{
    _myID = [Config getOwnID];
    if (_myID == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshHeaderView];
            [self.refreshControl endRefreshing];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    } else {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
        
        [manager GET:[NSString stringWithFormat:@"%@%@?uid=%lld", OSCAPI_PREFIX, OSCAPI_MY_INFORMATION, _myID]
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
                 ONOXMLElement *userXML = [responseDocument.rootElement firstChildWithTag:@"user"];
                 _myProfile = [[OSCUser alloc] initWithXML:userXML];
                 
                 [Config updateProfile:_myProfile];
                 
                 [self refreshHeaderView];
                 [self.refreshControl endRefreshing];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.tableView reloadData];
                 });
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 MBProgressHUD *HUD = [Utils createHUD];
                 HUD.mode = MBProgressHUDModeCustomView;
                 HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                 HUD.labelText = @"网络异常，加载失败";
                 
                 [HUD hide:YES afterDelay:1];
                 
                 [self.refreshControl endRefreshing];
             }];
    }
}





- (void)pushFavoriteSVC
{
    SwipableViewController *favoritesSVC = [[SwipableViewController alloc] initWithTitle:@"收藏"
                                                                            andSubTitles:@[@"软件", @"话题", @"代码", @"博客", @"资讯"]
                                                                          andControllers:@[
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeSoftware],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeTopic],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeCode],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeBlog],
                                                                                           [[FavoritesViewController alloc] initWithFavoritesType:FavoritesTypeNews]
                                                                                           ]];
    favoritesSVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:favoritesSVC animated:YES];
}

- (void)pushFriendsSVC:(UIButton *)button
{
    SwipableViewController *friendsSVC = [[SwipableViewController alloc] initWithTitle:@"关注/粉丝"
                                                                          andSubTitles:@[@"关注", @"粉丝"]
                                                                        andControllers:@[
                                                                                         [[FriendsViewController alloc] initWithUserID:_myID andFriendsRelation:1],
                                                                                         [[FriendsViewController alloc] initWithUserID:_myID andFriendsRelation:0]
                                                                                         ]];
    if (button == _fanButton) {[friendsSVC scrollToViewAtIndex:1];}
    
    friendsSVC.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController pushViewController:friendsSVC animated:YES];
}



#pragma mark - customize subviews

- (void)setUpSubviews
{
    _creditButton.titleLabel.numberOfLines = 0;
    _creditButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    _collectionButton.titleLabel.numberOfLines = 0;
    _collectionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    _followingButton.titleLabel.numberOfLines = 0;
    _followingButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    _fanButton.titleLabel.numberOfLines = 0;
    _fanButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [_collectionButton addTarget:self action:@selector(pushFavoriteSVC) forControlEvents:UIControlEventTouchUpInside];
    [_followingButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
    [_fanButton addTarget:self action:@selector(pushFriendsSVC:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [_portrait setBorderWidth:2.0 andColor:[UIColor whiteColor]];
    [_portrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPortrait)]];
    
    [self setCoverImage];
    self.refreshControl.tintColor = [UIColor refreshControlColor];
}



- (void)tapPortrait
{
    if (![Utils isNetworkExist]) {
        MBProgressHUD *HUD = [Utils createHUD];
        HUD.mode = MBProgressHUDModeText;
        HUD.labelText = @"网络无连接，请检查网络";
        
        [HUD hide:YES afterDelay:1];
    } else {
        if ([Config getOwnID] == 0) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self.navigationController pushViewController:loginVC animated:YES];
        } else {
            [self.navigationController pushViewController:[MyBasicInfoViewController new] animated:YES];
        }
    }
}


#pragma mark - refresh header

- (void)refreshHeaderView
{
    _myProfile = [Config myProfile];
    
    BOOL isLogin = _myID != 0;
    
    if (isLogin) {
        [_portrait sd_setImageWithURL:_myProfile.portraitURL
                     placeholderImage:[UIImage imageNamed:@"default-portrait"]
                              options:SDWebImageContinueInBackground | SDWebImageHandleCookies
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                if (!image) {return;}
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"TweetUserUpdate" object:@(YES)];
                            }];
    } else {
        _portrait.image = [UIImage imageNamed:@"default-portrait"];
    }
    
    _nameLabel.text = _myProfile.name;
    _separator.backgroundColor = [UIColor lineColor];
    
    [self setCoverImage];
    
    _QRCodeButton.hidden = !isLogin;
    _creditButton.hidden = !isLogin;
    _collectionButton.hidden = !isLogin;
    _followingButton.hidden = !isLogin;
    _fanButton.hidden = !isLogin;
    _separator.hidden = !isLogin;
    
    if (isLogin) {
        [_QRCodeButton addTarget:self action:@selector(showQRCode) forControlEvents:UIControlEventTouchUpInside];
        [_creditButton setTitle:[NSString stringWithFormat:@"积分\n%@", @(_myProfile.score)] forState:UIControlStateNormal];
        [_collectionButton setTitle:[NSString stringWithFormat:@"收藏\n%@", @(_myProfile.favoriteCount)] forState:UIControlStateNormal];
        [_followingButton setTitle:[NSString stringWithFormat:@"关注\n%@", @(_myProfile.followersCount)] forState:UIControlStateNormal];
        [_fanButton setTitle:[NSString stringWithFormat:@"粉丝\n%@", @(_myProfile.fansCount)] forState:UIControlStateNormal];
    }
}


- (void)setCoverImage
{
    NSNumber *screenWidth = @([UIScreen mainScreen].bounds.size.width);
    NSString *imageName = @"user-background";
    if (screenWidth.intValue < 400) {
        imageName = [NSString stringWithFormat:@"%@-%@", imageName, screenWidth];;
    }
    
    if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode) {
        imageName = [NSString stringWithFormat:@"%@-dark", imageName];
    }
    
    if (!self.tableView.scalableCover) {
        [self.tableView addScalableCoverWithImage:[UIImage imageNamed:imageName]];
    } else {
        self.tableView.scalableCover.image = [UIImage imageNamed:imageName];
    }
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell new];
    cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    
    UIView *selectedBackground = [UIView new];
    selectedBackground.backgroundColor = [UIColor colorWithHex:0xF5FFFA];
    [cell setSelectedBackgroundView:selectedBackground];
    
    cell.backgroundColor = [UIColor cellsColor];//colorWithHex:0xF9F9F9
    
    cell.textLabel.text = @[@"消息", @"博客", @"团队"][indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@[@"me-message", @"me-blog", @"me-team"][indexPath.row]];
    
    cell.textLabel.textColor = [UIColor titleColor];
    
    if (indexPath.row == 0) {
        if (_badgeValue == 0) {
            cell.accessoryView = nil;
        } else {
            UILabel *accessoryBadge = [UILabel new];
            accessoryBadge.backgroundColor = [UIColor redColor];
            accessoryBadge.text = [@(_badgeValue) stringValue];
            accessoryBadge.textColor = [UIColor whiteColor];
            accessoryBadge.textAlignment = NSTextAlignmentCenter;
            accessoryBadge.layer.cornerRadius = 11;
            accessoryBadge.clipsToBounds = YES;
            
            CGFloat width = [accessoryBadge sizeThatFits:CGSizeMake(MAXFLOAT, 26)].width + 8;
            width = width > 26? width: 22;
            accessoryBadge.frame = CGRectMake(0, 0, width, 22);
            cell.accessoryView = accessoryBadge;
        }
    }
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = [UIColor selectCellSColor];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    switch (indexPath.row) {
        case 0: {
            _badgeValue = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
            self.navigationController.tabBarItem.badgeValue = nil;
            
            MessageCenter *messageCenterVC = [[MessageCenter alloc] initWithNoticeCounts:_noticeCounts];
            messageCenterVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:messageCenterVC animated:YES];
            
            break;
        }
        case 1: {
            BlogsViewController *blogsVC = [[BlogsViewController alloc] initWithUserID:_myID];
            blogsVC.navigationItem.title = @"我的博客";
            blogsVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:blogsVC animated:YES];
            break;
        }
        case 2: {
                        break;
        }
        default: break;
    }
}


#pragma mark - 二维码相关

- (void)showQRCode
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.color = [UIColor whiteColor];
    
    HUD.labelText = @"扫一扫上面的二维码，加我为好友";
    HUD.labelFont = [UIFont systemFontOfSize:13];
    HUD.labelColor = [UIColor grayColor];
    HUD.customView = self.myQRCodeImageView;
    [HUD addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideHUD:)]];
}

- (void)hideHUD:(UIGestureRecognizer *)recognizer
{
    [(MBProgressHUD *)recognizer.view hide:YES];
}

- (UIImageView *)myQRCodeImageView
{
    if (!_myQRCodeImageView) {
        UIImage *myQRCode = [Utils createQRCodeFromString:[NSString stringWithFormat:@"http://my.oschina.net/u/%llu", [Config getOwnID]]];
        _myQRCodeImageView = [[UIImageView alloc] initWithImage:myQRCode];
    }
    
    return _myQRCodeImageView;
}


#pragma mark - 处理通知

- (void)noticeUpdateHandler:(NSNotification *)notification
{
    NSArray *noticeCounts = [notification object];
    
    __block int sumOfCount = 0;
    [noticeCounts enumerateObjectsUsingBlock:^(NSNumber *count, NSUInteger idx, BOOL *stop) {
        _noticeCounts[idx] = count;
        sumOfCount += [count intValue];
    }];
    
    _badgeValue = sumOfCount;
    if (_badgeValue) {
        self.navigationController.tabBarItem.badgeValue = [@(sumOfCount) stringValue];
    } else {
        self.navigationController.tabBarItem.badgeValue = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:sumOfCount];
}


- (void)userRefreshHandler:(NSNotification *)notification
{
    _myID = [Config getOwnID];
    
    [self refreshHeaderView];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
