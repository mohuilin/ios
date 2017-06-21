//
//  LMRamAccountInfo.h
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRamAccountInfo : LMBaseModel

@property (nonatomic ,copy) NSString *address;
@property (nonatomic ,copy) NSString *avatar;
@property (nonatomic ,copy) NSString *nick;
@property (nonatomic ,copy) NSString *username;
@property (nonatomic ,copy) NSString *remarks;
@property (nonatomic ,copy) NSString *groupNickName;
@property (nonatomic ,assign) int  roleInGroup;
@property (nonatomic ,assign) BOOL isGroupAdmin;
@property (nonatomic ,copy) NSString *pub_key;
@end
