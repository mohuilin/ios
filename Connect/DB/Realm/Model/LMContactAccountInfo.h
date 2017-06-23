//
//  LMContactAccountInfo.h
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
#import "LMTag.h"

@interface LMContactAccountInfo : LMBaseModel

@property  NSString *address;
@property  NSString *pub_key;
@property  NSString *avatar;
@property  NSString *username;
@property  NSString *remarks;
@property  int source;
@property  BOOL isBlackMan;
@property  BOOL isOffenContact;

@property RLMArray<LMTag *><LMTag> *tags;

- (LMContactAccountInfo *)initWithAccountInfo:(AccountInfo *)info;

- (AccountInfo *)accountInfo;

@end

RLM_ARRAY_TYPE(LMContactAccountInfo)
