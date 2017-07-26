//
//  LMRecentChat.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
#import "RecentChatModel.h"
#import "LMRecentChatSetting.h"

@interface LMRecentChat : LMBaseModel

@property (copy ,nonatomic) NSString *headUrl;
@property (copy ,nonatomic) NSString *name;
@property (copy ,nonatomic) NSString *content;
@property (copy ,nonatomic) NSString *identifier;
@property (copy ,nonatomic) NSString *draft;
@property (assign ,nonatomic) BOOL isTopChat;
@property (assign ,nonatomic) BOOL stranger;
@property (assign ,nonatomic) BOOL groupNoteMyself;
@property (assign ,nonatomic) int unReadCount;
@property (assign ,nonatomic) int talkType;
@property (nonatomic ,strong) NSDate *createTime;

@property(nonatomic, strong) LMRecentChatSetting *chatSetting;

@end
