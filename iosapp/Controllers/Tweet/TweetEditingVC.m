//
//  TweetEditingVC.m
//  iosapp
//
//  Created by ChanAetern on 12/18/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "TweetEditingVC.h"
#import "EmojiPageVC.h"
#import "OSCAPI.h"
#import "TeamAPI.h"
#import "Config.h"
#import "Utils.h"
#import "PlaceholderTextView.h"
#import "LoginViewController.h"
#import "ImageViewerController.h"
#import "AppDelegate.h"
#import "Config.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>
#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <MBProgressHUD.h>
#import <ReactiveCocoa.h>
#import "TweetFriendsListViewController.h"


@interface TweetEditingVC () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView          *scrollView;
@property (nonatomic, strong) UIView                *contentView;
@property (nonatomic, strong) PlaceholderTextView   *edittingArea;
@property (nonatomic, strong) UIImageView           *imageView;
@property (nonatomic, strong) UILabel               *deleteImageButton;
@property (nonatomic, strong) UIToolbar             *toolBar;
@property (nonatomic, strong) NSLayoutConstraint    *keyboardHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint    *textViewHeightConstraint;
@property (nonatomic, strong) EmojiPageVC           *emojiPageVC;
@property (nonatomic, assign) BOOL                  isEmojiPageOnScreen;

@property (nonatomic, strong) UIImage               *image;
@property (nonatomic, strong) NSString              *topicName;
@property (nonatomic, assign) int                   teamID;

@end

@implementation TweetEditingVC

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _image = image;
    }
    
    return self;
}

- (instancetype)initWithTopic:(NSString *)topic
{
    self = [super init];
    if (self) {
        _topicName = topic;
    }
    
    return self;
}

- (instancetype)initWithTeamID:(int)teamID
{
    self = [super init];
    if (self) {
        _teamID = teamID;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"弹一弹";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelButtonClicked)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发表"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(pubTweet)];
    self.view.backgroundColor = [UIColor whiteColor];
    
    ((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode = [Config getMode];
    [self initSubViews];
    [self setLayout];
    
    if (!_edittingArea.text.length) {
        _edittingArea.text = [Config getTweetText];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor themeColor];
    [_edittingArea.delegate textViewDidChange:_edittingArea];
    
    [_edittingArea becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)initSubViews
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.scrollEnabled = YES;
    _scrollView.bounces = YES;
    [self.view addSubview:_scrollView];
    
    _contentView = [[UIView alloc] initWithFrame:_scrollView.bounds];
    _contentView.userInteractionEnabled = YES;
    [_scrollView addSubview:_contentView];
    _scrollView.contentSize = _contentView.bounds.size;
    
    _edittingArea = [PlaceholderTextView new];
    _edittingArea.placeholder = @"今天你动弹了吗？";
    _edittingArea.delegate = self;
    if (_topicName.length) {
        _edittingArea.text = [NSString stringWithFormat:@"#%@#", _topicName];
    }
    _edittingArea.returnKeyType = UIReturnKeySend;
    _edittingArea.enablesReturnKeyAutomatically = YES;
    _edittingArea.scrollEnabled = NO;
    _edittingArea.font = [UIFont systemFontOfSize:18];
    _edittingArea.autocorrectionType = UITextAutocorrectionTypeNo;
    [_contentView addSubview:_edittingArea];
    
    if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode) {
        _edittingArea.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    
    _edittingArea.backgroundColor = [UIColor themeColor];
    _edittingArea.textColor = [UIColor titleColor];
    
    _emojiPageVC = [[EmojiPageVC alloc] initWithTextView:_edittingArea];
    _emojiPageVC.view.hidden = YES;
    _emojiPageVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_emojiPageVC.view];
    
    _imageView = [UIImageView new];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.userInteractionEnabled = YES;
    _imageView.image = _image;
    _image = nil;
    [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showImagePreview)]];
    [_contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:_edittingArea action:@selector(becomeFirstResponder)]];
    [_contentView addSubview:_imageView];
    
    
    _deleteImageButton = [UILabel new];
    _deleteImageButton.userInteractionEnabled = YES;
    _deleteImageButton.text = @"✕";
    _deleteImageButton.textColor = [UIColor whiteColor];
    _deleteImageButton.backgroundColor = [UIColor redColor];
    _deleteImageButton.textAlignment = NSTextAlignmentCenter;
    _deleteImageButton.hidden = _imageView.image == nil;
    [_deleteImageButton setCornerRadius:11];
    [_deleteImageButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteImage)]];
    [_contentView addSubview:_deleteImageButton];
    
    
    /****** toolBar ******/
    
    _toolBar = [UIToolbar new];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixedSpace.width = 25.0f;
    NSMutableArray *barButtonItems = [[NSMutableArray alloc] initWithObjects:fixedSpace, nil];
    NSArray *iconName = @[@"toolbar-image", @"toolbar-mention", @"toolbar-reference", @"toolbar-emoji"];
    NSArray *action   = @[@"addImage", @"mentionSomenone", @"referSoftware", @"switchInputView"];
    for (int i = 0; i < 4; i++) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:iconName[i]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:NSSelectorFromString(action[i])];
        //button.tintColor = [UIColor grayColor];
        if (((AppDelegate *)[UIApplication sharedApplication].delegate).inNightMode) {
            _toolBar.barTintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
            button.tintColor = [UIColor clearColor];
        } else {
            _toolBar.barTintColor = [UIColor colorWithRed:246.0/255 green:246.0/255 blue:246.0/255 alpha:1.0];
            button.tintColor = [UIColor clearColor];
        }
        [barButtonItems addObject:button];
        if (i < 3) {[barButtonItems addObject:flexibleSpace];}
    }
    [barButtonItems addObject:fixedSpace];
    [_toolBar setItems:barButtonItems];
    
    // 底部添加border
    
    UIView *bottomBorder = [UIView new];
    bottomBorder.backgroundColor = [UIColor borderColor];
    bottomBorder.translatesAutoresizingMaskIntoConstraints = NO;
    [_toolBar addSubview:bottomBorder];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(bottomBorder);
    
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[bottomBorder]|" options:0 metrics:nil views:views]];
    [_toolBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomBorder(0.5)]|" options:0 metrics:nil views:views]];
    
    [self.view addSubview:_toolBar];
    
    _toolBar.backgroundColor = [UIColor themeColor];
}

- (void)setLayout
{
    for (UIView *view in _contentView.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    _toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(_edittingArea, _imageView, _toolBar, _deleteImageButton, _contentView);
    
    
    
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_edittingArea]-30-[_imageView(90)]"
                                                                         options:NSLayoutFormatAlignAllLeft metrics:nil views:views]];
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_imageView(90)]" options:0 metrics:nil views:views]];
    
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-8-[_edittingArea]-8-|" options:0 metrics:nil views:views]];
    _textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:_edittingArea attribute:NSLayoutAttributeHeight         relatedBy:NSLayoutRelationEqual
                                                                toItem:nil           attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:48];
    [_contentView addConstraint:_textViewHeightConstraint];
    
    
    
    /*** toolBar ***/
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_toolBar]|" options:0 metrics:nil views:views]];
    _keyboardHeightConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
                                                                toItem:_toolBar  attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self.view addConstraint:_keyboardHeightConstraint];
    
    
    /*** emojiPage ***/
    
    NSDictionary *view = @{@"emojiPage": _emojiPageVC.view};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emojiPage(216)]|" options:0 metrics:nil views:view]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[emojiPage]|" options:0 metrics:nil views:view]];
    
    
    
    /*** delete button ***/
    
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_deleteImageButton(22)]" options:0 metrics:nil views:views]];
    [_contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_deleteImageButton(22)]"   options:0 metrics:nil views:views]];
    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView         attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                                toItem:_deleteImageButton attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView         attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                                                toItem:_deleteImageButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

- (void)cancelButtonClicked
{
    if (_edittingArea.text.length > 0) {
        NSString *alertString = _teamID? @"是否取消编辑动弹" : @"是否保存已编辑的信息";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertString message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        [alertView show];
    } else {
        [Config saveTweetText:@"" forUser:[Config getOwnID]];
        [_edittingArea resignFirstResponder];
        
        if (_teamID) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_teamID) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }
    } else {
        [Config saveTweetText:buttonIndex == alertView.cancelButtonIndex? @"" : _edittingArea.text
                      forUser:[Config getOwnID]];
    }
    [_edittingArea resignFirstResponder];
    
    if (_teamID) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - ToolBar 高度相关

- (void)keyboardWillShow:(NSNotification *)notification
{
    _emojiPageVC.view.hidden = YES;
    _isEmojiPageOnScreen = NO;
    
    CGRect keyboardBounds = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardHeightConstraint.constant = keyboardBounds.size.height;
    
    [self updateBarHeight];
}


- (void)keyboardWillHide:(NSNotification *)notification
{
    _keyboardHeightConstraint.constant = 0;
    
    [self updateBarHeight];
}


- (void)updateBarHeight
{
    [self.view setNeedsUpdateConstraints];
    [UIView animateKeyframesWithDuration:0.25       //animationDuration
                                   delay:0
                                 options:7 << 16    //animationOptions
                              animations:^{
                                  [self.view layoutIfNeeded];
                              } completion:nil];
}



#pragma mark - ToolBar 操作

#pragma mark 图片相关

- (void)addImage
{
    [self.edittingArea resignFirstResponder]; //键盘遮盖了actionsheet
    
    [[[UIActionSheet alloc] initWithTitle:@"添加图片"
                                 delegate:self
                        cancelButtonTitle:@"取消"
                   destructiveButtonTitle:nil
                        otherButtonTitles:@"相册", @"相机", nil]
     
     showInView:self.view];
}

- (void)showImagePreview
{
    if (_imageView.image) {
        [self.navigationController presentViewController:[[ImageViewerController alloc] initWithImage:_imageView.image] animated:YES completion:nil];
    }
}

- (void)deleteImage
{
    _imageView.image = nil;
    _deleteImageButton.hidden = YES;
}


#pragma mark 插入字符串操作（@人，引用软件或发表话题）

- (void)mentionSomenone
{
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    if (_teamID) {
           }
    else {
        TweetFriendsListViewController * vc = [TweetFriendsListViewController new];
        [vc setSelectDone:^(NSString *result) {
            [self insertString:result andSelect:NO];
        }];
        [self.navigationController pushViewController:vc
                                             animated:YES];
    }
}

- (void)referSoftware
{
    [self insertString:@"#请输入软件名或话题#" andSelect:YES];
}

- (void)insertString:(NSString *)string andSelect:(BOOL)shouldSelect
{
    [_edittingArea becomeFirstResponder];
    
    NSUInteger cursorLocation = _edittingArea.selectedRange.location;
    [_edittingArea replaceRange:_edittingArea.selectedTextRange withText:string];
    
    if (shouldSelect) {
        UITextPosition *selectedStartPos = [_edittingArea positionFromPosition:_edittingArea.beginningOfDocument offset:cursorLocation + 1];
        UITextPosition *selectedEndPos   = [_edittingArea positionFromPosition:_edittingArea.beginningOfDocument offset:cursorLocation + string.length - 1];
        
        UITextRange *newRange = [_edittingArea textRangeFromPosition:selectedStartPos toPosition:selectedEndPos];
        
        [_edittingArea setSelectedTextRange:newRange];
    }
}


#pragma mark 表情面板与键盘切换

- (void)switchInputView
{
    // 还要考虑一下用外接键盘输入时，置空inputView后，字体小的情况
    
    if (_isEmojiPageOnScreen) {
        [_edittingArea becomeFirstResponder];
        
        [_toolBar.items[7] setImage:[[UIImage imageNamed:@"toolbar-emoji"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        _edittingArea.font = [UIFont systemFontOfSize:18];
    } else {
        [_edittingArea resignFirstResponder];
        [_toolBar.items[7] setImage:[[UIImage imageNamed:@"toolbar-text"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        
        _keyboardHeightConstraint.constant = 216;
        [self updateBarHeight];
    }
    
    _emojiPageVC.view.hidden = !_emojiPageVC.view.hidden;
    _isEmojiPageOnScreen = !_isEmojiPageOnScreen;
}


#pragma mark 发表动弹

- (void)pubTweet
{
    if ([Config getOwnID] == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        LoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.labelText = @"动弹发送中";
    [HUD hide:YES afterDelay:1];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
        
        NSString *API = _teamID? TEAM_TWEET_PUB : OSCAPI_TWEET_PUB;
        [manager             POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, API]
                       parameters:@{
                                    @"uid": @([Config getOwnID]),
                                    @"msg": [Utils convertRichTextToRawText:_edittingArea],
                                    @"teamid": @(_teamID)
                                    }
         
        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            if (_imageView.image) {
                [formData appendPartWithFileData:[Utils compressImage:_imageView.image]
                                            name:@"img"
                                        fileName:@"img.jpg"
                                        mimeType:@"image/jpeg"];
            }
        }
         
                          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
                              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
                              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
                              NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
                              
                              HUD.mode = MBProgressHUDModeCustomView;
                              [HUD show:YES];
                              
                              if (errorCode == 1) {
                                  _edittingArea.text = @"";
                                  _imageView.image = nil;
                                  _deleteImageButton.hidden = YES;
                                  
                                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                                  HUD.labelText = @"动弹发表成功";
                                  
                                  [Config saveTweetText:@"" forUser:[Config getOwnID]];
                              } else {
                                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                                  HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
                                  
                                  [Config saveTweetText:_edittingArea.text forUser:[Config getOwnID]];
                              }
                              
                              [HUD hide:YES afterDelay:1];
                              
                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              HUD.mode = MBProgressHUDModeCustomView;
                              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                              HUD.labelText = @"网络异常，动弹发送失败";
                              
                              [HUD hide:YES afterDelay:1];
                              
                              [Config saveTweetText:_edittingArea.text forUser:[Config getOwnID]];
                          }];
    });
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    } else if (buttonIndex == 0) {
        UIImagePickerController *imagePickerController = [UIImagePickerController new];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.allowsEditing = NO;
        imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else {
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
    }
}

#pragma mark - UIImagePickerController 回调函数

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _imageView.image = info[UIImagePickerControllerOriginalImage];
    _deleteImageButton.hidden = NO;
    
    //如果是拍照的照片，则需要手动保存到本地，系统不会自动保存拍照成功后的照片
    //UIImageWriteToSavedPhotosAlbum(edit, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString: @"\n"]) {
        [self pubTweet];
        [textView resignFirstResponder];
        return NO;
    }
    
    if (_teamID && [text isEqualToString: @"@"]) {
        [self mentionSomenone];
        return NO;
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.navigationItem.rightBarButtonItem.enabled = [textView hasText];
}

- (void)textViewDidChange:(PlaceholderTextView *)textView
{
    self.navigationItem.rightBarButtonItem.enabled = [textView hasText];
    
    CGFloat height = ceilf([textView sizeThatFits:textView.frame.size].height + 10);
    if (height != _textViewHeightConstraint.constant) {
        _textViewHeightConstraint.constant = height;
        [self.view layoutIfNeeded];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == _scrollView) {
        [_edittingArea resignFirstResponder];
        
        if (_keyboardHeightConstraint.constant != 0) {
            _emojiPageVC.view.hidden = YES;
            _isEmojiPageOnScreen = NO;
            [_toolBar.items[7] setImage:[[UIImage imageNamed:@"toolbar-emoji"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            
            _keyboardHeightConstraint.constant = 0;
            [self updateBarHeight];
        }
    }
}



@end
