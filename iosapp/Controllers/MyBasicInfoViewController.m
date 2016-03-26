//
//  MyBasicInfoViewController.m
//  iosapp
//
//  Created by 李萍 on 15/2/5.
//  Copyright (c) 2015年 oschina. All rights reserved.
//

#import "MyBasicInfoViewController.h"

#import "OSCUser.h"
#import "UIColor+Util.h"
#import "OSCAPI.h"
#import "Config.h"
#import "Utils.h"
#import "HomepageViewController.h"
#import "ImageViewerController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <MBProgressHUD.h>


@interface MyBasicInfoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) OSCUser *myProfile;
@property (nonatomic, readonly, assign) int64_t myID;

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIImageView *portrait;
@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation MyBasicInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.bounces = NO;
    self.navigationItem.title = @"我的资料";
    self.view.backgroundColor = [UIColor themeColor];
    self.tableView.tableFooterView = [UIView new];
    
    _myProfile = [Config myProfile];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_HUD hide:YES];
}



#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIImageView *header = [UIImageView new];
    header.clipsToBounds = YES;
    header.userInteractionEnabled = YES;
    header.contentMode = UIViewContentModeScaleAspectFill;
    NSNumber *screenWidth = @([UIScreen mainScreen].bounds.size.width);
    NSString *imageName = @"user-background";
    if (screenWidth.intValue < 400) {
        imageName = [NSString stringWithFormat:@"%@-%@", imageName, screenWidth];
    }
    header.image = [UIImage imageNamed:imageName];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, header.image.size.width, header.image.size.height)];
    view.backgroundColor = [UIColor infosBackViewColor];
    [header addSubview:view];
    
    _portrait = [UIImageView new];
    _portrait.contentMode = UIViewContentModeScaleAspectFit;
    [_portrait setCornerRadius:25];
    [_portrait loadPortrait:_myProfile.portraitURL];
    _portrait.userInteractionEnabled = YES;
    [_portrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPortrait)]];
    [header addSubview:_portrait];
    
    _nameLabel = [UILabel new];
    _nameLabel.font = [UIFont boldSystemFontOfSize:18];
    _nameLabel.textColor = [UIColor colorWithHex:0xEEEEEE];
    _nameLabel.text = _myProfile.name;
    [header addSubview:_nameLabel];
    
    for (UIView *view in header.subviews) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_portrait, _nameLabel);
    
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[_portrait(50)]-8-[_nameLabel]-8-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    
    [header addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_portrait(50)]" options:0 metrics:nil views:views]];
    
    [header addConstraint:[NSLayoutConstraint constraintWithItem:_portrait attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
                                                             toItem:header attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
    
    return header;

}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell new];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName:[UIColor grayColor]};
    NSArray *title = @[@"加入时间：", @"所在地区：", @"开发平台：", @"专长领域："];
    
    NSString *joinTime = [_myProfile.joinTime timeAgoSinceNow];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title[indexPath.row]
                                                                                       attributes:titleAttributes];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@[
                                                                                        joinTime ?: @"",
                                                                                        _myProfile.location ?: @"",
                                                                                        _myProfile.developPlatform ?: @"",
                                                                                        _myProfile.expertise ?: @""
                                                                                        ][indexPath.row]]];
    
    cell.textLabel.attributedText = [attributedText copy];
    cell.textLabel.textColor = [UIColor titleColor];
    cell.backgroundColor = [UIColor cellsColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 111;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (void)tapPortrait
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"选择操作" message:nil delegate:self
                                              cancelButtonTitle:@"取消" otherButtonTitles:@"更换头像", @"查看大头像", nil];
    alertView.tag = 1;
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {return;}
    
    if (alertView.tag == 1)
    {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        } else if (buttonIndex == 1){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"选择图片" message:nil delegate:self
                                                      cancelButtonTitle:@"取消" otherButtonTitles:@"相机", @"相册", nil];
            alertView.tag = 2;
            
            [alertView show];
            
        } else {
            
            NSString *str = [NSString stringWithFormat:@"%@", _myProfile.portraitURL];
            
            if (str.length == 0) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"尚未设置头像" message:nil delegate:self
                                                          cancelButtonTitle:@"知道了" otherButtonTitles: nil];
                [alertView show];
                return ;
            }
            
            NSArray *array1 = [str componentsSeparatedByString:@"_"];
            
            NSArray *array2 = [array1[1] componentsSeparatedByString:@"."];
            
            NSString *bigPortraitURL = [NSString stringWithFormat:@"%@_200.%@", array1[0], array2[1]];
            
            ImageViewerController *imgViewweVC = [[ImageViewerController alloc] initWithImageURL:[NSURL URLWithString:bigPortraitURL]];
            
            [self presentViewController:imgViewweVC animated:YES completion:nil];
        }

    } else {
         if (buttonIndex == 1) {
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
                imagePickerController.allowsEditing = YES;
                imagePickerController.showsCameraControls = YES;
                imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
                
                [self presentViewController:imagePickerController animated:YES completion:nil];
            }

            
        } else {
            UIImagePickerController *imagePickerController = [UIImagePickerController new];
            imagePickerController.delegate = self;
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePickerController.allowsEditing = YES;
            imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
            
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }
}

- (void)updatePortrait
{
    MBProgressHUD *HUD = [Utils createHUD];
    HUD.labelText = @"正在上传头像";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_USERINFO_UPDATE] parameters:@{@"uid":@([Config getOwnID])}
    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if (_image) {
            [formData appendPartWithFileData:[Utils compressImage:_image] name:@"portrait" fileName:@"img.jpg" mimeType:@"image/jpeg"];
        }
    } success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDoment) {
        ONOXMLElement *result = [responseDoment.rootElement firstChildWithTag:@"result"];
        int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
        NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
        
        HUD.mode = MBProgressHUDModeCustomView;
        if (errorCode) {
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
            HUD.labelText = @"头像更新成功";
            
            HomepageViewController *homepageVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
            [homepageVC refresh];
            
            _portrait.image = _image;
        } else {
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
            HUD.labelText = errorMessage;
        }
        [HUD hide:YES afterDelay:1];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
        HUD.labelText = @"网络异常，头像更换失败";
        
        [HUD hide:YES afterDelay:1];
    }];
}


#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _image = info[UIImagePickerControllerEditedImage];
    
    [picker dismissViewControllerAnimated:YES completion:^ {
        [self updatePortrait];
    }];
}





@end
