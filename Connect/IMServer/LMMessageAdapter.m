//
//  LMMessageAdapter.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageAdapter.h"
#import "StringTool.h"
#import "ConnectTool.h"
#import "GroupDBManager.h"
#import "LMBaseSSDBManager.h"
#import "LMMessageExtendManager.h"
#import "MessageDBManager.h"
#import "LMConversionManager.h"
#import "LMIMHelper.h"
#import "LMMessageTool.h"

@implementation LMMessageAdapter

+ (ChatMessageInfo *)decodeMessageWithMassagePost:(MessagePost *)msgPost groupECDH:(NSString *)groupECDH {
    NSData *data = [ConnectTool decodeGroupGcmDataWithEcdhKey:groupECDH GcmData:msgPost.msgData.chatMsg.cipherData];
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[GPBMessage parseFromData:data error:nil]];
    
    return chatMessage;
}

+ (ChatMessageInfo *)decodeMessageWithMassagePost:(MessagePost *)msgPost {
    ChatMessageInfo *chatMessageInfo = nil;
    LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
    if (!GJCFStringIsNull(msgPost.msgData.chatSession.pubKey) &&
            msgPost.msgData.chatSession.salt.length == 64 &&
            msgPost.msgData.chatSession.ver.length == 64) {
        securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
    } else if (!GJCFStringIsNull(msgPost.msgData.chatSession.pubKey) &&
            msgPost.msgData.chatSession.salt.length == 64 &&
            msgPost.msgData.chatSession.ver.length == 0) {
        securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
    }
    switch (securityLevel) {
        case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
            NSData *data = [ConnectTool decodeHalfRandomPeerImMessageGcmData:msgPost.msgData.chatMsg.cipherData publickey:msgPost.msgData.chatSession.pubKey salt:msgPost.msgData.chatSession.salt];
            chatMessageInfo = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
        }
            break;
        case LMChatEcdhKeySecurityLevelTypeNomarl: {
            NSData *data = [ConnectTool decodeMessageGcmData:msgPost.msgData.chatMsg.cipherData publickey:msgPost.pubKey needEmptySalt:YES];
            chatMessageInfo = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
        }
            break;
        case LMChatEcdhKeySecurityLevelTypeRandom: {
            NSData *data = [ConnectTool decodePeerImMessageGcmData:msgPost.msgData.chatMsg.cipherData publickey:msgPost.msgData.chatSession.pubKey salt:msgPost.msgData.chatSession.salt ver:msgPost.msgData.chatSession.ver];
            chatMessageInfo = [self chatMessageInfoWithChatMsg:msgPost.msgData.chatMsg originMsg:[self parseDataWithData:data msgType:msgPost.msgData.chatMsg.msgType]];
            if (!data) {
                chatMessageInfo = [self createDecodeFailedTipMessageWithMassagePost:msgPost];
            }
        }
            break;
        default:
            break;
    }
    return chatMessageInfo;
}

+ (ChatMessageInfo *)createDecodeFailedTipMessageWithMassagePost:(MessagePost *)msgPost {
    ChatMessageInfo *chatMessage = [LMMessageTool makeNotifyMessageWithMessageOwer:msgPost.msgData.chatMsg.to content:LMLocalizedString(@"Chat One message failed to decrypt", nil) noteType:0 ext:nil];
    return chatMessage;
}

+ (ChatMessageInfo *)packSystemMessage:(MSMessage *)sysMsg {
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageType = sysMsg.category;
    chatMessage.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMessage.messageId = sysMsg.msgId;
    chatMessage.messageOwer = kSystemIdendifier;
    chatMessage.chatType = ChatType_ConnectSystem;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    switch (sysMsg.category) {
        case GJGCChatFriendContentTypeText: {
            TextMessage *textMsg = [TextMessage parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = textMsg;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {
            VoiceMessage *voiceMsg = [VoiceMessage parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = voiceMsg;
        }
            break;
        case GJGCChatFriendContentTypeImage: {
            PhotoMessage *imageMsg = [PhotoMessage parseFromData:sysMsg.body error:nil];
            if (imageMsg.imageWidth == 0) {
                imageMsg.imageWidth = AUTO_WIDTH(200);
            }
            if (imageMsg.imageHeight == 0) {
                imageMsg.imageHeight = AUTO_WIDTH(250);
            }
            chatMessage.msgContent = imageMsg;
        }
            break;
        case GJGCChatFriendContentTypeVideo: {
            
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            
        }
            break;
        case GJGCChatFriendContentTypeGif: {
            
        }
            break;
        case GJGCChatFriendContentTypeTransfer: {
            SystemTransferPackage *transfer = [SystemTransferPackage parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = transfer;
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: //luckypackage
        {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
            NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
            int currentVer = [[versionNum stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            if (currentVer < 6) {
                chatMessage.messageType = GJGCChatFriendContentTypeNotFound;
            } else {
                SystemRedPackage *redPackMsg = [SystemRedPackage parseFromData:sysMsg.body error:nil];
                chatMessage.msgContent = redPackMsg;
            }
        }
            break;
        case 101: //group reviewed
        {
            Reviewed *reviewed = [Reviewed parseFromData:sysMsg.body error:nil];
            ReviewedStatus *reviewedStatus = [ReviewedStatus new];
            reviewedStatus.review = reviewed;
            reviewedStatus.newaccept = YES;
            reviewedStatus.refused = NO;
            chatMessage.messageType = GJGCChatApplyToJoinGroup;
            chatMessage.msgContent = reviewedStatus;
            if (!GJCFStringIsNull(reviewed.verificationCode)) {
                LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
                NSData *applyMessageData = nil;
                [ssdbManager get:reviewed.verificationCode data:&applyMessageData];
                if (applyMessageData) {
                    GroupApplyMessage *applyMessage = [GroupApplyMessage parseFromData:applyMessageData error:nil];
                    BOOL isExist = [[MessageDBManager sharedManager] isMessageIsExistWithMessageId:applyMessage.messageId messageOwer:kSystemIdendifier];
                    if (isExist) {
                        [GCDQueue executeInMainQueue:^{
                            SendNotify(DeleteGroupReviewedMessageNotification, applyMessage.messageId);
                        }];

                        [[MessageDBManager sharedManager] deleteMessageByMessageId:applyMessage.messageId messageOwer:kSystemIdendifier];
                    }
                    GroupApplyChange *applyChange = [GroupApplyChange parseFromData:applyMessage.applyData error:nil];
                    if (reviewed.tips && ![applyChange.tipsHistoryArray containsObject:reviewed.tips]) {
                        [applyChange.tipsHistoryArray objectAddObject:reviewed.tips];
                    }

                    applyMessage = [GroupApplyMessage new];
                    applyMessage.applyData = applyChange.data;
                    applyMessage.messageId = chatMessage.messageId;
                    [ssdbManager set:reviewed.verificationCode data:applyMessage.data];
                } else {
                    GroupApplyChange *applyChange = [GroupApplyChange new];
                    applyChange.verificationCode = reviewed.verificationCode;
                    applyChange.source = reviewed.source;
                    if (reviewed.tips) {
                        applyChange.tipsHistoryArray = @[reviewed.tips].mutableCopy;
                    }
                    GroupApplyMessage *applyMessage = [GroupApplyMessage new];
                    applyMessage.applyData = applyChange.data;
                    applyMessage.messageId = chatMessage.messageId;
                    [ssdbManager set:applyChange.verificationCode data:applyMessage.data];
                }
                [ssdbManager close];
            }
        }
            break;
        case 102: //announcement
        {
            Announcement *announcement = [Announcement parseFromData:sysMsg.body error:nil];
            chatMessage.msgContent = announcement;
        }
            break;
        case 103://luckypackage garb tips
        {
            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
            SystemRedpackgeNotice *repackNotict = [SystemRedpackgeNotice parseFromData:sysMsg.body error:nil];
            NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Chat opened Lucky Packet of", nil),repackNotict.receiver.username,LMLocalizedString(@"Chat You", nil)];
            NotifyMessage *notify = [LMMessageTool makeNotifyMessageWithTips:tips ext:repackNotict.hashid notifyType:NotifyMessageTypeGrabRULLuckyPackage];
            chatMessage.msgContent = notify;
        }
            break;

        case 104://group apply refuse or accepy tips
        {
            ReviewedResponse *repackNotict = [ReviewedResponse parseFromData:sysMsg.body error:nil];
            NSString *contentMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join rejected", nil), repackNotict.name];
            if (repackNotict.success) {
                contentMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join has passed", nil), repackNotict.name];
            }
            NotifyMessage *notify = [LMMessageTool makeNotifyNormalMessageWithTips:contentMessage];
            LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
            [ssdbManager set:repackNotict.identifier data:repackNotict.data];
            [ssdbManager close];
            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
            chatMessage.msgContent = notify;
        }
            break;
        case 105://phone number change
        {
            UpdateMobileBind *nameBind = [UpdateMobileBind parseFromData:sysMsg.body error:nil];
            chatMessage.messageType = GJGCChatFriendContentTypeText;
            TextMessage *text = [LMMessageTool makeTextWithMessageText:[NSString stringWithFormat:LMLocalizedString(@"Chat Your Connect ID will no longer be linked with mobile number", nil), nameBind.username]];
            chatMessage.msgContent = text;
            
            [[LKUserCenter shareCenter] currentLoginUser].bondingPhone = @"";
            [[LKUserCenter shareCenter] updateUserInfo:[[LKUserCenter shareCenter] currentLoginUser]];
        }
            break;
        case 106: //dismiss group note
        {
            RemoveGroup *dismissGroup = [RemoveGroup parseFromData:sysMsg.body error:nil];
            NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Chat Group has been disbanded", nil), dismissGroup.name];
            NotifyMessage *notify = [LMMessageTool makeNotifyNormalMessageWithTips:tips];
            chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
            chatMessage.msgContent = notify;
            
            if ([[SessionManager sharedManager].chatSession isEqualToString:dismissGroup.groupId]) {
                SendNotify(ConnnectGroupDismissNotification, dismissGroup.groupId)
            }
            [[LMConversionManager sharedManager] deleteConversation:[[SessionManager sharedManager] getRecentChatWithIdentifier:dismissGroup.groupId]];
            [[GroupDBManager sharedManager] deletegroupWithGroupId:dismissGroup.groupId];
        }
            break;
        case 200: {//outer address transfer to self
            AddressNotify *addressNot = [AddressNotify parseFromData:sysMsg.body error:nil];
            TransferMessage *transfer = [LMMessageTool makeTransferWithHashId:addressNot.txId transferType:3 amount:addressNot.amount tips:nil];
            chatMessage.messageType = GJGCChatFriendContentTypeTransfer;
            chatMessage.msgContent = transfer;
        }
            break;
        default:
            break;
    }
    return chatMessage;
}

+ (GPBMessage *)packageChatMsg:(ChatMessage *)chatMsg groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg {
    MessageData *messageData = [[MessageData alloc] init];
    /// chat msg
    messageData.chatMsg = chatMsg;
    
    /// chat session
    ChatSession *chatSession = [[ChatSession alloc] init];
    messageData.chatSession = chatSession;

    switch (chatMsg.chatType) {
        case GJGCChatFriendTalkTypePrivate:
        {
            ChatCookieData *reciverChatCookie = [[SessionManager sharedManager] getChatCookieWithChatSession:chatMsg.to];
            LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
            BOOL reciverChatCookieExpire = [[SessionManager sharedManager] chatCookieExpire:chatMsg.to];
            if (reciverChatCookie && [SessionManager sharedManager].loginUserChatCookie && !reciverChatCookieExpire) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
            } else if ((!reciverChatCookie || reciverChatCookieExpire)
                       && [SessionManager sharedManager].loginUserChatCookie) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
            }
            switch (securityLevel) {
                case LMChatEcdhKeySecurityLevelTypeRandom: {
                    chatSession.pubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
                    chatSession.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
                    chatSession.ver = reciverChatCookie.salt;
                    
                    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
                    NSData *ecdhKey = [LMIMHelper getECDHkeyWithPrivkey:privkey publicKey:reciverChatCookie.chatPubKey];
                    
                    // Salt or
                    NSData *exoData = [StringTool DataXOR1:[SessionManager sharedManager].loginUserChatCookie.salt DataXOR2:reciverChatCookie.salt];
                    
                    ecdhKey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
                    chatMsg.cipherData = [ConnectTool createGcmDataWithEcdhkey:ecdhKey data:originMsg.data aad:nil];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeNomarl: {
                    chatMsg.cipherData = [ConnectTool createGcmWithData:originMsg.data privkey:nil publickey:chatMsg.to aad:nil needEmptySalt:YES];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
                    
                    chatSession.pubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
                    chatSession.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
                    
                    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
                    NSData *ecdhKey = [LMIMHelper getECDHkeyWithPrivkey:privkey publicKey:chatMsg.to];
                    // Extended
                    ecdhKey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[SessionManager sharedManager].loginUserChatCookie.salt];
                    chatMsg.cipherData = [ConnectTool createGcmDataWithEcdhkey:ecdhKey data:originMsg.data aad:nil];
                }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case GJGCChatFriendTalkTypeGroup:{
            chatMsg.cipherData = [ConnectTool createGcmWithData:originMsg.data ecdhKey:[StringTool hexStringToData:groupEcdh] needEmptySalt:NO];
        }
            break;
            
        case GJGCChatFriendTalkTypePostSystem:{
            MSMessage *msMessage = [[MSMessage alloc] init];
            msMessage.msgId = [ConnectTool generateMessageId];
            msMessage.body = originMsg.data;
            msMessage.category = chatMsg.msgType;
            IMTransferData *imTransferData = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:msMessage.data aad:nil];
            return imTransferData;
        }
            break;
            
        default:
            break;
    }

    NSString *sign = [ConnectTool signWithData:messageData.data];
    MessagePost *messagePost = [[MessagePost alloc] init];
    messagePost.pubKey = [LKUserCenter shareCenter].currentLoginUser.pub_key;
    messagePost.msgData = messageData;
    messagePost.sign = sign;
    
    return messagePost;

}



+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg {
    
    MessageData *messageData = [[MessageData alloc] init];
    
    /// chat msg
    ChatMessage *chatMsg = [[ChatMessage alloc] init];
    chatMsg.from = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    chatMsg.to = to;
    chatMsg.msgType = msgType;
    chatMsg.ext = ext;
    chatMsg.msgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMsg.chatType = chatType;
    messageData.chatMsg = chatMsg;
    
    /// chat session
    ChatSession *chatSession = [[ChatSession alloc] init];
    messageData.chatSession = chatSession;
    
    
    switch (chatType) {
        case GJGCChatFriendTalkTypePrivate:
        {
            ChatCookieData *reciverChatCookie = [[SessionManager sharedManager] getChatCookieWithChatSession:to];
            LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
            BOOL reciverChatCookieExpire = [[SessionManager sharedManager] chatCookieExpire:to];
            if (reciverChatCookie && [SessionManager sharedManager].loginUserChatCookie && !reciverChatCookieExpire) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
            } else if ((!reciverChatCookie || reciverChatCookieExpire)
                       && [SessionManager sharedManager].loginUserChatCookie) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
            }
            switch (securityLevel) {
                case LMChatEcdhKeySecurityLevelTypeRandom: {
                    chatSession.pubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
                    chatSession.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
                    chatSession.ver = reciverChatCookie.salt;
                    
                    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
                    NSData *ecdhKey = [LMIMHelper getECDHkeyWithPrivkey:privkey publicKey:reciverChatCookie.chatPubKey];
                    
                    // Salt or
                    NSData *exoData = [StringTool DataXOR1:[SessionManager sharedManager].loginUserChatCookie.salt DataXOR2:reciverChatCookie.salt];
                    
                    ecdhKey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
                    chatMsg.cipherData = [ConnectTool createGcmDataWithEcdhkey:ecdhKey data:originMsg.data aad:nil];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeNomarl: {
                    chatMsg.cipherData = [ConnectTool createGcmWithData:originMsg.data privkey:nil publickey:to aad:nil needEmptySalt:YES];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
                    
                    chatSession.pubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
                    chatSession.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
                    
                    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
                    NSData *ecdhKey = [LMIMHelper getECDHkeyWithPrivkey:privkey publicKey:to];
                    // Extended
                    ecdhKey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[SessionManager sharedManager].loginUserChatCookie.salt];
                    chatMsg.cipherData = [ConnectTool createGcmDataWithEcdhkey:ecdhKey data:originMsg.data aad:nil];
                }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case GJGCChatFriendTalkTypeGroup:{
            chatMsg.cipherData = [ConnectTool createGcmWithData:originMsg.data ecdhKey:[StringTool hexStringToData:groupEcdh] needEmptySalt:NO];
        }
            break;
            
        case GJGCChatFriendTalkTypePostSystem:{
            MSMessage *msMessage = [[MSMessage alloc] init];
            msMessage.msgId = [ConnectTool generateMessageId];
            msMessage.body = originMsg.data;
            msMessage.category = msgType;
            IMTransferData *imTransferData = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:msMessage.data aad:nil];
            return imTransferData;
        }
            break;
            
        default:
            break;
    }
    
    return messageData;
}


+ (ChatMessageInfo *)chatMessageInfoWithChatMsg:(ChatMessage *)chatMsg originMsg:(GPBMessage *)originMsg{
    ChatMessageInfo *chatMessageInfo = [ChatMessageInfo new];
    chatMessageInfo.messageId = chatMsg.msgId;
    chatMessageInfo.messageOwer = chatMsg.to;
    chatMessageInfo.createTime = chatMsg.msgTime;
    chatMessageInfo.from = chatMsg.from;
    chatMessageInfo.chatType = chatMsg.chatType;
    chatMessageInfo.messageType = chatMsg.msgType;
    chatMessageInfo.msgContent = originMsg;
    chatMessageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;

    if ([originMsg isKindOfClass:[VoiceMessage class]]) {
        VoiceMessage *voice = (VoiceMessage *)originMsg;
        chatMessageInfo.snapTime = voice.snapTime;
    } else if ([originMsg isKindOfClass:[VideoMessage class]]) {
        VideoMessage *video = (VideoMessage *)originMsg;
        chatMessageInfo.snapTime = video.snapTime;
    } else if ([originMsg isKindOfClass:[PhotoMessage class]]) {
        PhotoMessage *photo = (PhotoMessage *)originMsg;
        chatMessageInfo.snapTime = photo.snapTime;
    } else if ([originMsg isKindOfClass:[TextMessage class]]) {
        TextMessage *test = (TextMessage *)originMsg;
        chatMessageInfo.snapTime = test.snapTime;
    } else if ([originMsg isKindOfClass:[EmotionMessage class]]) {
        EmotionMessage *emotion = (EmotionMessage *)originMsg;
        chatMessageInfo.snapTime = emotion.snapTime;
    }
 
    return chatMessageInfo;
}

+ (MessageData *)packageChatMessageInfo:(ChatMessageInfo *)chatMessageInfo ext:(id)ext groupEcdh:(NSString *)groupEcdh {
    MessageData *messageData = [[MessageData alloc] init];
    /// chat msg
    ChatMessage *chatMsg = [[ChatMessage alloc] init];
    chatMsg.from = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    chatMsg.to = chatMessageInfo.messageOwer;
    chatMsg.msgType = chatMessageInfo.messageType;
    chatMsg.ext = ext;
    chatMsg.msgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMsg.chatType = chatMessageInfo.chatType;
    messageData.chatMsg = chatMsg;
    
    /// chat session
    ChatSession *chatSession = [[ChatSession alloc] init];
    messageData.chatSession = chatSession;

    switch (chatMsg.chatType) {
        case GJGCChatFriendTalkTypePrivate:
        {
            ChatCookieData *reciverChatCookie = [[SessionManager sharedManager] getChatCookieWithChatSession:chatMsg.to];
            LMChatEcdhKeySecurityLevelType securityLevel = LMChatEcdhKeySecurityLevelTypeNomarl;
            BOOL reciverChatCookieExpire = [[SessionManager sharedManager] chatCookieExpire:chatMsg.to];
            if (reciverChatCookie && [SessionManager sharedManager].loginUserChatCookie && !reciverChatCookieExpire) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeRandom;
            } else if ((!reciverChatCookie || reciverChatCookieExpire)
                       && [SessionManager sharedManager].loginUserChatCookie) {
                securityLevel = LMChatEcdhKeySecurityLevelTypeHalfRandom;
            }
            switch (securityLevel) {
                case LMChatEcdhKeySecurityLevelTypeRandom: {
                    chatSession.pubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
                    chatSession.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
                    chatSession.ver = reciverChatCookie.salt;
                    
                    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
                    NSData *ecdhKey = [LMIMHelper getECDHkeyWithPrivkey:privkey publicKey:reciverChatCookie.chatPubKey];
                    
                    // Salt or
                    NSData *exoData = [StringTool DataXOR1:[SessionManager sharedManager].loginUserChatCookie.salt DataXOR2:reciverChatCookie.salt];
                    
                    ecdhKey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhKey salt:exoData];
                    chatMsg.cipherData = [ConnectTool createGcmDataWithEcdhkey:ecdhKey data:chatMessageInfo.msgContent.data aad:nil];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeNomarl: {
                    chatMsg.cipherData = [ConnectTool createGcmWithData:chatMessageInfo.msgContent.data privkey:nil publickey:chatMsg.to aad:nil needEmptySalt:YES];
                }
                    break;
                case LMChatEcdhKeySecurityLevelTypeHalfRandom: {
                    
                    chatSession.pubKey = [SessionManager sharedManager].loginUserChatCookie.chatPubKey;
                    chatSession.salt = [SessionManager sharedManager].loginUserChatCookie.salt;
                    
                    NSString * privkey = [SessionManager sharedManager].loginUserChatCookie.chatPrivkey;
                    NSData *ecdhKey = [LMIMHelper getECDHkeyWithPrivkey:privkey publicKey:chatMsg.to];
                    // Extended
                    ecdhKey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[SessionManager sharedManager].loginUserChatCookie.salt];
                    chatMsg.cipherData = [ConnectTool createGcmDataWithEcdhkey:ecdhKey data:chatMessageInfo.msgContent.data aad:nil];
                }
                    break;
                default:
                    break;
            }
        }
            break;
            
        case GJGCChatFriendTalkTypeGroup:{
            chatMsg.cipherData = [ConnectTool createGcmWithData:chatMessageInfo.msgContent.data ecdhKey:[StringTool hexStringToData:groupEcdh] needEmptySalt:NO];
        }
            break;
            
        case GJGCChatFriendTalkTypePostSystem:{
            MSMessage *msMessage = [[MSMessage alloc] init];
            msMessage.msgId = [ConnectTool generateMessageId];
            msMessage.body = chatMessageInfo.msgContent.data;
            msMessage.category = chatMessageInfo.messageType;
            IMTransferData *imTransferData = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:msMessage.data aad:nil];
            return imTransferData;
        }
            break;
            
        default:
            break;
    }
    
    return messageData;
}

+ (GPBMessage *)parseDataWithData:(NSData *)data msgType:(int)msgType {
    GPBMessage *msgContent = nil;
    switch (msgType) {
        case GJGCChatFriendContentTypeText:
        {
            msgContent = [TextMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            msgContent = [LocationMessage parseFromData:data error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeAudio:
        {
            msgContent = [VoiceMessage parseFromData:data error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeVideo:
        {
            msgContent = [VideoMessage parseFromData:data error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeImage:
        {
            msgContent = [PhotoMessage parseFromData:data error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeGif: {
            msgContent = [EmotionMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypePayReceipt:
        {
            msgContent = [PaymentMessage parseFromData:data error:nil];
        }
            break;
            
        case GJGCChatFriendContentTypeTransfer:
        {
            msgContent = [TransferMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: {
            msgContent = [LuckPacketMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            msgContent = [CardMessage parseFromData:data error:nil];
        }
            break;
            
        case GJGCChatWalletLink: {
            msgContent = [WebsiteMessage parseFromData:data error:nil];
        }
            break;
        case 102:{
            msgContent = [Announcement parseFromData:data error:nil];
        }
            break;
        case GJGCChatApplyToJoinGroup:
        {
            msgContent = [ReviewedStatus parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypeSnapChat:
        {
            msgContent = [DestructMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypeSnapChatReadedAck:
        {
            msgContent = [ReadReceiptMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatFriendContentTypeStatusTip:
        {
            msgContent = [NotifyMessage parseFromData:data error:nil];
        }
            break;
        case GJGCChatInviteToGroup:{
            msgContent = [JoinGroupMessage parseFromData:data error:nil];
        }
            break;
            
        default:
            break;
    }
    return msgContent;
}

@end
