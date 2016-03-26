//
//  FriendsViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 12/11/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "FriendsViewController.h"
#import "OSCUser.h"
#import "PersonCell.h"
#import "UserDetailsViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>

static NSString * const kPersonCellID = @"PersonCell";

@interface FriendsViewController ()

@property (nonatomic, assign) int64_t uid;

@end

@implementation FriendsViewController

- (instancetype)initWithUserID:(int64_t)userID andFriendsRelation:(int)relation
{
    self = [super init];
    if (!self) {return nil;}
    
    self.generateURL = ^NSString * (NSUInteger page) {
        return [NSString stringWithFormat:@"%@%@?uid=%lld&relation=%d&pageIndex=%lu&%@", OSCAPI_PREFIX, OSCAPI_FRIENDS_LIST, userID, relation, (unsigned long)page, OSCAPI_SUFFIX];
    };
    
    self.objClass = [OSCUser class];
    
    return self;
}



- (NSArray *)parseXML:(ONOXMLDocument *)xml
{
    return [[xml.rootElement firstChildWithTag:@"friends"] childrenWithTag:@"friend"];
}





#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[PersonCell class] forCellReuseIdentifier:kPersonCellID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}




#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSCUser *friend = self.objects[indexPath.row];
    PersonCell *cell = [tableView dequeueReusableCellWithIdentifier:kPersonCellID forIndexPath:indexPath];
    
    [cell.portrait loadPortrait:friend.portraitURL];
    cell.nameLabel.text = friend.name;
    cell.infoLabel.text = friend.expertise;
    cell.infoLabel.textColor = [UIColor titleColor];
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = [UIColor selectCellSColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSCUser *friend = self.objects[indexPath.row];
    self.label.text = friend.name;
    self.label.font = [UIFont systemFontOfSize:16];
    CGSize nameSize = [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 60, MAXFLOAT)];
    
    self.label.text = friend.expertise;
    self.label.font = [UIFont systemFontOfSize:12];
    CGSize infoLabelSize = [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 60, MAXFLOAT)];
    
    return nameSize.height + infoLabelSize.height + 21;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OSCUser *friend = self.objects[indexPath.row];
    UserDetailsViewController *userDetailsVC = [[UserDetailsViewController alloc] initWithUserID:friend.userID];
    [self.navigationController pushViewController:userDetailsVC animated:YES];
}




@end
