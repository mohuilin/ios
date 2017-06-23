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

- (LMContactAccountInfo *)initWithAccountInfo:(AccountInfo *)info{
    if (self = [super init]) {
        self.address = info.address;
        self.pub_key = info.pub_key;
        self.avatar = info.avatar;
        self.username = info.username;
        self.remarks = info.remarks;
        self.source = info.source;
        self.isBlackMan = info.isBlackMan;
        self.isOffenContact = info.isOffenContact;
        for (NSString *tag in info.tags) {
            LMTag *realmTag = [[LMTag alloc] init];
            realmTag.tag = tag;
            [self.tags addObject:realmTag];
        }
    }
    return self;
}

- (AccountInfo *)accountInfo{
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

