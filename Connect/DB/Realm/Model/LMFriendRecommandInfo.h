//
//  LMFriendRecommandInfo.h
//  Connect
//
//  Created by Connect on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMFriendRecommandInfo : LMBaseModel

@property (copy ,nonatomic) NSString *address;
@property (copy ,nonatomic) NSString *pubKey;
@property (copy ,nonatomic) NSString *avatar;
@property (copy ,nonatomic) NSString *username;
@property (assign ,nonatomic) int status;

@end
