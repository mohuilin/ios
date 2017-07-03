//
//  GroupDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GroupDBManager.h"


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

- (LMRamGroupInfo *)addMember:(NSArray *)newMembers ToGroupChat:(NSString *)groupId {

    if (GJCFStringIsNull(groupId) || newMembers.count <= 0) {
        return nil;
    }
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupId]];
    LMRamGroupInfo *ramGroupInfo = [results lastObject];
    ramGroupInfo.groupIdentifer = groupId;
    for (LMRamMemberInfo *ramInfo in newMembers) {
        ramInfo.identifier = groupId;
        if (ramInfo.isGroupAdmin) {
            ramGroupInfo.admin = ramInfo;
        }
        ramInfo.univerStr = [[NSString stringWithFormat:@"%@%@", ramInfo.address, groupId] sha1String];
        [ramGroupInfo.membersArray addObject:ramInfo];
    }
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:ramGroupInfo];
    }];
    return ramGroupInfo;

}

- (void)savegroup:(LMRamGroupInfo *)group {

    if (GJCFStringIsNull(group.groupIdentifer)) {
        return;
    }
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
       [realm addOrUpdateObject:group];
    }];

}

- (void)deletegroupWithGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }

    LMRamGroupInfo *groupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupId]] lastObject];
    if (groupInfo) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm deleteObject:groupInfo];
        }];
    }

}

- (NSString *)getGroupSummaryWithGroupID:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return nil;
    }

    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'", groupId]];
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

    LMRamMemberInfo *memberInfo = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@' ", groupId, address]] lastObject];
    if (memberInfo) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:memberInfo];
        }];
    }
}
- (void)updateGroupMembserUsername:(NSString *)userName address:(NSString *)address groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return;
    }

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'", groupId, address]];
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

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'", groupId, address]];
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

    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'", groupId, address]];
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
    BOOL flag = (role != 0);
    RLMResults<LMRamMemberInfo *> *ramAccountInfos = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@'", groupId, address]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountInfos lastObject];
    if (ramAccountInfo) {
        [self executeRealmWithBlock:^{
           ramAccountInfo.isGroupAdmin = flag;
        }];
    }

}
- (BOOL)isGroupExist:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return NO;
    }
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]];
    if (results.count >0) {
        return YES;
    }
    return NO;
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


- (LMRamGroupInfo *)getGroupByGroupIdentifier:(NSString *)groupid {

    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'", groupid]];
    if (results.count > 0) {
        LMRamGroupInfo *ramGroupInfo = [results lastObject];
        LMRamMemberInfo *admin = [ramGroupInfo.membersArray firstObject];
        if (!admin.isGroupAdmin) {
            //move
            for (LMRamMemberInfo *member in ramGroupInfo.membersArray) {
                if (member.isGroupAdmin) {
                    admin = member;
                    break;
                }
            }
            if (admin) {
                NSInteger index = [ramGroupInfo.membersArray indexOfObject:admin];
                if (index != NSNotFound) {
                    [self executeRealmWithBlock:^{
                        [ramGroupInfo.membersArray moveObjectAtIndex:index toIndex:0];
                    }];
                }
            }
        }
        return ramGroupInfo;
    }
    return nil;
}

- (BOOL)groupInfoExisitByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupid]] lastObject];
    if (ramGroupInfo.groupIdentifer.length > 0) {
        return YES;
    } else {
        return NO;
    }
}


- (NSMutableArray *)getgroupMemberByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    RLMResults<LMRamMemberInfo *> *ramAccountInfoResults = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' ", groupid]];
    AccountInfo *admin = nil;
    NSMutableArray *mutableMembers = [NSMutableArray array];
    for (LMRamMemberInfo *ramAccountInfo in ramAccountInfoResults) {
        AccountInfo *accountInfo = (AccountInfo *)ramAccountInfo.normalInfo;
        NSString *remark = ramAccountInfo.groupNicksName;
        if (GJCFStringIsNull(remark) || [remark isEqual:[NSNull null]]) {
            accountInfo.groupNickName = ramAccountInfo.username;
        } else {
            accountInfo.groupNickName = remark;
        }
        if (accountInfo.isGroupAdmin) {
            admin = accountInfo;
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
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'", groupid]];
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
        [groupsArray addObject:ramGroupInfo];
    }
    return groupsArray;
}

- (BOOL)isGroupPublic:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }
    RLMResults<LMRamGroupInfo *> *ramGroupInfoResult = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'", groupid]];
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


- (RLMResults *)realmCommonGroupList {
    
    RLMResults <LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:@"isCommonGroup == 1"];
    return results;
}

- (NSArray *)commonGroupList {

    RLMResults <LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:@"isCommonGroup == 1"];
    if (results.count <= 0) {
        return nil;
    }
    NSMutableArray *groupArray = [NSMutableArray array];
    for (LMRamGroupInfo *ramGroupInfo in results) {
        [groupArray addObject:ramGroupInfo];
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
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupid]] lastObject];
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
    LMRamGroupInfo *groupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
        LMRamMemberInfo *admin = nil;
        for (LMRamMemberInfo *member in groupInfo.membersArray) {
            if ([member.address isEqualToString:address]) {
                admin = member;
                admin.isGroupAdmin = YES;
            } else {
                member.isGroupAdmin = NO;
            }
        }
        if (admin) {
            NSInteger adminIndex = [groupInfo.membersArray indexOfObject:admin];
            [groupInfo.membersArray moveObjectAtIndex:adminIndex toIndex:0];
            groupInfo.admin = admin;
        }
    }];
}

- (void)removeFromCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' AND isCommonGroup == 1 ", groupid]] lastObject];
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
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupid]] lastObject];
    return ramGroupInfo.isCommonGroup;
}

- (LMRamMemberInfo *)getAdminByGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return nil;
    }
    RLMResults<LMRamMemberInfo *> *ramAccountResult = [LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND isGroupAdmin == 1 ",groupId]];
    LMRamMemberInfo *ramAccountInfo = [ramAccountResult lastObject];
    if (ramAccountInfo) {
        return ramAccountInfo;
    }
    return nil;
}


- (LMRamMemberInfo *)getGroupMemberByGroupId:(NSString *)groupId memberAddress:(NSString *)address {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return nil;
    }
    LMRamMemberInfo *info = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address ='%@' ", groupId, address]] lastObject];
    return info;

}


- (BOOL)userWithAddress:(NSString *)address isinGroup:(NSString *)groupId {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return NO;
    }
    LMRamMemberInfo *info = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address = '%@' ", groupId, address]] lastObject];
    if (info.pubKey.length > 0) {
        return YES;
    } else {
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
    LMRamMemberInfo *admin = [self getAdminByGroupId:identifier];
    return [admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
}
@end
