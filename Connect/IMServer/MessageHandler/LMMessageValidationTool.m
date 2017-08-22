//
//  LMMessageValidationTool.m
//  Connect
//
//  Created by MoHuilin on 2016/12/29.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMMessageValidationTool.h"
#import "ChatMessageInfo.h"
#import "LMMessageTool.h"

@implementation LMMessageValidationTool

+ (BOOL)checkMessageValidata:(ChatMessageInfo *)chatMessageInfo messageType:(MessageType)msgType {

    if (!chatMessageInfo) {
        return NO;
    }

    //General property check
    if (GJCFStringIsNull(chatMessageInfo.messageId)) {
        return NO;
    }

    if (GJCFStringIsNull(chatMessageInfo.messageOwer)) {
        return NO;
    }

    if (GJCFStringIsNull(chatMessageInfo.from)) {
        return NO;
    }

    switch (msgType) {
        case MessageTypeSystem:
            return [self checkSystemMessage:chatMessageInfo];
            break;
        default:
            break;
    }

    switch (chatMessageInfo.messageType) {
        case GJGCChatFriendContentTypeGif: {
            EmotionMessage *msgContent = (EmotionMessage *)chatMessageInfo.msgContent;
            if (msgContent.content.length == 0) {
                return NO;
            }
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeText: {
            TextMessage *msgContent = (TextMessage *)chatMessageInfo.msgContent;
            if (msgContent.content.length == 0) {
                return NO;
            }
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {
            VoiceMessage *msgContent = (VoiceMessage *)chatMessageInfo.msgContent;
            if (msgContent.URL.length == 0) {
                return NO;
            }
            if (msgContent.timeLength < 0 ||
                msgContent.timeLength > 60) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            PhotoMessage *msgContent = (PhotoMessage *)chatMessageInfo.msgContent;
            if (msgContent.URL.length == 0) {
                return NO;
            }
            if (msgContent.imageWidth == 0) {
                return NO;
            }
            
            if (msgContent.imageHeight == 0) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeVideo: {
            VideoMessage *msgContent = (VideoMessage *)chatMessageInfo.msgContent;
            if (msgContent.URL.length == 0) {
                return NO;
            }
            if (msgContent.cover.length == 0) {
                return NO;
            }
            if (msgContent.imageWidth == 0) {
                return NO;
            }
            if (msgContent.imageHeight == 0) {
                return NO;
            }
            
            if (msgContent.size == 0) {
                return NO;
            }
            
            if (msgContent.timeLength == 0) {
                return NO;
            }
            
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeSnapChat: {
            DestructMessage *msgContent = (DestructMessage *)chatMessageInfo.msgContent;
            if (msgContent.time == -1) {
                msgContent.time = 0;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeSnapChatReadedAck: {
            ReadReceiptMessage *msgContent = (ReadReceiptMessage *)chatMessageInfo.msgContent;
            if (msgContent.messageId.length == 0) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypePayReceipt: {
            PaymentMessage *msgContent = (PaymentMessage *)chatMessageInfo.msgContent;
            if (msgContent.hashId.length == 0) {
                return NO;
            }
            if (msgContent.amount == 0) {
                return NO;
            }
            
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeTransfer: {
            TransferMessage *msgContent = (TransferMessage *)chatMessageInfo.msgContent;
            if (msgContent.hashId.length == 0) {
                return NO;
            }
            if (msgContent.amount == 0) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeRedEnvelope: {
            LuckPacketMessage *msgContent = (LuckPacketMessage *)chatMessageInfo.msgContent;
            if (msgContent.hashId.length == 0) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeMapLocation: {
            LocationMessage *msgContent = (LocationMessage *)chatMessageInfo.msgContent;
            if (msgContent.latitude == 0) {
                return NO;
            }
            if (msgContent.longitude == 0) {
                return NO;
            }
            if (msgContent.address.length == 0) {
                return NO;
            }
            
            if (msgContent.screenShot.length == 0) {
                return NO;
            }
            
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            CardMessage *msgContent = (CardMessage *)chatMessageInfo.msgContent;
            if (msgContent.username == 0) {
                return NO;
            }
            if (msgContent.uid == 0) {
                return NO;
            }
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeStatusTip: {
            NotifyMessage *msgContent = (NotifyMessage *)chatMessageInfo.msgContent;
            if (msgContent.content == 0) {
                return NO;
            }
            return YES;
        }
            break;

        case GJGCChatInviteToGroup: {
            JoinGroupMessage *msgContent = (JoinGroupMessage *)chatMessageInfo.msgContent;
            if (msgContent.groupName.length == 0) {
                return NO;
            }
            if (msgContent.groupId.length == 0) {
                return NO;
            }
            if (msgContent.token.length == 0) {
                return NO;
            }
            return YES;
        }
            break;
        case GJGCChatApplyToJoinGroup: {
//            Reviewed *msgContent = (Reviewed *)chatMessageInfo.msgContent;
            return YES;
        }

        case GJGCChatInviteNewMemberTip: {

            return YES;
        }
            break;
        case GJGCChatWalletLink: {
        
            return YES;
        }
            break;

        default: //cant parse message
        {
            chatMessageInfo.messageType = GJGCChatFriendContentTypeText;
            chatMessageInfo.msgContent = [LMMessageTool makeTextWithMessageText:LMLocalizedString(@"Chat Message not parse upgrade version", nil)];
            
            return YES;
        }
            break;
    }
    return NO;
}


+ (BOOL)checkSystemMessage:(ChatMessageInfo *)chatMessageInfo {
    switch (chatMessageInfo.messageType) {
        case GJGCChatFriendContentTypeText: {
            
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeTransfer: {


            return YES;
        }
            break;

        case GJGCChatFriendContentTypeRedEnvelope: {
            
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeStatusTip: {
            
            return YES;
        }
            break;

        case GJGCChatApplyToJoinGroup: {

            return YES;
        }

        case 102: //annoncement
        {

            return YES;
        }
            break;

        default: {
            chatMessageInfo.messageType = GJGCChatFriendContentTypeText;
            chatMessageInfo.msgContent = [LMMessageTool makeTextWithMessageText:LMLocalizedString(@"Chat Message not parse upgrade version", nil)];
            return YES;
        }
            break;
    }
    return NO;
}

@end
