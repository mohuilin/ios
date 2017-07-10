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
@property(copy, nonatomic) NSString *groupName;
// group id
@property(copy, nonatomic) NSString *groupIdentifer;
// group ecdhkey
@property(copy, nonatomic) NSString *groupEcdhKey;
// isCommonGroup
@property BOOL isCommonGroup;
// isGroupVerify
@property BOOL isGroupVerify;
// isPublic
@property BOOL isPublic;
// avatarUrl
@property(copy, nonatomic) NSString *avatarUrl;
// groupSummary
@property(copy, nonatomic) NSString *summary;
// admin 
@property(strong, nonatomic) LMRamMemberInfo *admin;
@property(strong, nonatomic) RLMArray<LMRamMemberInfo *> <LMRamMemberInfo> *membersArray;

@end
