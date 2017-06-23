//
//  LMRamGroupInfo.h
//  Connect
//
//  Created by Connect on 2017/6/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
#import "LMRamMemberInfo.h"

@interface LMRamGroupInfo : LMBaseModel

// group name
@property NSString *groupName;
// group id
@property NSString *groupIdentifer;
// group ecdhkey
@property NSString *groupEcdhKey;
// isCommonGroup
@property BOOL isCommonGroup;
// isGroupVerify
@property BOOL isGroupVerify;
// isPublic
@property BOOL isPublic;
// avatarUrl
@property NSString *avatarUrl;
// groupSummary
@property NSString *summary;

@property LMRamMemberInfo *admin;

@property RLMArray<LMRamMemberInfo *> <LMRamMemberInfo> *membersArray;

@end
