//
//  LMContactAccountInfo.m
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMContactAccountInfo.h"

@implementation LMContactAccountInfo

+ (NSString *)primaryKey{
    return @"address";
}

- (LMBaseModel *)initWithNormalInfo:(id)info{
    if (self = [super init]) {
        if ([info isKindOfClass:[AccountInfo class]]) {
            AccountInfo *user = (AccountInfo *)info;
            self.address = user.address;
            self.pub_key = user.pub_key;
            self.avatar = user.avatar;
            self.username = user.username;
            self.remarks = user.remarks;
            self.source = user.source;
            self.isBlackMan = user.isBlackMan;
            self.isOffenContact = user.isOffenContact;
            for (NSString *tag in user.tags) {
                LMTag *realmTag = [[LMTag alloc] init];
                realmTag.tag = tag;
                [self.tags addObject:realmTag];
            }
        }
    }
    return self;
}

- (id)normalInfo{
    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.address = self.address;
    accountInfo.pub_key = self.pub_key;
    accountInfo.avatar = self.avatar;
    accountInfo.username = self.username;
    accountInfo.remarks = self.remarks;
    accountInfo.source = self.source;
    accountInfo.isBlackMan = self.isBlackMan;
    accountInfo.isOffenContact = self.isOffenContact;
    NSMutableArray *tags = [NSMutableArray array];
    for (LMTag *realmTag in self.tags) {
        if (realmTag.tag) {
            [tags addObject:realmTag.tag];
        }
    }
    accountInfo.tags = tags;
    return accountInfo;
}

@end

