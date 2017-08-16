//
//  LMMessage.m
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessage.h"
#import "NSDictionary+LMSafety.h"
#import "StringTool.h"

@implementation LMMessage

+ (NSString *)primaryKey {
    return @"uniqueId";
}

- (LMBaseModel *)initWithNormalInfo:(id)info {
    if (self = [super init]) {
        if ([info isKindOfClass:[ChatMessageInfo class]]) {
            ChatMessageInfo *chatMessage = (ChatMessageInfo *) info;
            self.messageId = chatMessage.messageId;
            self.messageOwer = chatMessage.messageOwer;
            self.chatType = chatMessage.chatType;
            self.msgType = chatMessage.messageType;
            //set uniqueid  ,ensure message unique
            self.uniqueId = [[NSString stringWithFormat:@"%@_%@", self.messageId, self.messageOwer] sha1String];
            self.from = chatMessage.from;
            self.messageContent = [StringTool hexStringFromData:chatMessage.msgContent.data];
            self.createTime = chatMessage.createTime;
            self.readTime = chatMessage.readTime;
            self.snapTime = chatMessage.snapTime;
            self.sendstatus = chatMessage.sendstatus;
            self.state = chatMessage.state;
            switch (chatMessage.messageType) {
                case GJGCChatFriendContentTypeTransfer: {
                    LMMessageExt *msgExt = [[LMMessageExt alloc] init];
                    msgExt.messageId = chatMessage.messageId;
                    msgExt.status = 1;
                    self.msgExt = msgExt;
                }
                    break;
                case GJGCChatFriendContentTypePayReceipt: {
                    LMMessageExt *msgExt = [[LMMessageExt alloc] init];
                    msgExt.messageId = chatMessage.messageId;
                    self.msgExt = msgExt;
                }
                    break;

                default:
                    break;
            }
        }
    }
    return self;
}


- (id)normalInfo {
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.ID = self.ID;
    chatMessage.messageOwer = self.messageOwer;
    chatMessage.from = self.from;
    chatMessage.messageId = self.messageId;
    chatMessage.createTime = self.createTime;
    chatMessage.readTime = self.readTime;
    chatMessage.snapTime = self.snapTime;
    chatMessage.sendstatus = self.sendstatus;
    chatMessage.state = self.state;
    chatMessage.chatType = self.chatType;
    chatMessage.messageType = self.msgType;
    if (chatMessage.state == 0) {
        chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
    }
    switch (chatMessage.messageType) {
        case GJGCChatFriendContentTypeText:
        {
            chatMessage.msgContent = [TextMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            chatMessage.msgContent = [LocationMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeAudio:
        {
            chatMessage.msgContent = [VoiceMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeVideo:
        {
            chatMessage.msgContent = [VideoMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeImage:
        {
            chatMessage.msgContent = [PhotoMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeGif: {
            chatMessage.msgContent = [EmotionMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
        case GJGCChatFriendContentTypePayReceipt:
        {
            chatMessage.msgContent = [PaymentMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeTransfer:
        {
            chatMessage.msgContent = [TransferMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: {
            chatMessage.msgContent = [LuckPacketMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            chatMessage.msgContent = [CardMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
            
        case GJGCChatWalletLink: {
            chatMessage.msgContent = [WebsiteMessage parseFromData:[StringTool hexStringToData:self.messageContent] error:nil];
        }
            break;
        default:
            break;
    }
    return chatMessage;
}

@end
