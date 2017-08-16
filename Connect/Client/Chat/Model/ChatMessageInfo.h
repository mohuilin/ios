//
//  ChatMessageInfo.h
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendConstans.h"

@interface ChatMessageInfo : NSObject

@property (nonatomic ,assign) NSInteger ID;//auto id
@property (nonatomic ,copy) NSString *messageOwer;
@property (nonatomic ,copy) NSString *messageId;
@property (nonatomic ,assign) NSInteger createTime;
@property (nonatomic ,assign) NSInteger readTime;
@property (nonatomic ,assign) NSInteger snapTime;
@property (nonatomic ,assign) BOOL isRead;
@property (nonatomic ,copy) NSString *senderAddress;
@property (nonatomic ,assign) int chatType;
@property (nonatomic ,assign) GJGCChatFriendContentType messageType;
@property (nonatomic, assign) GJGCChatFriendSendMessageStatus sendstatus;
@property (nonatomic ,assign) int state;
@property (nonatomic ,strong) GPBMessage *msgContent; /// 发送的原始消息， eg:文本 图片
@property (nonatomic ,assign) int payCount;
@property (nonatomic ,assign) int crowdCount;

@end
