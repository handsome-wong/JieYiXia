//
//  OSCActivity.h
//  iosapp
//
//  Created by chenhaoxiang on 1/25/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "OSCBaseObject.h"

typedef NS_ENUM(NSUInteger, ActivityStatus)
{
    ActivityStatusActivityFinished = 1,
    ActivityStatusGoing,
    ActivityStatusSignUpClosing,
};

typedef NS_ENUM(NSUInteger, ActivityApplyStatus)
{
    ActivityApplyStatusAudited,
    ActivityApplyStatusDetermined,
    ActivityApplyStatusAttended,
    ActivityApplyStatusCanceled,
    ActivityApplyStatusRejected,
};

@interface OSCActivity : OSCBaseObject

@property (nonatomic, readonly, assign)   int64_t     activityID;
@property (nonatomic, readonly, strong)   NSURL      *coverURL;
@property (nonatomic, readonly, strong)   NSURL      *url;
@property (nonatomic, readonly, copy)     NSString   *title;
@property (nonatomic, readonly, strong)   NSDate     *startTime;
@property (nonatomic, readonly, strong)   NSDate     *endTime;
@property (nonatomic, readonly, copy)     NSString   *createTime;
@property (nonatomic, readonly, copy)     NSString   *location;
@property (nonatomic, readonly, copy)     NSString   *city;
@property (nonatomic, readonly, assign)   ActivityStatus status;
@property (nonatomic, readonly, assign)   ActivityApplyStatus applyStatus;
@property (nonatomic, readonly, copy)     NSString   *remarkTip;
@property (nonatomic, readonly, strong)   NSMutableArray *remarkCitys;

@end
