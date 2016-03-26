//
//  UserDetailsViewController.h
//  iosapp
//
//  Created by chenhaoxiang on 11/5/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventsViewController.h"

@interface UserDetailsViewController : EventsViewController

- (instancetype)initWithUserID:(int64_t)userID;
- (instancetype)initWithUserName:(NSString *)userName;

@end
