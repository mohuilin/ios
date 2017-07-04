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
/**
 * set group summary
 * @param textString
 * @param groupId
 */
- (void)updateGroupSummary:(NSString *)textString withGroupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    if (textString.length <= 0) {
        textString = @"";
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
        ramGroupInfo.summary = textString;
    }];
}
/**
 * add new member to group
 * @param newMembers
 * @param groupId
 * @return
 */
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
/**
 *  save group info
 * @param group
 */
- (void)savegroup:(LMRamGroupInfo *)group {

    if (GJCFStringIsNull(group.groupIdentifer)) {
        return;
    }
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
       [realm addOrUpdateObject:group];
    }];

}
/**
 * delete group info
 * @param groupId
 */
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
/**
 * get group summary
 * @param groupId
 * @return
 */
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
/**
 * remove member form group
 * @param address
 * @param groupId
 */
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
/**
 * updata some group member name
 * @param userName
 * @param address
 * @param groupId
 */
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
/**
 * updata some group member avatar
 * @param avatarUrl
 * @param address
 * @param groupId
 */
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
/**
 * updata some group member nickname
 * @param nickName
 * @param address
 * @param groupId
 */
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
/**
 * updata some group member role in group
 * @param role
 * @param address
 * @param groupId
 */
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
/**
 * update group name
 * @param name
 * @param groupId
 */
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
/**
 * update group name
 * @param name
 * @param groupId
 */
- (void)updateGroupName:(NSString *)name groupId:(NSString *)groupId {

    if (GJCFStringIsNull(name) || GJCFStringIsNull(groupId)) {
        return;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
       ramGroupInfo.groupName = name;
    }];
    
}
/**
 * update group avatar
 * @param avatarUrl
 * @param groupId
 */
- (void)updateGroupAvatarUrl:(NSString *)avatarUrl groupId:(NSString *)groupId {
    if (GJCFStringIsNull(avatarUrl) || GJCFStringIsNull(groupId)) {
        return;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupId]] lastObject];
    [self executeRealmWithBlock:^{
       ramGroupInfo.avatarUrl = avatarUrl;
    }];
    
}
/**
 * get group info
 * @param groupid
 * @return
 */
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
/**
 * check group is exists
 * @param groupid
 * @return
 */
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
/**
 * get group all memebers
 * @param groupid
 * @return
 */
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
/**
 * get group ecdh key
 * @param groupID
 * @return
 */
- (NSString *)getGroupEcdhKeyByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'", groupid]];
    LMRamGroupInfo *ramGroupInfo = [results lastObject];
    return ramGroupInfo.groupEcdhKey;
}
/**
 * get all group info
 * @return
 */
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
/**
 * get group is public
 * @param groupid
 * @return
 */
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
/**
 * async get all group info
 * @param complete
 */
- (void)getAllgroupsWithComplete:(void (^)(NSArray *groups))complete {
    [GCDQueue executeInGlobalQueue:^{
        NSArray *allGoup = [self getAllgroups];
        if (complete) {
            complete(allGoup);
        }

    }];
}
/**
 * realmCommonGroupList
 * @param nil
 * @param nil
 */
- (RLMResults *)realmCommonGroupList {
    
    RLMResults <LMRamGroupInfo *> *results = [LMRamGroupInfo objectsWhere:@"isCommonGroup == 1"];
    return results;
}
/**
 * get common group list
 * @return
 */
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
/**
 * get all commonGroup
 * @param nil
 * @param nil
 */
- (void)getCommonGroupListWithComplete:(void (^)(NSArray *CommonGroups))complete {
    [GCDQueue executeInGlobalQueue:^{
        NSArray *commonArray = [self commonGroupList];
        if (complete) {
            complete(commonArray);
        }
    }];
}
/**
 * updata group common status
 * @param groupid
 */
- (void)updateGroupStatus:(BOOL)flag groupId:(NSString *)groupId {
    if (GJCFStringIsNull(groupId)) {
        return;
    }
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupId]] lastObject];
    if (ramGroupInfo) {
        [self executeRealmWithBlock:^{
            ramGroupInfo.isCommonGroup = flag;
        }];
    }
}
/**
 * update group public statue
 * @param isPublic
 * @param groupid
 */
- (void)updateGroupPublic:(BOOL)isPublic groupId:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return;
    }

    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ",groupid]] lastObject];
    [self executeRealmWithBlock:^{
       ramGroupInfo.isPublic = isPublic;
    }];

}
/**
 * set group with new adminer
 * @param address
 * @param groupId
 */
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
/**
 * delete all group info
 */
- (void)removeAllGroup {
    RLMResults<LMRamGroupInfo *> *results = [LMRamGroupInfo allObjects];
    for (LMRamGroupInfo *ramGroup in results) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:ramGroup];
        }];
    }
}
/**
 * check group is common group
 * @param groupid
 * @return
 */
- (BOOL)isInCommonGroup:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return NO;
    }
    LMRamGroupInfo *ramGroupInfo = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@' ", groupid]] lastObject];
    return ramGroupInfo.isCommonGroup;
}
/**
 * get group adminer
 * @param groupId
 * @return
 */
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
/**
 * get group member
 * @param groupId
 * @param address
 * @return
 */
- (LMRamMemberInfo *)getGroupMemberByGroupId:(NSString *)groupId memberAddress:(NSString *)address {
    if (GJCFStringIsNull(groupId) || GJCFStringIsNull(address)) {
        return nil;
    }
    LMRamMemberInfo *info = [[LMRamMemberInfo objectsWhere:[NSString stringWithFormat:@"identifier = '%@' AND address ='%@' ", groupId, address]] lastObject];
    return info;

}
/**
 * check user is in group
 * @param groupId
 * @param address
 * @return
 */
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
/**
 * updata group base info
 * @param public_
 * @param reviewed
 * @param summary
 * @param avatar
 * @param groupId
 */
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
/**
 * check login user is group adminer
 * @param identifier
 * @return
 */
- (BOOL)checkLoginUserIsGroupAdminWithIdentifier:(NSString *)identifier {
    LMRamMemberInfo *admin = [self getAdminByGroupId:identifier];
    return [admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
}
@end
