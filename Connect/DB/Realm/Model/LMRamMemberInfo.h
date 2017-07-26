//
//  LMRamMemberInfo.h
//  Connect
//
//  Created by Connect on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRamMemberInfo : LMBaseModel

@property (copy ,nonatomic) NSString *identifier;
@property (copy ,nonatomic) NSString *username;
@property (copy ,nonatomic) NSString *avatar;
@property (copy ,nonatomic) NSString *address;
@property (assign ,nonatomic) BOOL isGroupAdmin;
@property (copy ,nonatomic) NSString *groupNicksName;
@property (copy ,nonatomic) NSString *pubKey;
@property (copy ,nonatomic) NSString *univerStr;

@property(readonly) RLMLinkingObjects *group;

@end

RLM_ARRAY_TYPE(LMRamMemberInfo)
