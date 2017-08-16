//
//  LMConnectIMChater.m
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMConnectIMChater.h"
#import "LMMessageTool.h"
#import "LMChatMsgUploadManager.h"
#import "IMService.h"
#import "LMMessageAdapter.h"
#import "GroupDBManager.h"
#import "LMConversionManager.h"
#import "LMIMHelper.h"
#import "StringTool.h"
#import "MessageDBManager.h"

@implementation LMConnectIMChater

CREATE_SHARED_MANAGER(LMConnectIMChater)

- (void)sendReadAckWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg,NSError *error))complete {
    
    /// 业务层
    GPBMessage *originMsg = [LMMessageTool makeReadReceiptWithMsgId:msgId];
    
    MessageData *messageData = [LMMessageAdapter packageMessageDataWithTo:to chatType:ChatType_Private msgType:0 ext:nil groupEcdh:nil cipherData:originMsg];

    /// 发送数据
    [[IMService instance] asyncSendReadReceiptMessage:messageData originContent:originMsg completion:^(ChatMessage *msgData, NSError *error) {
        if (complete) {
            complete(msgData,error);
        }
    }];
}

- (void)sendMsgWithUIContentModel:(GJGCChatFriendContentModel *)messageModel chatIdentifier:(NSString *)chatIdentifier chatType:(GJGCChatFriendTalkType)chatType snapTime:(int)snapTime progress:(void (^)(CGFloat progress))progress complete:(void (^)(ChatMessage *chatMsg,NSError *error))complete {
    
    /// 业务层
    GPBMessage *originMsg = [LMMessageTool packageOriginMsgWithChatContent:messageModel snapTime:snapTime];
    /// 保存消息
    ChatMessageInfo *chatMsgInfo = [LMMessageTool chatMsgInfoWithTo:chatIdentifier chatType:chatType msgType:messageModel.contentType msgContent:originMsg];
    [[MessageDBManager sharedManager] saveMessage:chatMsgInfo];
    
    NSData *mainData = nil;
    NSData *minorData = nil;
    switch (messageModel.contentType) {
        case GJGCChatFriendContentTypeAudio:{
            mainData = [LMMessageTool formateVideoLoacalPath:messageModel];
        }
            break;
        case GJGCChatFriendContentTypeImage:{
            minorData = [NSData dataWithContentsOfFile:messageModel.thumbImageCachePath];
            mainData = [NSData dataWithContentsOfFile:messageModel.imageOriginDataCachePath];
        }
            break;
        case GJGCChatFriendContentTypeVideo:{
            minorData = [NSData dataWithContentsOfFile:messageModel.videoOriginCoverImageCachePath];
            mainData = [NSData dataWithContentsOfFile:messageModel.videoOriginDataPath];
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:
        {
            mainData = [NSData dataWithContentsOfFile:messageModel.locationImageOriginDataCachePath];
        }
            break;
        default:
            break;
    }
    
    if (mainData) {
        NSData *ECDH = nil;
        if (chatType == GJGCChatFriendTalkTypeGroup) {
            NSString *ecdhKey = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:chatIdentifier];
            ECDH = [StringTool hexStringToData:ecdhKey];
        } else if (chatType == GJGCChatFriendTalkTypePrivate) {
            ECDH = [LMIMHelper getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                                     publicKey:chatIdentifier];
        }

        /// 上传富文本消息
        [[LMChatMsgUploadManager sharedManager] uploadMainData:mainData minorData:minorData encryptECDH:ECDH to:chatIdentifier msgId:chatMsgInfo.messageId chatType:chatType originMsg:originMsg progress:progress complete:^(GPBMessage *originMsg, NSString *to, NSString *msgId, NSError *error) {
            /// 更新消息
            ChatMessageInfo *chatMsgInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:msgId messageOwer:to];
            chatMsgInfo.msgContent = originMsg;
            
            [[MessageDBManager sharedManager] updataMessage:chatMsgInfo];
            
            /// 封装消息
            NSString *groupECDH = nil;
            if (chatType == GJGCChatFriendTalkTypeGroup) {
                groupECDH = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:to];
            }
            /// Socket层
            MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:chatMsgInfo ext:nil groupEcdh:groupECDH];
            
            /// 更新会话
            [[LMConversionManager sharedManager] sendMessage:messageData.chatMsg content:messageModel.originTextMessage snapChat:snapTime > 0 type:chatType];
            
            /// 发送数据
            [[IMService instance] asyncSendMessage:messageData originContent:originMsg completion:^(ChatMessage *msgData, NSError *error) {
                if (complete) {
                    complete(msgData,error);
                }
            }];
        }];

    } else {
        NSString *groupECDH = nil;
        if (chatType == GJGCChatFriendTalkTypeGroup) {
            groupECDH = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:chatIdentifier];
        }
        /// Socket层
        MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:chatMsgInfo ext:nil groupEcdh:groupECDH];
        
        /// 更新会话
        [[LMConversionManager sharedManager] sendMessage:messageData.chatMsg content:messageModel.originTextMessage snapChat:snapTime > 0 type:chatType];
        
        /// 发送数据
        [[IMService instance] asyncSendMessage:messageData originContent:originMsg completion:^(ChatMessage *msgData, NSError *error) {
            if (complete) {
                complete(msgData,error);
            }
        }];
    }
}

@end
