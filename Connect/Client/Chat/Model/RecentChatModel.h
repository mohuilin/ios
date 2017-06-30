//
//  RecentChatModel.h
//  Connect
//
//  Created by MoHuilin on 16/6/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseInfo.h"
#import "LMRamGroupInfo.h"

@interface RecentChatModel : BaseInfo

@property(nonatomic, strong) NSString *headUrl;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *content;

@property(nonatomic, strong) NSString *identifier;

@property(nonatomic, assign) BOOL isTopChat;
@property(nonatomic, assign) BOOL stranger;

@property(nonatomic, assign) int unReadCount;

@property(nonatomic, assign) int snapChatDeleteTime;

@property(nonatomic, assign) BOOL notifyStatus;

@property(nonatomic, strong) AccountInfo *chatUser;

@property(nonatomic, strong) LMRamGroupInfo *chatGroupInfo;

@property(nonatomic, assign) GJGCChatFriendTalkType talkType;

@property(nonatomic, copy) NSString *draft;

@property (nonatomic ,assign) BOOL groupNoteMyself;

@property (nonatomic ,copy) NSMutableAttributedString *contentAttrStr;


@property(nonatomic, strong) NSDate *createTime;

- (NSComparisonResult)comparedata:(RecentChatModel *)r2;

@end
