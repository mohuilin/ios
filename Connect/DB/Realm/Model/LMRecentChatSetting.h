//
//  LMRecentChatSetting.h
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRecentChatSetting : LMBaseModel

@property (copy ,nonatomic) NSString *identifier;
@property (assign ,nonatomic) BOOL notifyStatus;
@property (assign ,nonatomic) int snapChatDeleteTime;

@end
