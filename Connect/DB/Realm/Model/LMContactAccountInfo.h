//
//  LMContactAccountInfo.h
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMContactAccountInfo : LMBaseModel

@property  NSString *address;
@property  NSString *pub_key;
@property  NSString *avatar;
@property  NSString *username;
@property  NSString *remarks;
@property  int source;
@property  BOOL isBlackMan;
@property  BOOL isOffenContact;

@end
