//
//  LMFriendRequestInfo.h
//  Connect
//
//  Created by MoHuilin on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMFriendRequestInfo : LMBaseModel

@property (copy ,nonatomic) NSString *address;
@property (copy ,nonatomic) NSString *pubKey;
@property (copy ,nonatomic) NSString *avatar;
@property (copy ,nonatomic) NSString *username;
@property (assign ,nonatomic) int source;
@property (assign ,nonatomic) int status;
@property (assign ,nonatomic) int read;
@property (copy ,nonatomic) NSString *tips;

@property(strong ,nonatomic) NSDate *createTime;

@end

