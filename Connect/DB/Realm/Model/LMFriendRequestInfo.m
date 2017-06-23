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


- (LMBaseModel *)initWithNormalInfo:(id)info{
    if (self = [super init]) {
        if ([info isKindOfClass:[AccountInfo class]]) {
            AccountInfo *user = (AccountInfo *)info;
            self.address = user.address;
            self.pubKey = user.pub_key;
            self.avatar = user.avatar;
            self.username = user.username;
            self.source = user.source;
            self.status = user.status;
            self.read = user.requestRead;
            self.tips = user.message;
        }
    }
    return self;
}

- (id)normalInfo{
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
