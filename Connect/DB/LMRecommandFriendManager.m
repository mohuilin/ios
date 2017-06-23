//
//  LMRecommandFriendManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRecommandFriendManager.h"
#import "Protofile.pbobjc.h"
#import "LMFriendRecommandInfo.h"

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

    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo allObjects];
    for (LMFriendRecommandInfo *info in results) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm deleteObject:info];
        }];
    }
}

- (void)deleteRecommandFriendWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMFriendRecommandInfo *friendRequestInfo = [[LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ", address]] lastObject];
    if (friendRequestInfo) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm deleteObject:friendRequestInfo];
        }];
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
        LMFriendRecommandInfo *ramFriendInfo = [self changeToRamModel:accountInfo];
        if (ramFriendInfo.username.length > 0) {
            [addArray addObject:ramFriendInfo];
        }
    }
    if (addArray.count > 0) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm addOrUpdateObjectsFromArray:addArray];
        }];
    }
}

- (NSArray *)getRecommandFriendsWithPage:(int)page {
    if (page <= 0) {
        page = 1;
    }
    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo allObjects];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSInteger number = (page * 20);
    NSInteger previousNumber = (page - 1) * 20;
    if (results.count >= number) {

        for (NSInteger index = previousNumber; index < number; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
            AccountInfo *info = [self realmChangeToAccount:ramFriendInfo];
            [resultArray addObject:info];
        }

    } else {

        for (NSInteger index = previousNumber; index < results.count; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
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
    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ", address]];
    if (results.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)updateRecommandFriendStatus:(int32_t)status withAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
   LMFriendRecommandInfo *friendRequest = [[LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]] lastObject];
    [self executeRealmWithBlock:^{
       friendRequest.status = status;
    }];
}

- (NSArray *)getRecommandFriendsWithPage:(int)page withStatus:(int)status {
    if (page <= 0) {
        page = 1;
    }

    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"status = %d ", status]];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSInteger number = (page * 20);
    NSInteger previousNumber = (page - 1) * 20;
    if (results.count >= number) {

        for (NSInteger index = previousNumber; index < number; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
            AccountInfo *info = [self realmChangeToAccount:ramFriendInfo];
            [resultArray addObject:info];
        }

    } else {

        for (NSInteger index = previousNumber; index < results.count; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
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

- (LMFriendRecommandInfo *)changeToRamModel:(AccountInfo *)accountInfo {


    LMFriendRecommandInfo *ramFriendInfo = [[LMFriendRecommandInfo alloc] init];
    ramFriendInfo.username = accountInfo.username;
    ramFriendInfo.address = accountInfo.address;
    ramFriendInfo.avatar = accountInfo.avatar;
    ramFriendInfo.status = accountInfo.recommandStatus;
    ramFriendInfo.pubKey = accountInfo.pub_key;
    return ramFriendInfo;

}

- (AccountInfo *)realmChangeToAccount:(LMFriendRecommandInfo *)ramFriendInfo {

    AccountInfo *accountInfo = [[AccountInfo alloc] init];
    accountInfo.username = ramFriendInfo.username;
    accountInfo.address = ramFriendInfo.address;
    accountInfo.avatar = ramFriendInfo.avatar;
    accountInfo.recommandStatus = ramFriendInfo.status;
    accountInfo.pub_key = ramFriendInfo.pubKey;
    return accountInfo;
}
@end

