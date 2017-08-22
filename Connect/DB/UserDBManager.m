//
//  UserDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UserDBManager.h"
#import "MessageDBManager.h"
#import "RecentChatDBManager.h"
#import "BadgeNumberManager.h"
#import "LMContactAccountInfo.h"
#import "LMFriendRequestInfo.h"
#import "LMIMHelper.h"
#import "LMRecentChat.h"

static UserDBManager *manager = nil;

@implementation UserDBManager

+ (UserDBManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (void)tearDown {
    manager = nil;
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

- (void)saveUser:(AccountInfo *)user {
    if (!user) {
        return;
    }
    if (GJCFStringIsNull(user.pub_key) ||
            GJCFStringIsNull(user.address) ||
            GJCFStringIsNull(user.avatar) ||
            GJCFStringIsNull(user.username)) {
        return;
    }

    LMContactAccountInfo *realmModel = [[LMContactAccountInfo alloc] initWithNormalInfo:user];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:realmModel];
    }];
}

- (void)batchSaveUsers:(NSArray *)users {

    for (AccountInfo *user in users) {
        LMContactAccountInfo *realmModel = [[LMContactAccountInfo alloc] initWithNormalInfo:user];
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm addOrUpdateObject:realmModel];
        }];
    }
}

- (void)deleteUserBypubkey:(NSString *)pubKey {
    if (GJCFStringIsNull(pubKey)) {
        return;
    }
    //delet message
    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:pubKey];
    //delete chat
    [[RecentChatDBManager sharedManager] deleteByIdentifier:pubKey];
    //delete chat setting
    [[RecentChatDBManager sharedManager] deleteRecentChatSettingWithIdentifier:pubKey];
    //delete request
    [self deleteRequestUserByAddress:[LMIMHelper getAddressByPubkey:pubKey]];
    //delete user
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"pub_key = '%@'", pubKey]];
    if (results.firstObject) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:[results firstObject]];
        }];
    }
}

- (void)deleteUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    NSString *pubKey = [self getUserPubkeyByAddress:address];
    [self deleteUserBypubkey:pubKey];
}

- (void)updateUserNameAndAvatar:(AccountInfo *)user {
    if (GJCFStringIsNull(user.pub_key) ||
            GJCFStringIsNull(user.avatar) ||
            GJCFStringIsNull(user.username)) {
        return;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"pub_key = '%@'", user.pub_key]] firstObject];
    
    LMRecentChat *recent = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", user.pub_key]] firstObject];

    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        realmUser.avatar = user.avatar;
        realmUser.username = user.username;
        if (recent) {
            recent.headUrl = user.avatar;
            recent.name = user.username;
        }
    }];
}

- (void)setUserCommonContact:(BOOL)commonContact AndSetNewRemark:(NSString *)remark withAddress:(NSString *)address {
    if (GJCFStringIsNull(address) ||
        GJCFStringIsNull(remark)) {
        return;
    }
    
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    
    LMRecentChat *recent = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", realmUser.pub_key]] firstObject];
    
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        realmUser.remarks = remark;
        realmUser.isOffenContact = commonContact;
        if (recent) {
            recent.name = remark;
        }
    }];
}

- (AccountInfo *)getUserByPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return nil;
    }
    NSString *address = [LMIMHelper getAddressByPubkey:publickey];
    if ([publickey isEqualToString:kSystemIdendifier]) {
        address = @"Connect";
    }
    return [self getUserByAddress:address];
}

- (NSString *)getUserPubkeyByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    return realmUser.pub_key;
}

- (AccountInfo *)getUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    return realmUser.normalInfo;
}

- (RLMResults *)getRealmUsers {
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo allObjects];
    return results;
}

- (NSArray *)getAllUsers {
    NSMutableArray *modelArray = [NSMutableArray array];
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo allObjects];
    //model trasfer
    for (LMContactAccountInfo *realmModel in results) {
        AccountInfo *model = realmModel.normalInfo;
        [modelArray addObject:model];
    }
    return modelArray;
}

- (void)getAllUsersWithComplete:(void (^)(NSArray *))complete {
    if (complete) {
        [GCDQueue executeInGlobalQueue:^{
            complete([self getAllUsers]);
        }];
    }
}


- (void)getAllUsersNoConnectWithComplete:(void (^)(NSArray *))complete {
    if (complete) {
        NSMutableArray *modelArray = [NSMutableArray array];
        RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo objectsWhere:@"pub_key != 'connect'"];
        //model trasfer
        for (LMContactAccountInfo *realmModel in results) {
            AccountInfo *model = realmModel.normalInfo;
            [modelArray addObject:model];
        }
        complete(modelArray);
    }
}

- (BOOL)isFriendByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    return realmUser != nil;
}


- (long int)getRequestTimeByUserPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return 0;
    }

    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"pubKey = '%@'", publickey]] firstObject];
    return (long long) ([realmUser.createTime timeIntervalSince1970] * 1000);
}

- (NSString *)getRequestTipsByUserPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return 0;
    }

    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"pubKey = '%@'", publickey]] firstObject];
    return realmUser.tips;
}

- (NSArray *)getAllNewFirendRequest {
    NSMutableArray *modelArray = [NSMutableArray array];
    RLMResults <LMFriendRequestInfo *> *results = [LMFriendRequestInfo allObjects];
    //model trasfer
    for (LMFriendRequestInfo *realmModel in results) {
        AccountInfo *model = realmModel.normalInfo;
        [modelArray addObject:model];
    }
    return modelArray;
}
- (RLMResults *)getAllNewFriendResults {
    
    RLMResults <LMFriendRequestInfo *> *results = [LMFriendRequestInfo allObjects];
    return results;
}


- (AccountInfo *)getFriendRequestBy:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    return realmUser.normalInfo;
}

- (RequestFriendStatus)getFriendRequestStatusByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return RequestFriendStatusAdd;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    return realmUser.status;
}

- (void)deleteRequestUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    if (realmUser) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:realmUser];
        }];
    }
}

- (void)saveNewFriend:(AccountInfo *)user {
    if (!user) {
        return;
    }
    if (GJCFStringIsNull(user.pub_key) ||
            GJCFStringIsNull(user.address) ||
            GJCFStringIsNull(user.avatar) ||
            GJCFStringIsNull(user.username)) {
        return;
    }
    if (user.status == RequestFriendStatusAccept) {
        [[BadgeNumberManager shareManager] getBadgeNumber:ALTYPE_CategoryTwo_NewFriend Completion:^(BadgeNumber *badgeNumber) {
            if (!badgeNumber) {
                BadgeNumber *createBadge = [[BadgeNumber alloc] init];
                createBadge.type = ALTYPE_CategoryTwo_NewFriend;
                createBadge.count = 1;
                createBadge.displayMode = ALDisplayMode_Number;
                [[BadgeNumberManager shareManager] setBadgeNumber:createBadge Completion:^(BOOL result) {

                }];
            } else {
                badgeNumber.count++;
                [[BadgeNumberManager shareManager] setBadgeNumber:badgeNumber Completion:^(BOOL result) {

                }];
            }
        }];
    }

    //save to realm
    LMFriendRequestInfo *realmModel = [[LMFriendRequestInfo alloc] initWithNormalInfo:user];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:realmModel];
    }];
}

- (void)updateNewFriendStatusAddress:(NSString *)address withStatus:(int)status {
    if (GJCFStringIsNull(address)) {
        return;
    }
    if (status < 0) {
        status = 0;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    [self executeRealmWithBlock:^{
        realmUser.status = status;
    }];
}


- (NSArray *)getUserTags:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    NSMutableArray *tags = [NSMutableArray array];
    for (LMTag *realmModel in realmUser.tags) {
        if (realmModel.tag) {
            [tags addObject:realmModel.tag];
        }
    }
    return tags;
}

- (NSArray *)getTagUsers:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return nil;
    }
    return nil;
}


- (NSArray *)tagList {
    RLMResults <LMTag *> *results = [LMTag allObjects];
    NSMutableArray *tags = [NSMutableArray array];
    for (LMTag *realmTag in results) {
        if (realmTag.tag) {
            [tags addObject:realmTag.tag];
        }
    }
    return tags;
}

- (BOOL)saveTag:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return NO;
    }
    LMTag *realmTag = [[LMTag alloc] init];
    realmTag.tag = tag;
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:realmTag];
    }];

    return YES;
}

- (BOOL)removeTag:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return NO;
    }
    LMTag *realmModel = [[LMTag objectsWhere:[NSString stringWithFormat:@"tag = '%@'", tag]] firstObject];
    if (realmModel) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:realmModel];
        }];
    }
    return YES;
}

- (BOOL)saveAddress:(NSString *)address toTag:(NSString *)tag {
    if (GJCFStringIsNull(address) ||
            GJCFStringIsNull(tag)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];

    LMTag *realmModel = [[LMTag objectsWhere:[NSString stringWithFormat:@"tag = '%@'", tag]] firstObject];
    if (![realmModel.tag isEqualToString:tag]) {
        LMTag *realmTag = [LMTag new];
        realmTag.tag = tag;
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realmUser.tags addObject:realmTag];
        }];
    }
    return YES;
}

- (BOOL)removeAddress:(NSString *)address fromTag:(NSString *)tag {
    if (GJCFStringIsNull(address) ||
            GJCFStringIsNull(tag)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    LMTag *realmTag = [LMTag new];
    realmTag.tag = tag;
    NSInteger index = [realmUser.tags indexOfObject:realmTag];
    if (index != NSNotFound) {
        [self executeRealmWithBlock:^{
            [realmUser.tags removeObjectAtIndex:index];
        }];
    }

    return YES;
}


- (NSArray *)blackManList {
    NSMutableArray *modelArray = [NSMutableArray array];
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo objectsWhere:@"isBlackMan = 1"];
    //model trasfer
    for (LMContactAccountInfo *realmModel in results) {
        AccountInfo *model = realmModel.normalInfo;
        [modelArray addObject:model];
    }
    return modelArray;
}

- (void)addUserToBlackListWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    [self executeRealmWithBlock:^{
        realmUser.isBlackMan = YES;
    }];
}

- (void)removeUserFromBlackList:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }

    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    [self executeRealmWithBlock:^{
        realmUser.isBlackMan = NO;
    }];
}

- (BOOL)userIsInBlackList:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'", address]] firstObject];
    return realmUser.isBlackMan;
}

@end
