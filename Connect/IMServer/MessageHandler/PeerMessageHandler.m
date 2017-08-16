
/*
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageHandler.h"
#import "NSString+DictionaryValue.h"
#import "UserDBManager.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "LMBaseSSDBManager.h"
#import "SystemTool.h"
#import "LMMessageValidationTool.h"
#import "LMConversionManager.h"
#import "LMMessageExtendManager.h"
#import "LMHistoryCacheManager.h"
#import "LMMessageAdapter.h"
#import "LMIMHelper.h"

@interface PeerMessageHandler ()

@end

@implementation PeerMessageHandler
+ (PeerMessageHandler *)instance {
    static PeerMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[PeerMessageHandler alloc] init];
        }
    });
    return m;
}

- (instancetype)init {
    if (self = [super init]) {
        self.getNewMessageObservers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}


- (void)addGetNewMessageObserver:(id <MessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers addObject:oberver];
}

- (void)removeGetNewMessageObserver:(id <MessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers removeObject:oberver];
}

- (void)pushGetBitchNewMessages:(NSArray *)messages {
    ChatMessageInfo *lastMsg = [messages lastObject];
    if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
        for (id <MessageHandlerGetNewMessage> ob in self.getNewMessageObservers) {
            if ([ob respondsToSelector:@selector(getBitchNewMessage:)]) {
                [GCDQueue executeInMainQueue:^{
                    [ob getBitchNewMessage:messages];
                }];
            }
        }
    }
}

- (void)pushGetReadAckWithMessageId:(NSString *)messageId chatUserPublickey:(NSString *)pulickey {

    for (id <MessageHandlerGetNewMessage> ob in self.getNewMessageObservers) {
        if ([ob respondsToSelector:@selector(getReadAckWithMessageID:chatUserPublickey:)]) {
            [ob getReadAckWithMessageID:messageId chatUserPublickey:pulickey];
        }
    }
}

- (BOOL)handleBatchMessages:(NSArray *)messages {

    NSMutableDictionary *owerMessagesDict = [NSMutableDictionary dictionary];
    NSMutableArray *messageExtendArray = [NSMutableArray array];
    for (MessagePost *msg in messages) {
        
        ChatMessageInfo *chatMessageInfo = [LMMessageAdapter decodeMessageWithMassagePost:msg];

        if (![LMMessageValidationTool checkMessageValidata:chatMessageInfo messageType:MessageTypePersion]) {
            continue;
        }
        if (chatMessageInfo.messageType == GJGCChatInviteToGroup) {
            NSString *identifier = @"";
            LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
            [ssdbManager del:identifier];
            [ssdbManager close];
        }
        
        if (chatMessageInfo.messageType == GJGCChatFriendContentTypeSnapChatReadedAck) { //ack
            ReadReceiptMessage *readReceipt = (ReadReceiptMessage *)chatMessageInfo.msgContent;
            [[MessageDBManager sharedManager] updateAudioMessageWithMsgID:readReceipt.messageId messageOwer:msg.pubKey];
            [GCDQueue executeInMainQueue:^{
                [self pushGetReadAckWithMessageId:readReceipt.messageId chatUserPublickey:msg.pubKey];
            }];
            continue;
        }
        
        //transfer message
        if (chatMessageInfo.messageType == GJGCChatFriendContentTypeTransfer) {
            [[LMHistoryCacheManager sharedManager] cacheTransferHistoryWith:chatMessageInfo.from];
        }
                
        NSMutableDictionary *msgDict = [owerMessagesDict valueForKey:chatMessageInfo.messageOwer];
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        if (messages) {
            [messages objectAddObject:chatMessageInfo];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessageInfo.messageType]) {
                unReadCount++;
                [msgDict setValue:@(unReadCount) forKey:@"unReadCount"];
            }
        } else {
            messages = [NSMutableArray array];
            [messages objectAddObject:chatMessageInfo];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessageInfo.messageType]) {
                unReadCount = 1;
            }
            NSMutableDictionary *msgDict = @{@"messages": messages,
                                             @"unReadCount": @(unReadCount)}.mutableCopy;
            [owerMessagesDict setObject:msgDict forKey:chatMessageInfo.messageOwer];
        }
        if (chatMessageInfo.messageType == GJGCChatFriendContentTypePayReceipt ||
            chatMessageInfo.messageType == GJGCChatFriendContentTypeTransfer) {
            
        }
    }
    [[LMMessageExtendManager sharedManager] saveBitchMessageExtend:messageExtendArray];

    for (NSDictionary *msgDict in owerMessagesDict.allValues) {
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        [messages sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
            ChatMessageInfo *r1 = obj1;
            ChatMessageInfo *r2 = obj2;
            int long long time1 = r1.createTime;
            int long long time2 = r2.createTime;
            if (time1 < time2) {
                return NSOrderedAscending;
            } else if (time1 == time2) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        }];

        NSMutableArray *pushMessages = [NSMutableArray arrayWithArray:messages];
        while (pushMessages.count > 0) {
            if (pushMessages.count > 20) {
                NSUInteger location = 0;
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:[pushMessages subarrayWithRange:NSMakeRange(location, 20)]];
                [pushMessages removeObjectsInRange:NSMakeRange(location, 20)];
                [self pushGetBitchNewMessages:pushArray];

                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];
                ChatMessageInfo *lastMsg = [pushArray lastObject];
                if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
                    unReadCount = 0;
                }
                
                [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount withSnapChatTime:lastMsg.snapTime];

                //notice onece, clear unread count
                unReadCount = 0;
            } else {
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:pushMessages];

                [self pushGetBitchNewMessages:pushArray];

                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];

                ChatMessageInfo *lastMsg = [pushArray lastObject];

                if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
                    unReadCount = 0;
                }

                [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount withSnapChatTime:lastMsg.snapTime];

                [pushMessages removeAllObjects];
            }
        }
    }
    return YES;
}

/**
 * Update session last message
 * @param chatMsg
 * @param messageCount
 * @param snapChatTime
 */
- (void)updataRecentChatLastMessageStatus:(ChatMessageInfo *)chatMsg messageCount:(int)messageCount withSnapChatTime:(long long)snapChatTime {
    [[LMConversionManager sharedManager] getNewMessagesWithLastMessage:chatMsg newMessageCount:messageCount type:GJGCChatFriendTalkTypePrivate withSnapChatTime:snapChatTime];
}

- (BOOL)handleMessage:(MessagePost *)msg {
    MessageData *messageData = msg.msgData;
    if (![[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:messageData.chatMsg.to] && [GJGCChatFriendConstans shouldNoticeWithType:messageData.chatMsg.msgType]) {
        if (![[SessionManager sharedManager].chatSession isEqualToString:msg.pubKey]) {
            [SystemTool vibrateOrVoiceNoti];
        }
    };
    return [self handleBatchMessages:@[msg]];
}

@end
