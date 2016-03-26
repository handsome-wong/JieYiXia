//
//  Config.m
//  iosapp
//
//  Created by chenhaoxiang on 11/6/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "Config.h"
#import "OSCUser.h"

#import <SSKeychain.h>

NSString * const kService = @"OSChina";
NSString * const kAccount = @"account";
NSString * const kUserID = @"userID";

NSString * const kUserName = @"name";
NSString * const kPortrait = @"portrait";
NSString * const kPortraitURL = @"portraitURL";
NSString * const kUserScore = @"score";
NSString * const kFavoriteCount = @"favoritecount";
NSString * const kFanCount = @"fans";
NSString * const kFollowerCount = @"followers";

NSString * const kJoinTime = @"jointime";
NSString * const kDevelopPlatform = @"devplatform";
NSString * const kExpertise = @"expertise";
NSString * const kLocation = @"location";

NSString * const kTrueName = @"trueName";
NSString * const kSex = @"sex";
NSString * const kPhoneNumber = @"phoneNumber";
NSString * const kCorporation = @"corporation";
NSString * const kPosition = @"position";

NSString * const kTeamID = @"teamID";
NSString * const kTeamsArray = @"teams";


@implementation Config

+ (void)saveOwnAccount:(NSString *)account andPassword:(NSString *)password
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:account forKey:kAccount];
    [userDefaults synchronize];
    
    [SSKeychain setPassword:password forService:kService account:account];
}


#pragma mark - user profile

+ (void)saveProfile:(OSCUser *)user
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setInteger:user.userID forKey:kUserID];
    [userDefaults setObject:user.name forKey:kUserName];
    [userDefaults setURL:user.portraitURL forKey:kPortraitURL];
    [userDefaults setObject:@(user.score) forKey:kUserScore];
    [userDefaults setObject:@(user.favoriteCount) forKey:kFavoriteCount];
    [userDefaults setObject:@(user.fansCount)      forKey:kFanCount];
    [userDefaults setObject:@(user.followersCount) forKey:kFollowerCount];
    
    [userDefaults synchronize];
}

+ (void)updateProfile:(OSCUser *)user
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:user.name forKey:kUserName];
    [userDefaults setURL:user.portraitURL forKey:kPortraitURL];
    [userDefaults setObject:@(user.score) forKey:kUserScore];
    [userDefaults setObject:@(user.favoriteCount) forKey:kFavoriteCount];
    [userDefaults setObject:@(user.fansCount)      forKey:kFanCount];
    [userDefaults setObject:@(user.followersCount) forKey:kFollowerCount];
    
    [userDefaults setObject:user.joinTime forKey:kJoinTime];
    [userDefaults setObject:user.location forKey:kLocation];
    [userDefaults setObject:user.expertise forKey:kExpertise];
    [userDefaults setObject:user.developPlatform forKey:kDevelopPlatform];
    
    [userDefaults synchronize];
}

+ (void)clearProfile
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:@(0) forKey:kUserID];
    [userDefaults setObject:@"点击头像登录" forKey:kUserName];
    [userDefaults setObject:@(0) forKey:kUserScore];
    [userDefaults setObject:@(0) forKey:kFavoriteCount];
    [userDefaults setObject:@(0) forKey:kFanCount];
    [userDefaults setObject:@(0) forKey:kFollowerCount];
    
    [userDefaults synchronize];
}

+ (OSCUser *)myProfile
{
    OSCUser *user = [OSCUser new];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    user.userID = [userDefaults integerForKey:kUserID];
    user.name = [userDefaults objectForKey:kUserName];
    user.portraitURL = [userDefaults URLForKey:kPortraitURL];
    user.score = [[userDefaults objectForKey:kUserScore] intValue];
    user.favoriteCount = [[userDefaults objectForKey:kFavoriteCount] intValue];
    user.fansCount = [[userDefaults objectForKey:kFanCount] intValue];
    user.followersCount = [[userDefaults objectForKey:kFollowerCount] intValue];
    
    user.joinTime = [userDefaults objectForKey:kJoinTime];
    user.location = [userDefaults objectForKey:kLocation];
    user.expertise = [userDefaults objectForKey:kExpertise];
    user.developPlatform = [userDefaults objectForKey:kDevelopPlatform];
    
    if (!user.name) {
        user.name = @"点击头像登录";
    }
    
    return user;
}



+ (void)clearCookie
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"sessionCookies"];
}

+ (void)savePortrait:(UIImage *)portrait
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:UIImagePNGRepresentation(portrait) forKey:kPortrait];
    
    [userDefaults synchronize];
}

+ (void)saveName:(NSString *)actorName sex:(NSInteger)sex phoneNumber:(NSString *)phoneNumber corporation:(NSString *)corporation andPosition:(NSString *)position
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:actorName forKey:kTrueName];
    [userDefaults setObject:@(sex) forKey:kSex];
    [userDefaults setObject:phoneNumber forKey:kPhoneNumber];
    [userDefaults setObject:corporation forKey:kCorporation];
    [userDefaults setObject:position forKey:kPosition];
    [userDefaults synchronize];
}

+ (void)saveTweetText:(NSString *)tweetText forUser:(ino64_t)userID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *key = [NSString stringWithFormat:@"tweetTmp_%lld", userID];
    [userDefaults setObject:tweetText forKey:key];
    
    [userDefaults synchronize];
}


+ (NSArray *)getOwnAccountAndPassword
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *account = [userDefaults objectForKey:kAccount];
    NSString *password = [SSKeychain passwordForService:kService account:account];
    
    if (account) {return @[account, password];}
    return nil;
}

+ (int64_t)getOwnID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:kUserID];
}

+ (NSString *)getOwnUserName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefaults objectForKey:kUserName];
    if (userName) {return userName;}
    return @"";
}

+ (NSArray *)getActivitySignUpInfomation
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *name = [userDefaults objectForKey:kTrueName] ?: @"";
    NSNumber *sex = [userDefaults objectForKey:kSex] ?: @(0);
    NSString *phoneNumber = [userDefaults objectForKey:kPhoneNumber] ?: @"";
    NSString *corporation = [userDefaults objectForKey:kCorporation] ?: @"";
    NSString *position = [userDefaults objectForKey:kPosition] ?: @"";
    
    return @[name, sex, phoneNumber, corporation, position];
}

+ (UIImage *)getPortrait
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIImage *portrait = [UIImage imageWithData:[userDefaults objectForKey:kPortrait]];
    
    return portrait;
}

+ (NSString *)getTweetText
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *IdStr = [NSString stringWithFormat:@"tweetTmp_%lld", [Config getOwnID]];
    NSString *tweetText = [userDefaults objectForKey:IdStr];
    
    return tweetText;
}


#pragma mark - Team

+ (int)teamID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [[userDefaults objectForKey:kTeamID] intValue];
}

+ (void)setTeamID:(int)teamID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setValue:@(teamID) forKey:kTeamID];
    [userDefaults synchronize];
}






+ (void)removeTeamInfo
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults removeObjectForKey:kTeamID];
    [userDefaults removeObjectForKey:kTeamsArray];
}

//夜间状态
+ (void)saveWhetherNightMode:(BOOL)isNight
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:@(isNight) forKey:@"mode"];
    [userDefaults synchronize];
}
+ (BOOL)getMode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [[userDefaults objectForKey:@"mode"] boolValue];
}

@end
