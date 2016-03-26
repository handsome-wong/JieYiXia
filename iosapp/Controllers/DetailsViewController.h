//
//  DetailsViewController.h
//  iosapp
//
//  Created by chenhaoxiang on 10/31/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "BottomBarViewController.h"

typedef NS_ENUM(int, DetailsType)
{
    DetailsTypeNews,
    DetailsTypeBlog,
    DetailsTypeSoftware,
};

typedef NS_ENUM(int, FavoriteType)
{
    FavoriteTypeSoftware = 1,
    FavoriteTypeTopic,
    FavoriteTypeBlog,
    FavoriteTypeNews,
    FavoriteTypeCode,
};

@class OSCNews;
@class OSCBlog;
@class OSCPost;
@class OSCSoftware;

@interface DetailsViewController : BottomBarViewController

- (instancetype)initWithNews:(OSCNews *)news;
- (instancetype)initWithBlog:(OSCBlog *)blog;
- (instancetype)initWithPost:(OSCPost *)post;
- (instancetype)initWithSoftware:(OSCSoftware *)software;

@end
