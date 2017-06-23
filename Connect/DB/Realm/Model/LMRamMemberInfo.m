//
//  LMRamMemberInfo.m
//  Connect
//
//  Created by Connect on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//
#import "LMRamMemberInfo.h"
#import "LMRamGroupInfo.h"

@implementation LMRamMemberInfo

+ (NSString *)primaryKey {
    return @"univerStr";
}

+ (NSDictionary<NSString *, RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{
            @"group": [RLMPropertyDescriptor descriptorWithClass:LMRamGroupInfo.class propertyName:@"membersArray"],
    };
}
- (LMBaseModel *)initWithNormalInfo:(BaseInfo *)accountInfos {
    if (self = [super init]) {
        if ([accountInfos isKindOfClass:[AccountInfo class]]) {
            
            AccountInfo *info = (AccountInfo *)accountInfos;
            self.username = info.username;
            self.avatar = info.avatar;
            self.address = info.address;
            self.isGroupAdmin = info.isGroupAdmin;
            self.groupNicksName = info.groupNickName;
            self.pubKey = info.pub_key;
            
        }
    }
    return self;
}
- (BaseInfo *)normalInfo {
    
    AccountInfo *accountInfo = [AccountInfo new];
    accountInfo.username = self.username;
    accountInfo.avatar = self.avatar;
    accountInfo.address = self.address;
    accountInfo.isGroupAdmin = self.isGroupAdmin;
    accountInfo.groupNickName = self.groupNicksName;
    accountInfo.pub_key = self.pubKey;
    if (self.isGroupAdmin) {
        accountInfo.roleInGroup = 1;
    }else {
        accountInfo.roleInGroup = 0;
    }
    return accountInfo;
}
@end
