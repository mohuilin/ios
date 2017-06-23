//
//  LMFriendRequestInfo.h
//  Connect
//
//  Created by MoHuilin on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMFriendRequestInfo : LMBaseModel

@property  NSString *address;
@property  NSString *pubKey;
@property  NSString *avatar;
@property  NSString *username;
@property  int source;
@property  int status;
@property  int read;
@property  NSString *tips;

@property (nonatomic ,assign) NSDate *createTime;

@end

