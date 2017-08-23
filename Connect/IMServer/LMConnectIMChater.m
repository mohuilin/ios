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
#import "ConnectTool.h"

@implementation LMConnectIMChater

CREATE_SHARED_MANAGER(LMConnectIMChater)


- (void)sendCreateGroupMsg:(CreateGroupMessage *)createGroupMessage to:(NSString *)to {
    /// 业务层
    ChatMessage *chatMsg = [LMMessageTool chatMsgWithTo:to chatType:0 msgType:0 ext:nil];
    GcmData *groupInfoGcmData = [ConnectTool createGcmWithData:createGroupMessage.data publickey:to needEmptySalt:YES];
    chatMsg.cipherData = groupInfoGcmData;
    
    MessageData *msgData = [MessageData new];
    msgData.chatMsg = chatMsg;
    
    
    NSString *sign = [ConnectTool signWithData:msgData.data];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.sign = sign;
    messagePost.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    messagePost.msgData = msgData;

    [[IMService instance] asyncSendGroupInfo:messagePost];
}



- (void)sendReadAckWithMessageId:(NSString *)msgId to:(NSString *)to complete:(void (^)(ChatMessage *chatMsg,NSError *error))complete {
    /// 业务层
    GPBMessage *originMsg = [LMMessageTool makeReadReceiptWithMsgId:msgId];
    MessageData *messageData = [LMMessageAdapter packageMessageDataWithTo:to chatType:ChatType_Private msgType:GJGCChatFriendContentTypeSnapChatReadedAck ext:nil groupEcdh:nil cipherData:originMsg];
    /// 发送数据
    [[IMService instance] asyncSendReadReceiptMessage:messageData originContent:originMsg completion:^(ChatMessage *msgData, NSError *error) {
        if (complete) {
            complete(msgData,error);
        }
    }];
}


- (void)sendChatMessageInfo:(ChatMessageInfo *)chatMessageInfo progress:(void (^)(NSString *to, NSString *msgId,CGFloat progress))progress complete:(void (^)(ChatMessageInfo *chatMsgInfo,NSError *error))complete {
    if ([LMMessageTool checkRichtextUploadStatuts:chatMessageInfo]) {
        NSString *groupECDH = nil;
        if (chatMessageInfo.chatType == GJGCChatFriendTalkTypeGroup) {
            groupECDH = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:chatMessageInfo.messageOwer];
        }
        /// Socket层
        MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:chatMessageInfo ext:nil groupEcdh:groupECDH];
        /// 更新会话
        [[LMConversionManager sharedManager] sendMessage:chatMessageInfo content:nil snapChat:chatMessageInfo.snapTime > 0 type:chatMessageInfo.chatType];
        
        if (complete) {
            complete(chatMessageInfo,nil);
        }
        /// 发送数据
        [[IMService instance] asyncSendMessage:messageData originContent:chatMessageInfo.msgContent chatType:chatMessageInfo.chatType completion:^(ChatMessage *chatMsg, NSError *error) {
            ChatMessageInfo *chatMessageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:chatMsg.msgId messageOwer:chatMsg.to];
            if (complete) {
                complete(chatMessageInfo,error);
            }
        }];
    } else {
        NSData *mainData = nil;
        NSData *minorData = nil;
        switch (chatMessageInfo.messageType) {
            case GJGCChatFriendContentTypeAudio:{
                NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
                filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                            stringByAppendingPathComponent:chatMessageInfo.messageOwer];
                NSString *amrFileName = [NSString stringWithFormat:@"%@.amr", chatMessageInfo.messageId];
                NSString *amrFilePath = [filePath stringByAppendingPathComponent:amrFileName];
                mainData = [NSData dataWithContentsOfFile:amrFilePath];
            }
                break;
            case GJGCChatFriendContentTypeImage:{
                
                NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
                filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                            stringByAppendingPathComponent:chatMessageInfo.messageOwer];
                NSString *originName = [NSString stringWithFormat:@"%@.jpg", chatMessageInfo.messageId];
                NSString *thumbImageName = [NSString stringWithFormat:@"%@-thumb.jpg", chatMessageInfo.messageId];
                NSString *originPath = [filePath stringByAppendingPathComponent:originName];
                NSString *thumbImageNamePath = [filePath stringByAppendingPathComponent:thumbImageName];
                
                minorData = [NSData dataWithContentsOfFile:thumbImageNamePath];
                mainData = [NSData dataWithContentsOfFile:originPath];
            }
                break;
            case GJGCChatFriendContentTypeVideo:{
                NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
                filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                            stringByAppendingPathComponent:chatMessageInfo.messageOwer];
                
                NSString *coverPath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-coverimage.jpg", chatMessageInfo.messageId]];
                NSString *videoPath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", chatMessageInfo.messageId]];
                minorData = [NSData dataWithContentsOfFile:coverPath];
                mainData = [NSData dataWithContentsOfFile:videoPath];
            }
                break;
            case GJGCChatFriendContentTypeMapLocation:
            {
                NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
                filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                            stringByAppendingPathComponent:chatMessageInfo.messageOwer];
                NSString *imageName = [NSString stringWithFormat:@"%@.jpg", chatMessageInfo.messageId];
                NSString *imagePath = [filePath stringByAppendingPathComponent:imageName];
                mainData = [NSData dataWithContentsOfFile:imagePath];
            }
                break;
            default:
                break;
        }

        if (mainData) {
            NSData *ECDH = nil;
            if (chatMessageInfo.chatType == GJGCChatFriendTalkTypeGroup) {
                NSString *ecdhKey = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:chatMessageInfo.messageOwer];
                ECDH = [StringTool hexStringToData:ecdhKey];
            } else if (chatMessageInfo.chatType == GJGCChatFriendTalkTypePrivate) {
                ECDH = [LMIMHelper getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey
                                               publicKey:chatMessageInfo.messageOwer];
            }
            
            /// 上传富文本消息
            [[LMChatMsgUploadManager sharedManager] uploadMainData:mainData minorData:minorData encryptECDH:ECDH to:chatMessageInfo.messageOwer msgId:chatMessageInfo.messageId chatType:chatMessageInfo.chatType originMsg:chatMessageInfo.msgContent progress:progress complete:^(GPBMessage *originMsg, NSString *to, NSString *msgId, NSError *error) {
                /// 更新消息
                ChatMessageInfo *chatMsgInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:msgId messageOwer:to];
                chatMsgInfo.msgContent = originMsg;
                
                [[MessageDBManager sharedManager] updataMessage:chatMsgInfo];
                
                /// 封装消息
                NSString *groupECDH = nil;
                if (chatMessageInfo.chatType == GJGCChatFriendTalkTypeGroup) {
                    groupECDH = [[GroupDBManager sharedManager] getGroupEcdhKeyByGroupIdentifier:to];
                }
                /// Socket层
                MessageData *messageData = [LMMessageAdapter packageChatMessageInfo:chatMsgInfo ext:nil groupEcdh:groupECDH];
                /// 更新会话
                [[LMConversionManager sharedManager] sendMessage:chatMessageInfo content:nil snapChat:chatMsgInfo.snapTime > 0 type:chatMsgInfo.chatType];
                
                /// 发送数据
                [[IMService instance] asyncSendMessage:messageData originContent:originMsg chatType:chatMsgInfo.chatType completion:^(ChatMessage *chatMsg, NSError *error) {
                    ChatMessageInfo *chatMessageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:chatMsg.msgId messageOwer:chatMsg.to];
                    if (complete) {
                        complete(chatMessageInfo,error);
                    }
                }];
            }];
        }
    }
}

- (void)sendMsgWithUIContentModel:(GJGCChatFriendContentModel *)messageModel chatIdentifier:(NSString *)chatIdentifier chatType:(GJGCChatFriendTalkType)chatType snapTime:(int)snapTime progress:(void (^)(NSString *to, NSString *msgId,CGFloat progress))progress complete:(void (^)(ChatMessageInfo *chatMsgInfo,NSError *error))complete {
    
    /// 业务层
    GPBMessage *originMsg = [LMMessageTool packageOriginMsgWithChatContent:messageModel snapTime:snapTime];
    /// 保存消息
    ChatMessageInfo *chatMsgInfo = [LMMessageTool chatMsgInfoWithTo:chatIdentifier chatType:chatType msgType:messageModel.contentType msgContent:originMsg];
    
    /// 同步消息ID和界面模型一致
    chatMsgInfo.messageId = messageModel.localMsgId;
    chatMsgInfo.snapTime = snapTime;
    
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
            [[LMConversionManager sharedManager] sendMessage:chatMsgInfo content:messageModel.originTextMessage snapChat:chatMsgInfo.snapTime > 0 type:chatMsgInfo.chatType];
            
            /// 发送数据
            [[IMService instance] asyncSendMessage:messageData originContent:originMsg chatType:chatMsgInfo.chatType completion:^(ChatMessage *chatMsg, NSError *error) {
                ChatMessageInfo *chatMessageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:chatMsg.msgId messageOwer:chatMsg.to];
                if (complete) {
                    complete(chatMessageInfo,error);
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
        [[LMConversionManager sharedManager] sendMessage:chatMsgInfo content:messageModel.originTextMessage snapChat:chatMsgInfo.snapTime > 0 type:chatType];
        
        if (complete) {
            complete(chatMsgInfo,nil);
        }
        /// 发送数据
        [[IMService instance] asyncSendMessage:messageData originContent:originMsg chatType:chatMsgInfo.chatType completion:^(ChatMessage *chatMsg, NSError *error) {
            ChatMessageInfo *chatMessageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:chatMsg.msgId messageOwer:chatMsg.to];
            if (complete) {
                complete(chatMessageInfo,error);
            }
        }];
    }
}

@end
