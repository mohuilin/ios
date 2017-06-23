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

#define ContactTable @"t_contact"
#define NewFriendTable @"t_friendrequest"
#define TagsTable @"t_tag"

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

    LMContactAccountInfo *realmModel = [[LMContactAccountInfo alloc] initWithAccountInfo:user];
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:realmModel];
    [realm commitWriteTransaction];
}

- (void)batchSaveUsers:(NSArray *)users {

    NSMutableArray *bitchRealmModel = [NSMutableArray array];
    for (AccountInfo *user in users) {
        LMContactAccountInfo *realmModel = [[LMContactAccountInfo alloc] initWithAccountInfo:user];
        [bitchRealmModel addObject:realmModel];
    }
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObjectsFromArray:bitchRealmModel];
    [realm commitWriteTransaction];
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
    [self deleteRequestUserByAddress:[KeyHandle getAddressByPubkey:pubKey]];
    //delete user
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"pub_key = '%@'",pubKey]];
    if (results.firstObject) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm deleteObject:[results firstObject]];
        [realm commitWriteTransaction];
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
    
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"pub_key = '%@'",user.pub_key]] firstObject];

    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmUser.avatar = user.avatar;
    realmUser.username = user.username;
    [realm commitWriteTransaction];
}

- (void)setUserCommonContact:(BOOL)commonContact AndSetNewRemark:(NSString *)remark withAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    if (!remark) {
        remark = @"";
    }
    
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmUser.remarks = remark;
    realmUser.isOffenContact = commonContact;
    [realm commitWriteTransaction];
}

- (AccountInfo *)getUserByPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return nil;
    }
    NSString *address = [KeyHandle getAddressByPubkey:publickey];
    if ([publickey isEqualToString:kSystemIdendifier]) {
        address = @"Connect";
    }
    return [self getUserByAddress:address];
}

- (NSString *)getUserPubkeyByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    return realmUser.pub_key;
}

- (AccountInfo *)getUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    return realmUser.accountInfo;
}

- (NSArray *)getAllUsers {
    NSMutableArray *modelArray = [NSMutableArray array];
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo allObjects];
    //model trasfer
    for (LMContactAccountInfo *realmModel in results) {
        AccountInfo *model = [realmModel accountInfo];
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
            AccountInfo *model = [realmModel accountInfo];
            [modelArray addObject:model];
        }
        complete(modelArray);
    }
}

- (BOOL)isFriendByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    return realmUser != nil;
}


- (long int)getRequestTimeByUserPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return 0;
    }
    
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"pubKey = '%@'",publickey]] firstObject];
    return (long long)([realmUser.createTime timeIntervalSince1970] * 1000);
}

- (NSString *)getRequestTipsByUserPublickey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return 0;
    }
    
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"pubKey = '%@'",publickey]] firstObject];
    return realmUser.tips;
}

- (NSArray *)getAllNewFirendRequest {
    NSMutableArray *modelArray = [NSMutableArray array];
    RLMResults <LMFriendRequestInfo *> *results = [LMFriendRequestInfo allObjects];
    //model trasfer
    for (LMFriendRequestInfo *realmModel in results) {
        AccountInfo *model = [realmModel accountInfo];
        [modelArray addObject:model];
    }
    return modelArray;
}

- (AccountInfo *)getFriendRequestBy:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    return realmUser.accountInfo;
}

- (RequestFriendStatus)getFriendRequestStatusByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return RequestFriendStatusAdd;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    return realmUser.status;
}

- (void)deleteRequestUserByAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm deleteObject:realmUser];
    [realm commitWriteTransaction];
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
    LMFriendRequestInfo *realmModel = [[LMFriendRequestInfo alloc] initWithAccountInfo:user];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:realmModel];
    [realm commitWriteTransaction];
}

- (void)updateNewFriendStatusAddress:(NSString *)address withStatus:(int)status {
    if (GJCFStringIsNull(address)) {
        return;
    }
    if (status < 0) {
        status = 0;
    }
    LMFriendRequestInfo *realmUser = [[LMFriendRequestInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmUser.status = status;
    [realm commitWriteTransaction];
}


- (NSArray *)getUserTags:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return nil;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
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
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:realmTag];
    [realm commitWriteTransaction];
    
    return YES;
}

- (BOOL)removeTag:(NSString *)tag {
    if (GJCFStringIsNull(tag)) {
        return NO;
    }
    LMTag *realmModel = [[LMTag objectsWhere:[NSString stringWithFormat:@"tag = '%@'",tag]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm deleteObject:realmModel];
    [realm commitWriteTransaction];
    return YES;
}

- (BOOL)saveAddress:(NSString *)address toTag:(NSString *)tag {
    if (GJCFStringIsNull(address) ||
        GJCFStringIsNull(tag)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    
    LMTag *realmModel = [[LMTag objectsWhere:[NSString stringWithFormat:@"tag = '%@'",tag]] firstObject];
    if (![realmModel.tag isEqualToString:tag]) {
        LMTag *realmTag = [LMTag new];
        realmTag.tag = tag;
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realmUser.tags addObject:realmTag];
        [realm commitWriteTransaction];
    }
    return YES;
}

- (BOOL)removeAddress:(NSString *)address fromTag:(NSString *)tag {
    if (GJCFStringIsNull(address) ||
        GJCFStringIsNull(tag)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    LMTag *realmTag = [LMTag new];
    realmTag.tag = tag;
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    NSInteger index = [realmUser.tags indexOfObject:realmTag];
    if (index != NSNotFound) {
        [realm beginWriteTransaction];
        [realmUser.tags removeObjectAtIndex:index];
        [realm commitWriteTransaction];
    }
    
    return YES;
}


- (NSArray *)blackManList {
    NSMutableArray *modelArray = [NSMutableArray array];
    RLMResults <LMContactAccountInfo *> *results = [LMContactAccountInfo objectsWhere:@"isBlackMan = 1"];
    //model trasfer
    for (LMContactAccountInfo *realmModel in results) {
        AccountInfo *model = [realmModel accountInfo];
        [modelArray addObject:model];
    }
    return modelArray;
}

- (void)addUserToBlackListWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmUser.isBlackMan = YES;
    [realm commitWriteTransaction];
}

- (void)removeUserFromBlackList:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }

    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmUser.isBlackMan = NO;
    [realm commitWriteTransaction];
}

- (BOOL)userIsInBlackList:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    LMContactAccountInfo *realmUser = [[LMContactAccountInfo objectsWhere:[NSString stringWithFormat:@"address = '%@'",address]] firstObject];
    return realmUser.isBlackMan;
}

@end
