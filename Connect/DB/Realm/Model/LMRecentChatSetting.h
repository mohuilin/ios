//
//  LMRecentChatSetting.h
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRecentChatSetting : LMBaseModel

@property NSString *identifier;
@property BOOL notifyStatus;
@property int snapChatDeleteTime;

@end
