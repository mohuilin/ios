//
//  LMRecommandFriendManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRecommandFriendManager.h"
#import "Protofile.pbobjc.h"
#import "LMFriendRequestInfo.h"

#define RecommandFriendTable @"t_recommand_friend"
#define Scope @"username",@"address",@"avatar",@"pub_key",@"status"

@interface LMRecommandFriendManager ()


@end

static LMRecommandFriendManager *manager = nil;

@implementation LMRecommandFriendManager

+ (LMRecommandFriendManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}

+ (void)tearDown {
    manager = nil;
}

- (void)deleteAllRecommandFriend; {

    RLMResults<LMFriendRequestInfo *> *results = [LMFriendRequestInfo allObjects];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    for (LMFriendRequestInfo *info in results) {
        [realm beginWriteTransaction];
        [realm deleteObject:info];
        [realm commitWriteTransaction];
    }
}

- (void)deleteRecommandFriendWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
   LMFriendRequestInfo *friendRequestInfo = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]] lastObject];
    if (friendRequestInfo) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm deleteObject:friendRequestInfo];
        [realm commitWriteTransaction];
    }
}

- (void)saveRecommandFriend:(NSArray *)friendArray; {
    if (friendArray.count <= 0) {
        return;
    }
    NSMutableArray *addArray = [NSMutableArray array];
    for (UserInfo *user in friendArray) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = user.username;
        accountInfo.address = user.address;
        accountInfo.avatar = user.avatar;
        accountInfo.pub_key = user.pubKey;
        accountInfo.recommandStatus = 1;
        LMFriendRequestInfo *ramFriendInfo = [self changeToRamModel:accountInfo];
        if (ramFriendInfo.username.length > 0) {
            [addArray addObject:ramFriendInfo];
        }
    }
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    if (addArray.count > 0) {
        [realm beginWriteTransaction];
        [realm addOrUpdateObjectsFromArray:addArray];
        [realm commitWriteTransaction];
    }
}

- (NSArray *)getRecommandFriendsWithPage:(int)page {
    if (page <= 0) {
        page = 1;
    }
    RLMResults<LMFriendRequestInfo *> *results = [LMFriendRequestInfo allObjects];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSInteger number = (page * 20);
    NSInteger previousNumber = (page - 1) * 20;
    if (results.count >= number) {
        
        for (NSInteger index = previousNumber; index < number; index ++) {
            LMFriendRequestInfo *ramFriendInfo = results[index];
            AccountInfo *info = [self realmChangeToAccount:ramFriendInfo];
            [resultArray addObject:info];
        }
        
    }else {
        
        for (NSInteger index = previousNumber; index < results.count; index ++) {
            LMFriendRequestInfo *ramFriendInfo = results[index];
            AccountInfo *info = [self realmChangeToAccount:ramFriendInfo];
            [resultArray addObject:info];
        }
        
    }
    if (resultArray.count > 0) {
        NSArray *result = resultArray.copy;
        result = [result sortedArrayUsingComparator:^NSComparisonResult(AccountInfo *obj1, AccountInfo *obj2) {
            return [obj2.pub_key compare:obj1.pub_key];
        }];
        return result;
    }
    return nil;
}
- (BOOL)isExistUser:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    RLMResults<LMFriendRequestInfo *> *results = [LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]];
    if (results.count > 0) {
        return YES;
    }else {
        return NO;
    }

}

- (void)updateRecommandFriendStatus:(int32_t)status withAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
   LMFriendRequestInfo *friendRequest = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]] lastObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    friendRequest.status = status;
    [realm commitWriteTransaction];
}

- (NSArray *)getRecommandFriendsWithPage:(int)page withStatus:(int)status {
    if (page <= 0) {
        page = 1;
    }
    
    RLMResults<LMFriendRequestInfo *> *results = [LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"status = %d ",status]];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSInteger number = (page * 20);
    NSInteger previousNumber = (page - 1) * 20;
    if (results.count >= number) {
        
        for (NSInteger index = previousNumber; index < number; index ++) {
            LMFriendRequestInfo *ramFriendInfo = results[index];
            AccountInfo *info = [self realmChangeToAccount:ramFriendInfo];
            [resultArray addObject:info];
        }
        
    }else {
        
        for (NSInteger index = previousNumber; index < results.count; index ++) {
            LMFriendRequestInfo *ramFriendInfo = results[index];
            AccountInfo *info = [self realmChangeToAccount:ramFriendInfo];
            [resultArray addObject:info];
        }
        
    }
    if (resultArray.count > 0) {
        NSArray *result = resultArray.copy;
        result = [result sortedArrayUsingComparator:^NSComparisonResult(AccountInfo *obj1, AccountInfo *obj2) {
            return [obj2.pub_key compare:obj1.pub_key];
        }];
        return result;
    }
    return nil;
    
}
- (LMFriendRequestInfo *)changeToRamModel:(AccountInfo *)accountInfo {
    
    
    LMFriendRequestInfo *ramFriendInfo = [[LMFriendRequestInfo alloc] init];
    ramFriendInfo.username = accountInfo.username;
    ramFriendInfo.address = accountInfo.address;
    ramFriendInfo.avatar = accountInfo.avatar;
    ramFriendInfo.status = accountInfo.recommandStatus;
    ramFriendInfo.source = accountInfo.source;
    return ramFriendInfo;
    
}
- (AccountInfo *)realmChangeToAccount:(LMFriendRequestInfo *)ramFriendInfo {
    
    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.username = ramFriendInfo.username;
    accountInfo.address = ramFriendInfo.address;
    accountInfo.avatar = ramFriendInfo.avatar;
    accountInfo.recommandStatus = ramFriendInfo.status;
    accountInfo.source = ramFriendInfo.source;
    return accountInfo;
}
@end

