//
//  LMConnectIMChater.h
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendContentModel.h"
#import "GJGCChatContentBaseModel.h"
#import "ChatMessageInfo.h"

@interface LMConnectIMChater : NSObject

+ (instancetype)sharedManager;

- (void)sendCreateGroupMsg:(CreateGroupMessage *)createGroupMessage to:(NSString *)to;

- (void)sendReadAckWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg,NSError *error))complete;

- (void)sendChatMessageInfo:(ChatMessageInfo *)chatMessageInfo progress:(void (^)(NSString *to, NSString *msgId,CGFloat progress))progress complete:(void (^)(ChatMessageInfo *chatMsgInfo,NSError *error))complete;

- (void)sendMsgWithUIContentModel:(GJGCChatFriendContentModel *)messageModel chatIdentifier:(NSString *)chatIdentifier chatType:(GJGCChatFriendTalkType)chatType snapTime:(int)snapTime progress:(void (^)(NSString *to, NSString *msgId,CGFloat progress))progress complete:(void (^)(ChatMessageInfo *chatMsgInfo,NSError *error))complete;

@end
