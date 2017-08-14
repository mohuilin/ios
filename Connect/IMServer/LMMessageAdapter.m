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

@implementation LMMessageAdapter

+ (NSString *)decodeMessageWithMassagePost:(MessagePost *)msgPost {
    NSString *messageString = nil;
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
            messageString = [ConnectTool decodeHalfRandomPeerImMessageGcmData:msgPost.msgData.chatMsg.cipherData publickey:msgPost.msgData.chatSession.pubKey salt:msgPost.msgData.chatSession.salt];
        }
            break;
        case LMChatEcdhKeySecurityLevelTypeNomarl: {
            messageString = [ConnectTool decodeMessageGcmData:msgPost.msgData.chatMsg.cipherData publickey:msgPost.pubKey needEmptySalt:YES];
        }
            break;
        case LMChatEcdhKeySecurityLevelTypeRandom: {
            messageString = [ConnectTool decodePeerImMessageGcmData:msgPost.msgData.chatMsg.cipherData publickey:msgPost.msgData.chatSession.pubKey salt:msgPost.msgData.chatSession.salt ver:msgPost.msgData.chatSession.ver];
            if (GJCFStringIsNull(messageString)) {
                MMMessage *tipMessage = [self createDecodeFailedTipMessageWithMassagePost:msgPost];
                messageString = [tipMessage mj_JSONString];
            }
        }
            break;
        default:
            break;
    }
    return messageString;
}

+ (MMMessage *)createDecodeFailedTipMessageWithMassagePost:(MessagePost *)msgPost {
    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeStatusTip;
    message.content = LMLocalizedString(@"Chat One message failed to decrypt", nil);
    message.ext1 = @(100);// not use ,just for check
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = msgPost.pubKey;
    message.user_id = [LMIMHelper getAddressByPubkey:message.publicKey];
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;

    return message;
}


+ (MMMessage *)packSystemMessage:(MSMessage *)sysMsg {
    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = @"Connect";
    message.type = sysMsg.category;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = sysMsg.msgId;
    message.publicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    switch (sysMsg.category) {
        case GJGCChatFriendContentTypeText: {
            TextMessage *textMsg = [TextMessage parseFromData:sysMsg.body error:nil];
            message.content = textMsg.content;
        }
            break;
        case GJGCChatFriendContentTypeAudio: {

            Voice *voiceMsg = [Voice parseFromData:sysMsg.body error:nil];
            message.content = voiceMsg.URL;
            //duration
            message.size = (int) voiceMsg.duration * 50;
        }
            break;
        case GJGCChatFriendContentTypeImage: {
            Image *imageMsg = [Image parseFromData:sysMsg.body error:nil];
            message.content = imageMsg.URL;
            message.imageOriginWidth = AUTO_WIDTH(200);
            message.imageOriginHeight = AUTO_WIDTH(250);
            if ([imageMsg.width floatValue] > 0) {
                message.imageOriginWidth = [imageMsg.width floatValue];
            }
            if ([imageMsg.height floatValue] > 0) {
                message.imageOriginHeight = [imageMsg.height floatValue];
            }
        }
            break;
        case GJGCChatFriendContentTypeVideo: {
            message.content = @"封面url";
            message.url = @"视频url";
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            if (message.type == GJGCChatFriendContentTypeMapLocation) {
                message.locationExt = @{@"locationLatitude": @(1),
                        @"locationLongitude": @(2),
                        @"address": @"address"};
            }

        }
            break;
        case GJGCChatFriendContentTypeGif: {
            message.content = @"1";
        }
            break;
        case GJGCChatFriendContentTypeTransfer: {
            /*
             message.ext1 = @(messageContent.amount);
             message.ext = messageContent.tipNote;
             message.ext = messageContent.tipNote;
             */
            SystemTransferPackage *transfer = [SystemTransferPackage parseFromData:sysMsg.body error:nil];
            message.content = transfer.txid;
            message.ext = transfer.tips;
            message.ext1 = @{@"amount": @(transfer.amount),
                    @"tips": @""};
            message.locationExt = transfer.sender;


            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict safeSetObject:message.message_id forKey:@"message_id"];
            [dict safeSetObject:message.content forKey:@"hashid"];
            [dict safeSetObject:@(1) forKey:@"status"];
            [dict safeSetObject:@(0) forKey:@"pay_count"];
            [dict safeSetObject:@(0) forKey:@"crowd_count"];
            [[LMMessageExtendManager sharedManager] saveBitchMessageExtendDict:dict];

        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: //luckypackage
        {
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary]; //CFBundleIdentifier
            NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
            int currentVer = [[versionNum stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
            if (currentVer < 6) {
                message.type = GJGCChatFriendContentTypeNotFound;
            } else {
                SystemRedPackage *redPackMsg = [SystemRedPackage parseFromData:sysMsg.body error:nil];
                message.content = redPackMsg.hashId;
                message.ext1 = redPackMsg.tips;
            }
        }
            break;
        case 101: //group reviewed
        {
            Reviewed *reviewed = [Reviewed parseFromData:sysMsg.body error:nil];
            message.ext1 = @{@"username": reviewed.userInfo.username,
                    @"avatar": reviewed.userInfo.avatar,
                    @"pubKey": reviewed.userInfo.pubKey,
                    @"identifier": reviewed.identifier,
                    @"category": @(reviewed.category),
                    @"tips": reviewed.tips ? reviewed.tips : @"",
                    @"verificationCode": reviewed.verificationCode ? reviewed.verificationCode : @"",
                    @"groupname": reviewed.name,
                    @"source": @(reviewed.source)};
            message.type = GJGCChatApplyToJoinGroup;


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
                    applyMessage.messageId = message.message_id;
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
                    applyMessage.messageId = message.message_id;
                    [ssdbManager set:applyChange.verificationCode data:applyMessage.data];
                }
                [ssdbManager close];
            }
        }
            break;
        case 102: //announcement
        {
            Announcement *announcement = [Announcement parseFromData:sysMsg.body error:nil];
            if (GJCFStringIsNull(announcement.title) || GJCFStringIsNull(announcement.desc)) {
                return nil;
            }
            NSMutableDictionary *ext1 = @{}.mutableCopy;
            [ext1 setObject:announcement.title forKey:@"title"];
            [ext1 setObject:announcement.desc forKey:@"content"];
            [ext1 setObject:@(announcement.category) forKey:@"category"];
            if (GJCFCheckObjectNull(@(announcement.createdAt))) {
                [ext1 setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"createAt"];
            } else {
                [ext1 setObject:@(announcement.createdAt) forKey:@"createAt"];
            }
            if (!GJCFStringIsNull(announcement.URL)) {
                [ext1 setObject:announcement.URL forKey:@"jumpUrl"];
            }
            if (!GJCFStringIsNull(announcement.coversURL)) {
                [ext1 setObject:announcement.coversURL forKey:@"coversURL"];
            }
            message.ext1 = ext1;
        }
            break;
        case 103://luckypackage garb tips
        {
            SystemRedpackgeNotice *repackNotict = [SystemRedpackgeNotice parseFromData:sysMsg.body error:nil];
            message.content = repackNotict.receiver.username;
            message.ext1 = @{@"type": @"redpackge",
                    @"hashid": repackNotict.hashid};
            message.type = GJGCChatFriendContentTypeStatusTip;
        }
            break;

        case 104://group apply refuse or accepy tips
        {
            ReviewedResponse *repackNotict = [ReviewedResponse parseFromData:sysMsg.body error:nil];
            NSString *contentMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join rejected", nil), repackNotict.name];
            if (repackNotict.success) {
                contentMessage = [NSString stringWithFormat:LMLocalizedString(@"Link You apply to join has passed", nil), repackNotict.name];
            }
            LMBaseSSDBManager *ssdbManager = [LMBaseSSDBManager open:@"system_message"];
            [ssdbManager set:repackNotict.identifier data:repackNotict.data];
            [ssdbManager close];
            message.ext1 = @{@"type": @"groupreviewed",
                    @"message": contentMessage};
            message.type = GJGCChatFriendContentTypeStatusTip;
        }
            break;
        case 105://phone number change
        {
            UpdateMobileBind *nameBind = [UpdateMobileBind parseFromData:sysMsg.body error:nil];
            message.type = GJGCChatFriendContentTypeText;
            message.content = [NSString stringWithFormat:LMLocalizedString(@"Chat Your Connect ID will no longer be linked with mobile number", nil), nameBind.username];

            [[LKUserCenter shareCenter] currentLoginUser].bondingPhone = @"";
            [[LKUserCenter shareCenter] updateUserInfo:[[LKUserCenter shareCenter] currentLoginUser]];
        }
            break;
        case 106: //dismiss group note
        {
            RemoveGroup *dismissGroup = [RemoveGroup parseFromData:sysMsg.body error:nil];
            NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Chat Group has been disbanded", nil), dismissGroup.name];
            message.ext1 = @{@"type": @"groupdismiss",
                    @"message": tips};


            if ([[SessionManager sharedManager].chatSession isEqualToString:dismissGroup.groupId]) {
                SendNotify(ConnnectGroupDismissNotification, dismissGroup.groupId)
            }
            message.type = GJGCChatFriendContentTypeStatusTip;

            [[LMConversionManager sharedManager] deleteConversation:[[SessionManager sharedManager] getRecentChatWithIdentifier:dismissGroup.groupId]];

            [[GroupDBManager sharedManager] deletegroupWithGroupId:dismissGroup.groupId];
            //clear group avatar
        }
            break;
        case 200: {//outer address transfer to self
            AddressNotify *addressNot = [AddressNotify parseFromData:sysMsg.body error:nil];
            message.content = addressNot.txId;
            message.ext1 = @{@"amount": @(addressNot.amount),
                    @"tips": @""};
            message.type = GJGCChatFriendContentTypeTransfer;
        }
            break;
        default:
            break;
    }
    return message;
}

+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg{
    
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

@end
