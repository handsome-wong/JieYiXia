//
//  BubbleChatViewController.h
//  iosapp
//
//  Created by ChanAetern on 2/15/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "DetailsViewController.h"

@interface BubbleChatViewController : BottomBarViewController

- (instancetype)initWithUserID:(int64_t)userID andUserName:(NSString *)userName;

@end
