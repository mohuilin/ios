//
//  LMRecentChat.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRecentChat : LMBaseModel

@property(nonatomic, copy) NSString *headUrl;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *time;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *draft;
@property(nonatomic, assign) BOOL isTopChat;
@property(nonatomic, assign) BOOL stranger;
@property(nonatomic, assign) BOOL notifyStatus;
@property(nonatomic ,assign) BOOL groupNoteMyself;
@property(nonatomic, assign) int unReadCount;
@property(nonatomic, assign) int snapChatDeleteTime;
@property(nonatomic, assign) int talkType;

@end
