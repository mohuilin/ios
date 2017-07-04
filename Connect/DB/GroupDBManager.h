//
//  GroupDBManager.h
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseDB.h"
#import "LMRamGroupInfo.h"


@interface GroupDBManager : BaseDB

+ (GroupDBManager *)sharedManager;

+ (void)tearDown;
/**
 * update group name
 * @param name
 * @param groupId
 */
- (BOOL)isGroupExist:(NSString *)groupId;
/**
 * update group name
 * @param name
 * @param groupId
 */
- (void)updateGroupName:(NSString *)name groupId:(NSString *)groupId;

/**
 * update group avatar
 * @param avatarUrl
 * @param groupId
 */
- (void)updateGroupAvatarUrl:(NSString *)avatarUrl groupId:(NSString *)groupId;

/**
 * set group summary
 * @param textString
 * @param groupId
 */
- (void)updateGroupSummary:(NSString *)textString withGroupId:(NSString *)groupId;

/**
 * update group public statue
 * @param isPublic
 * @param groupid
 */
- (void)updateGroupPublic:(BOOL)isPublic groupId:(NSString *)groupid;

/**
 * set group with new adminer
 * @param address
 * @param groupId
 */
- (void)setGroupNewAdmin:(NSString *)address groupId:(NSString *)groupId;

/**
 * get group ecdh key
 * @param groupID
 * @return
 */
- (NSString *)getGroupEcdhKeyByGroupIdentifier:(NSString *)groupID;

/**
 * get group summary
 * @param groupId
 * @return
 */
- (NSString *)getGroupSummaryWithGroupID:(NSString *)groupId;

/**
 * save group info
 * @param group
 */
- (void)savegroup:(LMRamGroupInfo *)group;

/**
 * get group info
 * @param groupid
 * @return
 */
- (LMRamGroupInfo *)getGroupByGroupIdentifier:(NSString *)groupid;

/**
 * get all group info
 * @return
 */
- (NSArray *)getAllgroups;

/**
 * get group is public
 * @param groupid
 * @return
 */
- (BOOL)isGroupPublic:(NSString *)groupid;

/**
 * get group adminer
 * @param groupId
 * @return
 */
- (LMRamMemberInfo *)getAdminByGroupId:(NSString *)groupId;


/**
 * delete group info
 * @param groupId
 */
- (void)deletegroupWithGroupId:(NSString *)groupId;

/**
 * delete all group info
 */
- (void)removeAllGroup;

/**
 * updata some group member name
 * @param userName
 * @param address
 * @param groupId
 */
- (void)updateGroupMembserUsername:(NSString *)userName address:(NSString *)address groupId:(NSString *)groupId;

/**
 * updata some group member avatar
 * @param avatarUrl
 * @param address
 * @param groupId
 */
- (void)updateGroupMembserAvatarUrl:(NSString *)avatarUrl address:(NSString *)address groupId:(NSString *)groupId;

/**
 * updata some group member nickname
 * @param nickName
 * @param address
 * @param groupId
 */
- (void)updateGroupMembserNick:(NSString *)nickName address:(NSString *)address groupId:(NSString *)groupId;

/**
 * updata some group member role in group
 * @param role
 * @param address
 * @param groupId
 */
- (void)updateGroupMembserRole:(int)role address:(NSString *)address groupId:(NSString *)groupId;

/**
 * get group all memebers
 * @param groupid
 * @return
 */
- (NSArray *)getgroupMemberByGroupIdentifier:(NSString *)groupid;

/**
 * add new member to group
 * @param newMembers
 * @param groupId
 * @return
 */
- (LMRamGroupInfo *)addMember:(NSArray *)newMembers ToGroupChat:(NSString *)groupId;

/**
 * remove member form group
 * @param address
 * @param groupId
 */
- (void)removeMemberWithAddress:(NSString *)address groupId:(NSString *)groupId;

/**
 * async get all group info
 * @param complete
 */
- (void)getAllgroupsWithComplete:(void (^)(NSArray *groups))complete;

- (RLMResults *)realmCommonGroupList;

- (void)getCommonGroupListWithComplete:(void (^)(NSArray *commonGroups))complete;

/**
 * get common group list
 * @return
 */
- (NSArray *)commonGroupList;

/**
 * add some group to common group
 * @param groupid
 */
- (void)addGroupToCommonGroup:(NSString *)groupid;

/**
 * remove group from common group
 * @param groupid
 */
- (void)removeFromCommonGroup:(NSString *)groupid;

/**
 * check group is common group
 * @param groupid
 * @return
 */
- (BOOL)isInCommonGroup:(NSString *)groupid;

/**
 * updata group base info
 * @param public_
 * @param reviewed
 * @param summary
 * @param avatar
 * @param groupId
 */
- (void)updateGroupPublic:(BOOL)public_ reviewed:(BOOL)reviewed summary:(NSString *)summary avatar:(NSString *)avatar withGroupId:(NSString *)groupId;

/**
 * check login user is group adminer
 * @param identifier
 * @return
 */
- (BOOL)checkLoginUserIsGroupAdminWithIdentifier:(NSString *)identifier;

/**
 * check group is exists
 * @param groupid
 * @return
 */
- (BOOL)groupInfoExisitByGroupIdentifier:(NSString *)groupid;

/**
 * get group member
 * @param groupId
 * @param address
 * @return
 */
- (LMRamMemberInfo *)getGroupMemberByGroupId:(NSString *)groupId memberAddress:(NSString *)address;

/**
 * check user is in group
 * @param groupId
 * @param address
 * @return
 */
- (BOOL)userWithAddress:(NSString *)address isinGroup:(NSString *)groupId;

@end
