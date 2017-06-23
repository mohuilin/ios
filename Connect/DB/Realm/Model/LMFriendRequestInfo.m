//
//  LMFriendRequestInfo.m
//  Connect
//
//  Created by MoHuilin on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMFriendRequestInfo.h"

@implementation LMFriendRequestInfo

+(NSString *)primaryKey {
    return @"address";
}

+ (NSDictionary *)defaultPropertyValues{
    NSMutableDictionary *defaultValues = [super defaultPropertyValues].mutableCopy;
    if (defaultValues) {
        [defaultValues setObject:[NSDate date] forKey:@"createTime"];
        return defaultValues;
    } else{
        return @{@"createTime":[NSDate date]};
    }
}


- (LMFriendRequestInfo *)initWithAccountInfo:(AccountInfo *)info{
    if (self = [super init]) {
        self.address = info.address;
        self.pubKey = info.pub_key;
        self.avatar = info.avatar;
        self.username = info.username;
        self.source = info.source;
        self.status = info.status;
        self.read = info.requestRead;
        self.tips = info.message;
    }
    return self;
}

- (AccountInfo *)accountInfo{
    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.address = self.address;
    accountInfo.pub_key = self.pubKey;
    accountInfo.avatar = self.avatar;
    accountInfo.username = self.username;
    accountInfo.source = self.source;
    accountInfo.status = self.status;
    accountInfo.requestRead = self.read;
    accountInfo.message = self.tips;
    return accountInfo;
}


@end
