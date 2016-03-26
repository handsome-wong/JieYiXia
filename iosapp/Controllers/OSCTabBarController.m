//
//  OSCTabBarController.m
//  iosapp
//
//  Created by chenhaoxiang on 12/15/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "OSCTabBarController.h"
#import "SwipableViewController.h"
#import "TweetsViewController.h"
#import "PostsViewController.h"
#import "NewsViewController.h"
#import "BlogsViewController.h"
#import "LoginViewController.h"
#import "HomepageViewController.h"
#import "DiscoverViewcontroller.h"
#import "Config.h"
#import "Utils.h"
#import "OptionButton.h"
#import "TweetEditingVC.h"
#import "UIView+Util.h"
#import "PersonSearchViewController.h"
#import "ScanViewController.h"
#import "ShakingViewController.h"
#import "VoiceTweetEditingVC.h"

#import "UIBarButtonItem+Badge.h"

#import <RESideMenu/RESideMenu.h>
#import "DXPopover.h"


@interface OSCTabBarController () <UITabBarControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    NewsViewController *newsViewCtl;
    NewsViewController *hotNewsViewCtl;
    BlogsViewController *blogViewCtl;
    BlogsViewController *recommendBlogViewCtl;
    BlogsViewController *groupBlogViewCtl;
    BlogsViewController *groupBorrowViewCtl;
    
    TweetsViewController *newTweetViewCtl;
    TweetsViewController *hotTweetViewCtl;
    TweetsViewController *myTweetViewCtl;
    
    CGFloat _popoverWidth;
    CGSize _popoverArrowSize;
    CGFloat _popoverCornerRadius;
    CGFloat _animationIn;
    CGFloat _animationOut;
    BOOL _animationSpring;
}


@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIImageView *blurView;
@property (nonatomic, assign) BOOL isPressed;
@property (nonatomic, strong) NSMutableArray *optionButtons;
@property (nonatomic, strong) UIDynamicAnimator *animator;

@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGGlyph length;

@property (nonatomic, strong) UIImageView *navimageright;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) DXPopover *popover;
@property (nonatomic, strong) NSArray *popover_configs;

@end

@implementation OSCTabBarController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dawnAndNightMode:) name:@"dawnAndNight" object:nil];
}

- (void)dawnAndNightMode:(NSNotification *)center
{
    newsViewCtl.view.backgroundColor = [UIColor themeColor];
    hotNewsViewCtl.view.backgroundColor = [UIColor themeColor];
    blogViewCtl.view.backgroundColor = [UIColor themeColor];
    recommendBlogViewCtl.view.backgroundColor = [UIColor themeColor];
    groupBlogViewCtl.view.backgroundColor = [UIColor themeColor];
    groupBorrowViewCtl.view.backgroundColor = [UIColor themeColor];
    
    newTweetViewCtl.view.backgroundColor = [UIColor themeColor];
    hotTweetViewCtl.view.backgroundColor = [UIColor themeColor];
    myTweetViewCtl.view.backgroundColor = [UIColor themeColor];

    [[UINavigationBar appearance] setBarTintColor:[UIColor navigationbarColor]];
    [[UITabBar appearance] setBarTintColor:[UIColor titleBarColor]];
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UINavigationController *nav, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            SwipableViewController *newsVc = nav.viewControllers[0];
            [newsVc.titleBar setTitleButtonsColor];
            [newsVc.viewPager.controllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                UITableViewController *table = obj;
                [table.navigationController.navigationBar setBarTintColor:[UIColor navigationbarColor]];
                [table.tabBarController.tabBar setBarTintColor:[UIColor titleBarColor]];
                [table.tableView reloadData];
            }];

        } else if (idx == 1) {
            SwipableViewController *tweetVc = nav.viewControllers[0];
            [tweetVc.titleBar setTitleButtonsColor];
            [tweetVc.viewPager.controllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                UITableViewController *table = obj;
                [table.navigationController.navigationBar setBarTintColor:[UIColor navigationbarColor]];
                [table.tabBarController.tabBar setBarTintColor:[UIColor titleBarColor]];
                [table.tableView reloadData];
            }];

        } else if (idx == 3) {
            DiscoverViewController *dvc = nav.viewControllers[0];
            [dvc.navigationController.navigationBar setBarTintColor:[UIColor navigationbarColor]];
            [dvc.tabBarController.tabBar setBarTintColor:[UIColor titleBarColor]];
            [dvc dawnAndNightMode];
        } else if (idx == 4) {
            HomepageViewController *homepageVC = nav.viewControllers[0];
            [homepageVC.navigationController.navigationBar setBarTintColor:[UIColor navigationbarColor]];
            [homepageVC.tabBarController.tabBar setBarTintColor:[UIColor titleBarColor]];
            [homepageVC dawnAndNightMode];
        }
    }];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"dawnAndNight" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    newsViewCtl = [[NewsViewController alloc]  initWithNewsListType:NewsListTypeNews];
    hotNewsViewCtl = [[NewsViewController alloc]  initWithNewsListType:NewsListTypeAllTypeWeekHottest];
    blogViewCtl = [[BlogsViewController alloc] initWithBlogsType:BlogTypeLatest];
    recommendBlogViewCtl = [[BlogsViewController alloc] initWithBlogsType:BlogTypeRecommended];
    groupBlogViewCtl= [[BlogsViewController alloc] initWithBlogsType:BlogTypeRecommended];
    groupBorrowViewCtl= [[BlogsViewController alloc] initWithBlogsType:BlogTypeRecommended];
    
    newTweetViewCtl = [[TweetsViewController alloc] initWithTweetsType:TweetsTypeAllTweets];
    hotTweetViewCtl = [[TweetsViewController alloc] initWithTweetsType:TweetsTypeHotestTweets];
    myTweetViewCtl = [[TweetsViewController alloc] initWithTweetsType:TweetsTypeOwnTweets];
    
    newsViewCtl.needCache = YES;
    hotNewsViewCtl.needCache = YES;
    blogViewCtl.needCache = YES;
    recommendBlogViewCtl.needCache = YES;
    
    newTweetViewCtl.needCache = YES;
    hotTweetViewCtl.needCache = YES;
    myTweetViewCtl.needCache = YES;
    
    SwipableViewController *newsSVC = [[SwipableViewController alloc]initWithTitle:@"消息"
                                                                       andSubTitles:@[@"关系", @"消息", @"晒宝", @"租借", @"群·动态", @"群·租借"]
                                                                     andControllers:@[newsViewCtl, hotNewsViewCtl, blogViewCtl,recommendBlogViewCtl,groupBlogViewCtl,groupBorrowViewCtl]
                                                                       underTabbar:YES currenIndex:1];
    
    
    SwipableViewController *tweetsSVC = [[SwipableViewController alloc] initWithTitle:@"借一下"
                                                                         andSubTitles:@[@"租借", @"群·动态", @"活动"]
                                                                       andControllers:@[newTweetViewCtl, hotTweetViewCtl, myTweetViewCtl]
                                                                          underTabbar:YES];
    
    UIStoryboard *discoverSB = [UIStoryboard storyboardWithName:@"Discover" bundle:nil];
    UINavigationController *discoverNav = [discoverSB instantiateViewControllerWithIdentifier:@"Nav"];
    
    
    UIStoryboard *homepageSB = [UIStoryboard storyboardWithName:@"Homepage" bundle:nil];
    UINavigationController *homepageNav = [homepageSB instantiateViewControllerWithIdentifier:@"Nav"];
    
    
    self.tabBar.translucent = NO;
    self.viewControllers = @[
                             [self addNavigationItemForViewController:newsSVC],
                             [self addNavigationItemForViewController:tweetsSVC],
                             [UIViewController new],
                             discoverNav,
                             homepageNav,
                             ];
    
    NSArray *titles = @[@"消息", @"借一下", @"", @"通讯录", @"我的"];
    NSArray *images = @[@"tabbar-news", @"tabbar-tweet", @"", @"tabbar-discover", @"tabbar-me"];
    [self.tabBar.items enumerateObjectsUsingBlock:^(UITabBarItem *item, NSUInteger idx, BOOL *stop) {
        [item setTitle:titles[idx]];
        [item setImage:[UIImage imageNamed:images[idx]]];
        [item setSelectedImage: [[UIImage imageNamed:[images[idx] stringByAppendingString:@"-selected"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }];
    [self.tabBar.items[2] setEnabled:NO];
    
    [self addCenterButtonWithImage:[UIImage imageNamed:@"tabbar-more"]];
    
    [self.tabBar addObserver:self
                  forKeyPath:@"selectedItem"
                     options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                     context:nil];
    
    // 功能键相关
    _optionButtons = [NSMutableArray new];
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    _screenWidth  = [UIScreen mainScreen].bounds.size.width;
    _length = 60;        // 圆形按钮的直径
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    NSArray *buttonTitles = @[@"文字", @"相册", @"拍照", @"语音", @"扫一扫", @"找人"];
    NSArray *buttonImages = @[@"tweetEditing", @"picture", @"shooting", @"sound", @"scan", @"search"];
    int buttonColors[] = {0xe69961, 0x0dac6b, 0x24a0c4, 0xe96360, 0x61b644, 0xf1c50e};
    
    for (int i = 0; i < 6; i++) {
        OptionButton *optionButton = [[OptionButton alloc] initWithTitle:buttonTitles[i]
                                                                   image:[UIImage imageNamed:buttonImages[i]]
                                                                andColor:[UIColor colorWithHex:buttonColors[i]]];
        
        optionButton.frame = CGRectMake((_screenWidth/6 * (i%3*2+1) - (_length+16)/2),
                                        _screenHeight + 150 + i/3*100,
                                        _length + 16,
                                        _length + [UIFont systemFontOfSize:14].lineHeight + 24);
        [optionButton.button setCornerRadius:_length/2];
        
        optionButton.tag = i;
        optionButton.userInteractionEnabled = YES;
        [optionButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOptionButton:)]];
        
        [self.view addSubview:optionButton];
        [_optionButtons addObject:optionButton];
    }
    
    UITableView *blueView = [[UITableView alloc] init];
    blueView.frame = CGRectMake(0, 0, _popoverWidth, 350);
    blueView.dataSource = self;
    blueView.delegate = self;
    self.tableView = blueView;
    [self resetPopover];
    
    self.popover_configs = @[
                     @"添加手机联系",
                     @"扫一扫",
                     @"建群"
                     ];
}


-(void)addCenterButtonWithImage:(UIImage *)buttonImage
{
    _centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    CGPoint origin = [self.view convertPoint:self.tabBar.center toView:self.tabBar];
    CGSize buttonSize = CGSizeMake(self.tabBar.frame.size.width / 5 - 6, self.tabBar.frame.size.height - 4);
    
    _centerButton.frame = CGRectMake(origin.x - buttonSize.height/2, origin.y - buttonSize.height/2, buttonSize.height, buttonSize.height);
    
    [_centerButton setCornerRadius:buttonSize.height/2];
    //[_centerButton setBackgroundColor:[UIColor colorWithHex:0x24a83d]];
    [_centerButton setImage:buttonImage forState:UIControlStateNormal];
    [_centerButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.tabBar addSubview:_centerButton];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedItem"]) {
        if(self.isPressed) {[self buttonPressed];}
    }
}


- (void)buttonPressed
{
    [self changeTheButtonStateAnimatedToOpen:_isPressed];
    
    _isPressed = !_isPressed;
}


- (void)changeTheButtonStateAnimatedToOpen:(BOOL)isPressed
{
    if (isPressed) {
        [self removeBlurView];
        
        [_animator removeAllBehaviors];
        for (int i = 0; i < 6; i++) {
            UIButton *button = _optionButtons[i];
            
            UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:button
                                                                         attachedToAnchor:CGPointMake(_screenWidth/6 * (i%3*2+1),
                                                                                                      _screenHeight + 200 + i/3*100)];
            attachment.damping = 0.65;
            attachment.frequency = 4;
            attachment.length = 1;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC * (6 - i)), dispatch_get_main_queue(), ^{
                [_animator addBehavior:attachment];
            });
        }
    } else {
        [self addBlurView];
        
        [_animator removeAllBehaviors];
        for (int i = 0; i < 6; i++) {
            UIButton *button = _optionButtons[i];
            [self.view bringSubviewToFront:button];
            
            UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:button
                                                                         attachedToAnchor:CGPointMake(_screenWidth/6 * (i%3*2+1),
                                                                                                      _screenHeight - 200 + i/3*100)];
            attachment.damping = 0.65;
            attachment.frequency = 4;
            attachment.length = 1;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.02 * NSEC_PER_SEC * (i + 1)), dispatch_get_main_queue(), ^{
                [_animator addBehavior:attachment];
            });
        }
    }
}

- (void)addBlurView
{
    _centerButton.enabled = NO;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect cropRect = CGRectMake(0, screenSize.height - 270, screenSize.width, screenSize.height);
    
    UIImage *originalImage = [self.view updateBlur];
    UIImage *croppedBlurImage = [originalImage cropToRect:cropRect];
    
    _blurView = [[UIImageView alloc] initWithImage:croppedBlurImage];
    _blurView.frame = cropRect;
    _blurView.userInteractionEnabled = YES;
    [self.view addSubview:_blurView];
    
    _dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    _dimView.backgroundColor = [UIColor blackColor];
    _dimView.alpha = 0.4;
    [self.view insertSubview:_dimView belowSubview:self.tabBar];
    
    [_blurView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPressed)]];
    [_dimView  addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPressed)]];
    
    [UIView animateWithDuration:0.25f
                     animations:nil
                     completion:^(BOOL finished) {
                         if (finished) {_centerButton.enabled = YES;}
                     }];
}


- (void)removeBlurView
{
    _centerButton.enabled = NO;
    
    self.view.alpha = 1;
    [UIView animateWithDuration:0.25f
                     animations:nil
                     completion:^(BOOL finished) {
                         if(finished) {
                             [_dimView removeFromSuperview];
                             _dimView = nil;
                             
                             [self.blurView removeFromSuperview];
                             self.blurView = nil;
                             _centerButton.enabled = YES;
                         }
                     }];
}



#pragma mark - 处理点击事件

- (void)onTapOptionButton:(UIGestureRecognizer *)recognizer
{
    switch (recognizer.view.tag) {
        case 0: {
            TweetEditingVC *tweetEditingVC = [TweetEditingVC new];
            UINavigationController *tweetEditingNav = [[UINavigationController alloc] initWithRootViewController:tweetEditingVC];
            [self.selectedViewController presentViewController:tweetEditingNav animated:YES completion:nil];
            break;
        }
        case 1: {
            UIImagePickerController *imagePickerController = [UIImagePickerController new];
            imagePickerController.delegate = self;
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePickerController.allowsEditing = NO;
            imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
            
            [self presentViewController:imagePickerController animated:YES completion:nil];
            
            break;
        }
        case 2: {
            if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:@"Device has no camera"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles: nil];
                
                [alertView show];
            } else {
                UIImagePickerController *imagePickerController = [UIImagePickerController new];
                imagePickerController.delegate = self;
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePickerController.allowsEditing = NO;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
                
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }
            break;
        }
        case 3: {
            /*
            ShakingViewController *shakingVC = [ShakingViewController new];
            UINavigationController *shakingNav = [[UINavigationController alloc] initWithRootViewController:shakingVC];
            [self.selectedViewController presentViewController:shakingNav animated:NO completion:nil];
             */
            
            VoiceTweetEditingVC *voiceTweetVC = [VoiceTweetEditingVC new];
            UINavigationController *voiceTweetNav = [[UINavigationController alloc] initWithRootViewController:voiceTweetVC];
            [self.selectedViewController presentViewController:voiceTweetNav animated:NO completion:nil];
            
            break;
        }
        case 4: {
            ScanViewController *scanVC = [ScanViewController new];
            UINavigationController *scanNav = [[UINavigationController alloc] initWithRootViewController:scanVC];
            [self.selectedViewController presentViewController:scanNav animated:NO completion:nil];
            break;
        }
        case 5: {
            PersonSearchViewController *personSearchVC = [PersonSearchViewController new];
            UINavigationController *personSearchNav = [[UINavigationController alloc] initWithRootViewController:personSearchVC];
            [self.selectedViewController presentViewController:personSearchNav animated:YES completion:nil];
            break;
        }
        default: break;
    }
    
    [self buttonPressed];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{    
    //如果是拍照的照片，则需要手动保存到本地，系统不会自动保存拍照成功后的照片
    //UIImageWriteToSavedPhotosAlbum(edit, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    [picker dismissViewControllerAnimated:NO completion:^{
        TweetEditingVC *tweetEditingVC = [[TweetEditingVC alloc] initWithImage:info[UIImagePickerControllerOriginalImage]];
        UINavigationController *tweetEditingNav = [[UINavigationController alloc] initWithRootViewController:tweetEditingVC];
        [self.selectedViewController presentViewController:tweetEditingNav animated:NO completion:nil];
    }];
}


#pragma mark -

- (UINavigationController *)addNavigationItemForViewController:(UIViewController *)viewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    /*viewController.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigationbar-sidebar"]
                                                                                        style:UIBarButtonItemStylePlain
                                                                                       target:self action:@selector(onClickMenuButton)];
    
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                                     target:self
                                                                                                     action:@selector(pushSearchViewController)];*/
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigationbar-add"]  style:UIBarButtonItemStylePlain
                                                                                                     target:self
                                                                                                     action:@selector (nibBundle)];
    
    
    
    return navigationController;
}

- (void)onClickMenuButton
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (self.selectedIndex <= 1 && self.selectedIndex == [tabBar.items indexOfObject:item]) {
        SwipableViewController *swipeableVC = (SwipableViewController *)((UINavigationController *)self.selectedViewController).viewControllers[0];
        OSCObjsViewController *objsViewController = (OSCObjsViewController *)swipeableVC.viewPager.childViewControllers[swipeableVC.titleBar.currentIndex];
        
        [UIView animateWithDuration:0.1 animations:^{
            [objsViewController.tableView setContentOffset:CGPointMake(0, -objsViewController.refreshControl.frame.size.height)];
        } completion:^(BOOL finished) {
            [objsViewController.tableView.header beginRefreshing];
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [objsViewController refresh];
        });
    }
}

#pragma mark - 处理左右navigationItem点击事件

- (void)pushSearchViewController
{
    //[(UINavigationController *)self.selectedViewController pushViewController:[SearchViewController new] animated:YES];
}

- (void)resetPopover {
    self.popover = [DXPopover new];
    _popoverWidth = 280.0;
}

- (void)showPopover {
    [self updateTableViewFrame];
    
    CGPoint startPoint =
    CGPointMake(CGRectGetMidX(CGRectMake(10,410, 300, 30)), CGRectGetMaxY(CGRectMake(10,410, 300, 30)) + 5);
    [self.popover showAtPoint:startPoint
               popoverPostion:DXPopoverPositionDown
              withContentView:self.tableView
                       inView:self.tabBarController.view];
    
    __weak typeof(self) weakSelf = self;
    self.popover.didDismissHandler = ^{
        [weakSelf bounceTargetView:weakSelf.navimageright];
    };
}

- (void)updateTableViewFrame {
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.width = _popoverWidth;
    self.tableView.frame = tableViewFrame;
    self.popover.contentInset = UIEdgeInsetsZero;
    self.popover.backgroundColor = [UIColor whiteColor];
}

- (void)bounceTargetView:(UIView *)targetView {
    targetView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         targetView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.popover_configs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellId];
    }
    cell.textLabel.text = self.popover_configs[indexPath.row];
    
    return cell;
}

static int i = 0;
static int j = 1;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        int c = i % 3;
        if (c == 0) {
            _popoverWidth = 160.0;
        } else if (c == 1) {
            _popoverWidth = 250.0;
        } else if (c == 2) {
            _popoverWidth = 300.0;
        }
        i++;
    } else if (indexPath.row == 1) {
        CGSize arrowSize = self.popover.arrowSize;
        arrowSize.width += randomFloatBetweenLowAndHigh(3.0, 5.0);
        arrowSize.height += randomFloatBetweenLowAndHigh(3.0, 5.0);
        self.popover.arrowSize = arrowSize;
    } else if (indexPath.row == 2) {
        self.popover.cornerRadius += randomFloatBetweenLowAndHigh(0.0, 1.0);
    } else if (indexPath.row == 3) {
        self.popover.animationIn = randomFloatBetweenLowAndHigh(0.4, 2.0);
    } else if (indexPath.row == 4) {
        self.popover.animationOut = randomFloatBetweenLowAndHigh(0.4, 2.0);
    } else if (indexPath.row == 5) {
        self.popover.animationSpring = !self.popover.animationSpring;
    } else if (indexPath.row == 6) {
        self.popover.maskType = j % 2;
        j++;
    }
    [self.popover dismiss];
}
static CGFloat randomFloatBetweenLowAndHigh(CGFloat low, CGFloat high) {
    CGFloat diff = high - low;
    return (((CGFloat)rand() / RAND_MAX) * diff) + low;
}
@end
