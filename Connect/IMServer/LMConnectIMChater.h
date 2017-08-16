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

@interface LMConnectIMChater : NSObject

+ (instancetype)sharedManager;

- (void)sendReadAckWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg,NSError *error))complete;

- (void)sendMsgWithUIContentModel:(GJGCChatFriendContentModel *)messageModel chatIdentifier:(NSString *)chatIdentifier chatType:(GJGCChatFriendTalkType)chatType snapTime:(int)snapTime progress:(void (^)(CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg,NSError *error))complete;

@end
