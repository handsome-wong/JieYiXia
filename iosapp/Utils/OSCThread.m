//
//  OSCThread.m
//  iosapp
//
//  Created by ChanAetern on 3/1/15.
//  Copyright (c) 2015 oschina. All rights reserved.
//

#import "OSCThread.h"
#import "OSCAPI.h"
#import "Config.h"
#import "Utils.h"

#import <AFNetworking.h>
#import <AFOnoResponseSerializer.h>
#import <Ono.h>
#import <Reachability.h>

static BOOL isPollingStarted;
static NSTimer *timer;
static Reachability *reachability;

@interface OSCThread ()

@end

@implementation OSCThread

+ (void)startPollingNotice
{
    if (isPollingStarted) {
        return;
    } else {
        timer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
        reachability = [Reachability reachabilityWithHostName:@"www.oschina.net"];
        isPollingStarted = YES;
    }
}

+ (void)timerUpdate
{
    if (reachability.currentReachabilityStatus == 0) {return;}
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager OSCManager];
    
    [manager GET:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_USER_NOTICE]
      parameters:@{@"uid":@([Config getOwnID])}
         success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
             ONOXMLElement *notice = [responseObject.rootElement firstChildWithTag:@"notice"];
             int atCount = [[[notice firstChildWithTag:@"atmeCount"] numberValue] intValue];
             int msgCount = [[[notice firstChildWithTag:@"msgCount"] numberValue] intValue];
             int reviewCount = [[[notice firstChildWithTag:@"reviewCount"] numberValue] intValue];
             int newFansCount = [[[notice firstChildWithTag:@"newFansCount"] numberValue] intValue];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:OSCAPI_USER_NOTICE
                                                                 object:@[@(atCount), @(reviewCount), @(msgCount), @(newFansCount)]];
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"%@", error);
         }];
}

@end
