//
//  LMRecentChat.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRecentChat : LMBaseModel

@property NSString *headUrl;
@property NSString *name;
@property NSString *time;
@property NSString *content;
@property NSString *identifier;
@property NSString *draft;
@property BOOL isTopChat;
@property BOOL stranger;
@property BOOL notifyStatus;
@property BOOL groupNoteMyself;
@property int unReadCount;
@property int snapChatDeleteTime;
@property int talkType;

@end
