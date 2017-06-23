//
//  LMRamMemberInfo.h
//  Connect
//
//  Created by Connect on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
@interface LMRamMemberInfo : LMBaseModel

@property  NSString *identifier;
@property  NSString *username;
@property  NSString *avatar;
@property  NSString *address;
@property  int roleInGroup;
@property  NSString *groupNicksName;
@property  NSString *pubKey;
@property  NSString *univerStr;

@property (readonly) RLMLinkingObjects *group;

@end

RLM_ARRAY_TYPE(LMRamMemberInfo)
