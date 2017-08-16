//
//  LMMessageValidationTool.m
//  Connect
//
//  Created by MoHuilin on 2016/12/29.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMMessageValidationTool.h"
#import "ChatMessageInfo.h"

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
        case MessageTypeGroup: {

        }
            break;
        case MessageTypeSystem:
            return [self checkSystemMessage:chatMessageInfo];
            break;
        default:
            break;
    }

    switch (chatMessageInfo.messageType) {
        case GJGCChatFriendContentTypeGif:
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

        case GJGCChatFriendContentTypeVideo: {

            return YES;
        }
            break;

        case GJGCChatFriendContentTypeSnapChat: {
            
            return YES;
        }
            break;

        case GJGCChatFriendContentTypeSnapChatReadedAck: {

            return YES;
        }
            break;

        case GJGCChatFriendContentTypePayReceipt: {
            
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

        case GJGCChatFriendContentTypeMapLocation: {
            
            return YES;
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {

            return YES;
        }
            break;
        case GJGCChatFriendContentTypeStatusTip: {
            
            return YES;
        }
            break;

        case GJGCChatInviteToGroup: {
            
            return YES;
        }
            break;
        case GJGCChatApplyToJoinGroup: {
            
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
//            message.content = LMLocalizedString(@"Chat Message not parse upgrade version", nil);
//            message.type = GJGCChatFriendContentTypeText;
            return YES;
        }
            break;
    }
    return NO;
}


+ (BOOL)checkSystemMessage:(ChatMessageInfo *)chatMesssageInfo {
    switch (chatMesssageInfo.messageType) {
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
//            message.content = LMLocalizedString(@"Chat Message not parse upgrade version", nil);
//            message.type = GJGCChatFriendContentTypeText;
            return YES;
        }
            break;
    }
    return NO;
}

@end
