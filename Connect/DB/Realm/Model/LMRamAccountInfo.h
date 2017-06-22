//
//  LMRamAccountInfo.h
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
@class LMRamGroupInfo;
@interface LMRamAccountInfo : LMBaseModel

@property  NSString *identifier;
@property  NSString *username;
@property  NSString *avatar;
@property  NSString *address;
@property  int roleInGroup;
@property  NSString *groupNicksName;
@property  NSString *pubKey;
@property  BOOL isGroupAdmin;
@property  NSString *univerStr;
@property  LMRamAccountInfo *admin;

@end

RLM_ARRAY_TYPE(LMRamAccountInfo)
