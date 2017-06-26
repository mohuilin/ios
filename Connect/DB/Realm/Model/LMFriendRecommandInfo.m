//
//  LMFriendRecommandInfo.m
//  Connect
//
//  Created by Connect on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMFriendRecommandInfo.h"

@implementation LMFriendRecommandInfo

+ (NSString *)primaryKey {
    return @"address";
}
- (LMBaseModel *)initWithNormalInfo:(id)info {
    if (self == [super init]) {
        if ([info isKindOfClass:[AccountInfo class]]) {
            AccountInfo *accountInfo = (AccountInfo *)info;
            self.username = accountInfo.username;
            self.address = accountInfo.address;
            self.avatar = accountInfo.avatar;
            self.status = accountInfo.recommandStatus;
            self.pubKey = accountInfo.pub_key;
        }
        
    }
    return self;
}
- (id)normalInfo {
    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.username = self.username;
    accountInfo.address = self.address;
    accountInfo.avatar = self.avatar;
    accountInfo.recommandStatus = self.status;
    accountInfo.pub_key = self.pubKey;
    return accountInfo;

}
@end
