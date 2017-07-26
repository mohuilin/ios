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

@property (copy ,nonatomic) NSString *address;
@property (copy ,nonatomic) NSString *pub_key;
@property (copy ,nonatomic) NSString *avatar;
@property (copy ,nonatomic) NSString *username;
@property (copy ,nonatomic) NSString *remarks;
@property (assign ,nonatomic) int source;
@property (assign ,nonatomic) BOOL isBlackMan;
@property (assign ,nonatomic) BOOL isOffenContact;

@property RLMArray<LMTag *> <LMTag> *tags;

@end

RLM_ARRAY_TYPE(LMContactAccountInfo)
