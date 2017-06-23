//
//  GroupDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GroupDBManager.h"
#import "LMRamGroupInfo.h"
#import "LMRealmDBManager.h"
#import "LMRamMemberInfo.h"
#import "RLMRealm+LMRLMRealm.h"

static GroupDBManager *manager = nil;

@implementation GroupDBManager

+ (GroupDBManager *)sharedManager {
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

- (void)updateGroupSummary:(NSString *)textString withGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    if (textString == nil) {
        textString = @"";
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
        ramGroupInfo.summary = textString;
    }];
    
    
}

- (LMGroupInfo *)addMember:(NSArray *)newMembers ToGroupChat:(NSString *)groupId {

    if (GJCFStringIsNull(groupId) || newMembers.count <= 0) {
        return nil;
    }
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]];
    LMRamGroupInfo *ramGroupInfo = [results lastObject];
    ramGroupInfo.groupIdentifer = groupId;
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    for (AccountInfo *info in newMembers) {
        LMRamMemberInfo *ramInfo = [LMRamMemberInfo new];
        ramInfo.identifier = groupId;
        ramInfo.username = info.username;
        ramInfo.avatar = info.avatar;
        ramInfo.address = info.address;
        ramInfo.roleInGroup = info.roleInGroup;
        ramInfo.groupNicksName = info.groupNickName;
        ramInfo.pubKey = info.pub_key;
        if (ramInfo.roleInGroup == 1) {
            ramGroupInfo.admin = ramInfo;
        }
        ramInfo.univerStr = [[NSString stringWithFormat:@"%@%@",ramInfo.address,groupId] sha1String];
        [ramGroupInfo.membersArray addObject:ramInfo];
    }
    [realm beginWriteTransaction];
    [LMRamGroupInfo createInRealm:realm withValue:ramGroupInfo];
    [realm commitWriteTransaction];
    LMGroupInfo *groupInfo = [self ramModelToCommonModel:[results lastObject]];
    return groupInfo;

}

- (void)savegroup:(LMGroupInfo *)group {

    if (GJCFStringIsNull(group.groupIdentifer)) {
        return;
    }
    LMRamGroupInfo *ramGroupInfo = [self changeToRamModel:group];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
       [realm addOrUpdateObject:ramGroupInfo];
    }];
    

}
- (void)deletegroupWithGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }

    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]];
    if ([results lastObject]) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm deleteObject:[results lastObject]];
        }];
    }
  
}

- (NSString *)getGroupSummaryWithGroupID:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return nil;
    }

    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'",groupId]];
    LMRamGroupInfo *ramGroupInfo = [results firstObject];
    if (ramGroupInfo.summary.length <= 0) {
        return @"";
    }
    return ramGroupInfo.summary;
    
}

- (void)removeMemberWithAddress:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }

    RLMResults <LMRamMemberInfo *> *results = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@' ",groupId,address]];
    if ([results lastObject]) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:[results lastObject]];
        }];
    }
}

- (void)updateGroup:(LMGroupInfo *)group {
    if (GJCFStringIsNull(group.groupIdentifer)) {
        return;
    }

    RLMResults<LMRamMemberInfo *> *memberResult = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",group.groupIdentifer]];
    for (LMRamMemberInfo * info in memberResult) {
       [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm deleteObject:info];
       }];
    }
    LMRamGroupInfo *ramGroupInfo = [self changeToRamModel:group];
    ramGroupInfo.groupIdentifer = group.groupIdentifer;
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
       [realm addOrUpdateObject:ramGroupInfo];
    }];
    
}


- (void)updateGroupMembserUsername:(NSString *)userName address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'",groupId,address]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountInfos firstObject];
    if (ramAccountInfo) {
        [self executeRealmWithBlock:^{
            ramAccountInfo.username = userName;
        }];
    }
}

- (void)updateGroupMembserAvatarUrl:(NSString *)avatarUrl address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address) || GJCFStringIsNull(avatarUrl)) {
        return;
    }

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'",groupId,address]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountInfos firstObject];
    if (ramAccountInfo) {
       [self executeRealmWithBlock:^{
          ramAccountInfo.avatar = avatarUrl;
       }];
    }

    
}

- (void)updateGroupMembserNick:(NSString *)nickName address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'",groupId,address]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountInfos lastObject];
    if (ramAccountInfo) {
        [self executeRealmWithBlock:^{
             ramAccountInfo.groupNicksName = nickName;
        }];
    }

    
    
}

- (void)updateGroupMembserRole:(int)role address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'",groupId,address]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountInfos lastObject];
    if (ramAccountInfo) {
        [self executeRealmWithBlock:^{
           ramAccountInfo.roleInGroup = role;
        }];
    }
    
}
- (void)updateGroupName:(NSString *)name groupId:(NSString *)groupId {

    if (GJCFStringIsNull(name) || GJCFStringIsNull(groupId)) {
        return;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
       ramGroupInfo.groupName = name;
    }];
    
}

- (void)updateGroupAvatarUrl:(NSString *)avatarUrl groupId:(NSString *)groupId {
    if (GJCFStringIsNull(avatarUrl) || GJCFStringIsNull(groupId)) {
        return;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
       ramGroupInfo.avatarUrl = avatarUrl;
    }];
    
    
}


- (LMGroupInfo *)getGroupByGroupIdentifier:(NSString *)groupid {

    if (GJCFStringIsNull(groupid)) {
        return nil;
    }

     RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'",groupid]];
    if (results.count > 0) {
        LMRamGroupInfo *ramGroupInfo = [results lastObject];
        LMGroupInfo *groupInfo = [self ramModelToCommonModel:ramGroupInfo];
        return groupInfo;
    }
    return nil;
}

- (BOOL)groupInfoExisitByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupid]] lastObject];
    if (ramGroupInfo.groupIdentifer.length > 0) {
        return YES;
    }else {
        return NO;
    }
}


- (NSMutableArray *)getgroupMemberByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }

    NSString *selectName = [NSString stringWithFormat:@"identifier = %@",groupid];
    RLMResults<LMRamMemberInfo *> *ramAccountInfoResults = [LMRamMemberInfo objectsWhere:selectName];
    AccountInfo *admin = nil;
    NSMutableArray *mutableMembers = [NSMutableArray array];
    for (LMRamMemberInfo *ramAccountInfo in ramAccountInfoResults) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = ramAccountInfo.username;
        accountInfo.avatar = ramAccountInfo.avatar;
        accountInfo.address = ramAccountInfo.address;
        NSString *remark = ramAccountInfo.groupNicksName;
        if (GJCFStringIsNull(remark) || [remark isEqual:[NSNull null]]) {
            accountInfo.groupNickName = ramAccountInfo.username;
        } else {
            accountInfo.groupNickName = remark;
        }
        accountInfo.roleInGroup = ramAccountInfo.roleInGroup;
        accountInfo.pub_key = ramAccountInfo.pubKey;
        if (accountInfo.roleInGroup == 1) {
            admin = accountInfo;
            accountInfo.isGroupAdmin = YES;
        } else {
            [mutableMembers objectAddObject:accountInfo];
        }

    }
    if (admin) {
        [mutableMembers objectInsert:admin atIndex:0];
    }
    return mutableMembers;
    
    
}

- (NSString *)getGroupEcdhKeyByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'",groupid]];
    LMRamGroupInfo *ramGroupInfo = [results lastObject];
    return ramGroupInfo.groupEcdhKey;
}


- (NSArray *)getAllgroups {
    
    NSMutableArray *groupsArray = [NSMutableArray array];
    RLMResults<LMRamGroupInfo *> *ramGroupResult = [LMRamGroupInfo allObjects];
    if (ramGroupResult.count <= 0) {
        return nil;
    }
    for (LMRamGroupInfo *ramGroupInfo  in ramGroupResult) {
        LMGroupInfo *groupInfo = [self ramModelToCommonModel:ramGroupInfo];
        [groupsArray addObject:groupInfo];
    }
    return groupsArray; 
}

- (BOOL)isGroupPublic:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }
    RLMResults<LMRamGroupInfo *> *ramGroupInfoResult = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'",groupid]];
    if (ramGroupInfoResult.count > 0) {
        LMRamGroupInfo *ramGroupInfo = [ramGroupInfoResult lastObject];
        return ramGroupInfo.isPublic;
    }
    return NO;
}

- (void)getAllgroupsWithComplete:(void (^)(NSArray *groups))complete {
    [GCDQueue executeInGlobalQueue:^{
        NSArray *allGoup = [self getAllgroups];
        if (complete) {
            complete(allGoup);
        }

    }];
}


- (NSArray *)commonGroupList {

    RLMResults <LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:@"isCommonGroup == 1 "];
    if (results.count <= 0) {
        return nil;
    }
    NSMutableArray *groupArray = [NSMutableArray array];
    for (LMRamGroupInfo * ramGroupInfo in results) {
        LMGroupInfo *groupInfo = [self ramModelToCommonModel:ramGroupInfo];
        [groupArray addObject:groupInfo];
    }
    return groupArray.copy;

}

- (void)getCommonGroupListWithComplete:(void (^)(NSArray *CommonGroups))complete {
    [GCDQueue executeInGlobalQueue:^{
        NSArray *commonArray = [self commonGroupList];
        if (complete) {
            complete(commonArray);
        }
    }];
}

- (void)addGroupToCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }
   LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupid]] lastObject];
    if (ramGroupInfo) {
       [self executeRealmWithBlock:^{
          ramGroupInfo.isCommonGroup = YES;
       }];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectAddCommonGroupNotification, groupid);
    }];
}
- (void)updateGroupPublic:(BOOL)isPublic groupId:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupid]] lastObject];
    [self executeRealmWithBlock:^{
       ramGroupInfo.isPublic = isPublic;
    }];
    

}

- (void)setGroupNewAdmin:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || address.length <= 0) {
        return;
    }
    
    RLMResults <LMRamMemberInfo *> *ramAccoutResults = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND roleInGroup = 1",groupId]];
    LMRamMemberInfo *ramAccoutnInfo = [ramAccoutResults firstObject];
    [self executeRealmWithBlock:^{
       ramAccoutnInfo.roleInGroup = 0;
    }];
    //add new admin
    LMRamMemberInfo *ramNewAccount = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@' ",groupId,address]] lastObject];
    [self executeRealmWithBlock:^{
        ramNewAccount.roleInGroup = 1;
    }];
}

- (void)removeFromCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' AND isCommonGroup == 1 ",groupid]] lastObject];
    if (ramGroupInfo) {
        [self executeRealmWithBlock:^{
           ramGroupInfo.isCommonGroup = NO;
        }];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRemoveCommonGroupNotification, groupid);
    }];
    

}

- (void)removeAllGroup {
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo allObjects];
    for (LMRamGroupInfo *ramGroup in results) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:ramGroup];
        }];
    }
}

- (BOOL)isInCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupid]] lastObject];
    return ramGroupInfo.isCommonGroup;
}

- (AccountInfo *)getAdminByGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return nil;
    }
    RLMResults<LMRamMemberInfo *> *ramAccountResult = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND roleInGroup = 1 ",groupId]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountResult lastObject];
    if (ramAccountInfo) {
        AccountInfo *accountInfo = [AccountInfo new];
        accountInfo.username = ramAccountInfo.username;
        accountInfo.avatar = ramAccountInfo.avatar;
        accountInfo.address = ramAccountInfo.address;
        accountInfo.roleInGroup = 1;
        accountInfo.groupNickName = ramAccountInfo.groupNicksName;
        accountInfo.pub_key = ramAccountInfo.pubKey;
        return accountInfo;
    }
    return nil;
}


- (AccountInfo *)getGroupMemberByGroupId:(NSString *)groupId memberAddress:(NSString *)address {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return nil;
    }
   LMRamMemberInfo *info = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address ='%@' ",groupId,address]] lastObject];
    AccountInfo *accountInfo = [AccountInfo new];
    accountInfo.username = info.username;
    accountInfo.avatar = info.avatar;
    accountInfo.address = info.address;
    accountInfo.roleInGroup = info.roleInGroup;
    accountInfo.groupNickName = info.groupNicksName;
    accountInfo.pub_key = info.pubKey;
    return accountInfo;
    
}


- (BOOL)userWithAddress:(NSString *)address isinGroup:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return NO;
    }
    LMRamMemberInfo *info = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@' ",groupId,address]] lastObject];
    if (info.pubKey.length > 0) {
        return YES;
    }else {
        return NO;
    }
}

- (void)updateGroupPublic:(BOOL)public_ reviewed:(BOOL)reviewed summary:(NSString *)summary avatar:(NSString *)avatar withGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    if (ramGroupInfo) {
      [self executeRealmWithBlock:^{
          ramGroupInfo.avatarUrl = avatar;
          ramGroupInfo.isPublic = public_;
          ramGroupInfo.isGroupVerify = reviewed;
          ramGroupInfo.summary = summary;
      }];
    }
}

- (BOOL)checkLoginUserIsGroupAdminWithIdentifier:(NSString *)identifier {
    AccountInfo *admin = [self getAdminByGroupId:identifier];
    return [admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
}
#pragma mark private method 
- (LMRamGroupInfo *)changeToRamModel:(LMGroupInfo *)groupInfo {
    
    LMRamGroupInfo *ramGroup = [[LMRamGroupInfo alloc] init];
    ramGroup.groupIdentifer = groupInfo.groupIdentifer;
    ramGroup.groupName = groupInfo.groupName;
    ramGroup.groupEcdhKey = groupInfo.groupEcdhKey;
    ramGroup.isCommonGroup = groupInfo.isCommonGroup;
    ramGroup.isGroupVerify = groupInfo.isGroupVerify;
    ramGroup.isPublic = groupInfo.isPublic;
    ramGroup.avatarUrl = groupInfo.avatarUrl;
    ramGroup.summary = groupInfo.summary;
    NSMutableArray *memberArray = groupInfo.groupMembers;
    for (AccountInfo *info in memberArray) {
        LMRamMemberInfo *ramInfo = [LMRamMemberInfo new];
        ramInfo.identifier = ramGroup.groupIdentifer;
        ramInfo.username = info.username;
        ramInfo.avatar = info.avatar;
        ramInfo.address = info.address;
        ramInfo.roleInGroup = info.roleInGroup;
        ramInfo.groupNicksName = info.groupNickName;
        ramInfo.pubKey = info.pub_key;
        if (info.roleInGroup == 1) {
            ramGroup.admin = ramInfo;
        }
        ramInfo.univerStr = [[NSString stringWithFormat:@"%@%@",ramInfo.address,ramGroup.groupIdentifer] sha1String];
        [ramGroup.membersArray addObject:ramInfo];
    }
    return ramGroup;
}
- (LMGroupInfo *)ramModelToCommonModel:(LMRamGroupInfo *)ramGroupInfo {
    LMGroupInfo *groupInfo = [[LMGroupInfo alloc] init];
    groupInfo.groupIdentifer = ramGroupInfo.groupIdentifer;
    groupInfo.groupName = ramGroupInfo.groupName;
    groupInfo.groupEcdhKey = ramGroupInfo.groupEcdhKey;
    groupInfo.isCommonGroup = ramGroupInfo.isCommonGroup;
    groupInfo.isGroupVerify = ramGroupInfo.isGroupVerify;
    groupInfo.isPublic = ramGroupInfo.isPublic;
    groupInfo.avatarUrl = ramGroupInfo.avatarUrl;
    groupInfo.summary = ramGroupInfo.summary;
    NSMutableArray *temArray = [NSMutableArray array];
    RLMArray<LMRamMemberInfo *> *membersArray = ramGroupInfo.membersArray;
    for (LMRamMemberInfo *info in membersArray) {
        AccountInfo *accountInfo = [AccountInfo new];
        accountInfo.username = info.username;
        accountInfo.avatar = info.avatar;
        accountInfo.address = info.address;
        accountInfo.roleInGroup = info.roleInGroup;
        accountInfo.groupNickName = info.groupNicksName;
        accountInfo.pub_key = info.pubKey;
        if (info.roleInGroup == 1) {
            accountInfo.isGroupAdmin = YES;
            groupInfo.admin = accountInfo;
        }
        [temArray addObject:accountInfo];
    }
    groupInfo.groupMembers = temArray;
    return groupInfo;
}
@end
