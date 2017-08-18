//
//  LMMessageTool.m
//  Connect
//
//  Created by MoHuilin on 2017/3/29.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageTool.h"
#import "ConnectTool.h"
#import "GJGCChatFriendCellStyle.h"
#import "GJGCChatContentEmojiParser.h"
#import "LMRamGroupInfo.h"
#import "GJGCChatSystemNotiCellStyle.h"
#import "LMOtherModel.h"
#import "LMMessageExtendManager.h"
#import "SessionManager.h"
#import "MessageDBManager.h"
#import "GroupDBManager.h"
#import "CameraTool.h"
#import <Photos/Photos.h>
#import "LMMessage.h"
#import "LMIMHelper.h"

@implementation LMMessageTool

+ (NSData *)formateVideoLoacalPath:(GJGCChatFriendContentModel *)messageContent {
    
    AccountInfo *user = nil;
    LMRamGroupInfo *group = nil;
    if ([[SessionManager sharedManager].chatObject isKindOfClass:[AccountInfo class]]) {
        user = (AccountInfo *)[SessionManager sharedManager].chatObject;
    } else if ([[SessionManager sharedManager].chatObject isKindOfClass:[LMRamGroupInfo class]]){
        group = (LMRamGroupInfo *)[SessionManager sharedManager].chatObject;
    }

    //amr
    NSData *date = [NSData dataWithContentsOfFile:messageContent.audioModel.tempEncodeFilePath];
    if (date) {
        NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainAudioCacheDirectory];
        cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                          stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
        
        if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
            GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
        }
        NSString *temWavName = [NSString stringWithFormat:@"%@.wav", messageContent.localMsgId];
        NSString *temWavPath = [cacheDirectory stringByAppendingPathComponent:temWavName];
        GJCFFileCopyFileIsRemove(messageContent.audioModel.localStorePath, temWavPath, YES);
        
        NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", messageContent.localMsgId];
        NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
        
        NSString *amrFileName = [NSString stringWithFormat:@"%@.amr", messageContent.localMsgId];
        NSString *amrFilePath = [cacheDirectory stringByAppendingPathComponent:amrFileName];
        GJCFFileCopyFileIsRemove(messageContent.audioModel.tempEncodeFilePath, amrFilePath, YES);
        messageContent.audioModel.localAMRStorePath = amrFilePath;
        messageContent.audioModel.downloadEncodeCachePath = downloadEncodeCachePath;
        messageContent.audioModel.tempWamFilePath = temWavPath;
    } else {
        date = [NSData dataWithContentsOfFile:messageContent.audioModel.localAMRStorePath];
    }
    
    return date;
}

+ (ChatMessageInfo *)chatMessageInfoWithMessageOwer:(NSString *)msgOwer messageType:(GJGCChatFriendContentType)messageType sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = [ConnectTool generateMessageId];
    chatMessage.messageOwer = msgOwer;
    chatMessage.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMessage.messageType = messageType;
    chatMessage.from = sender;
    chatMessage.chatType = chatType;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSending;
    return chatMessage;
}

+ (TextMessage *)makeTextWithMessageText:(NSString *)msgText {
    TextMessage *text = [TextMessage new];
    text.content = msgText;
    return text;
}

+ (ChatMessageInfo *)makeTextChatMessageWithMessageText:(NSString *)msgText msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeText sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeTextWithMessageText:msgText];
    return chatMessage;
}

+ (EmotionMessage *)makeEmotionWithGifID:(NSString *)gifId {
    EmotionMessage *emotion = [EmotionMessage new];
    emotion.content = gifId;
    return emotion;
}

+ (ChatMessageInfo *)makeEmotionChatMessageWithGifID:(NSString *)gifId  msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeGif sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeEmotionWithGifID:gifId];
    return chatMessage;
}


+ (PaymentMessage *)makeRecipetWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize {
    PaymentMessage *payment = [PaymentMessage new];
    payment.hashId = hashId;
    payment.paymentType = paymentType;
    payment.amount = amount;
    payment.tips = tips;
    payment.memberSize = memberSize;
    return payment;
}

+ (ChatMessageInfo *)makeRecipetChatMessageWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypePayReceipt sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeRecipetWithHashId:hashId paymentType:paymentType amount:amount tips:tips memberSize:memberSize];
    return chatMessage;
}

+ (TransferMessage *)makeTransferWithHashId:(NSString *)hashId transferType:(int)transferType amount:(int64_t)amount tips:(NSString *)tips {
    TransferMessage *transfer = [TransferMessage new];
    transfer.amount = amount;
    transfer.transferType = transferType;
    transfer.tips = tips;
    transfer.hashId = hashId;
    return transfer;
}

+ (ChatMessageInfo *)makeTransferChatMessageWithHashId:(NSString *)hashId transferType:(TransferMessageType)transferType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeTransfer sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeTransferWithHashId:hashId transferType:transferType amount:amount tips:tips];
    return chatMessage;
}

+ (LuckPacketMessage *)makeLuckyPackageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips {
    LuckPacketMessage *luck = [LuckPacketMessage new];
    luck.hashId = hashId;
    luck.tips = tips;
    luck.amount = amount;
    luck.luckyType = luckType;

    return luck;
}

+ (ChatMessageInfo *)makeLuckyPackageChatMessageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeRedEnvelope sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeLuckyPackageWithHashId:hashId luckType:luckType amount:amount tips:tips];
    return chatMessage;
}


+ (CardMessage *)makeCardWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid {
    CardMessage *card = [CardMessage new];
    card.uid = uid;
    card.avatar = avatar;
    card.username = username;
    return card;
}

+ (ChatMessageInfo *)makeCardChatMessageWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeNameCard sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeCardWithUsername:username avatar:avatar uid:uid];
    return chatMessage;
}


+ (WebsiteMessage *)makeWebSiteWithURL:(NSString *)url walletLinkType:(LMWalletlinkType)walletLinkType {
    WebsiteMessage *website = [WebsiteMessage new];
    website.URL = url;
    switch (walletLinkType) {
        case LMWalletlinkTypeOuterTransfer: {
            website.title = LMLocalizedString(@"Wallet Wallet Out Send Share", nil);
            website.subtitle = LMLocalizedString(@"Wallet Click to recive payment", nil);
        }
            break;
        case LMWalletlinkTypeOuterPacket: {
            website.title = LMLocalizedString(@"Wallet Send a lucky packet", nil);
            website.subtitle = LMLocalizedString(@"Wallet Click to open lucky packet", nil);
        }
            break;
        case LMWalletlinkTypeOuterCollection: {
            website.title = LMLocalizedString(@"Wallet Send the payment connection", nil);
            website.subtitle = LMLocalizedString(@"Wallet Click to transfer bitcoin", nil);
        }
            break;
        default:
            break;
    }
    return website;
}

+ (ChatMessageInfo *)makeWebSiteChatMessageWithURL:(NSString *)url walletLinkType:(LMWalletlinkType)walletLinkType msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatWalletLink sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeWebSiteWithURL:url walletLinkType:walletLinkType];
    return chatMessage;
}

+ (LocationMessage *)makeLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address {
    LocationMessage *location = [LocationMessage new];
    location.latitude = latitude;
    location.longitude = longitude;
    location.address = address;
    return location;
}

+ (ChatMessageInfo *)makeLocationChatMessageWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeMapLocation sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeLocationWithLatitude:latitude longitude:longitude address:address];
    return chatMessage;
}

+ (VoiceMessage *)makeVoiceWithSize:(int)size url:(NSString *)url{
    VoiceMessage *voice = [VoiceMessage new];
    voice.timeLength = size;
    voice.URL = url;
    return voice;
}

+ (ChatMessageInfo *)makeVoiceChatMessageWithSize:(int)size url:(NSString *)url msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeAudio sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeVoiceWithSize:size url:url];
    return chatMessage;
}

+ (VideoMessage *)makeVideoWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover {
    VideoMessage *video = [VideoMessage new];
    video.size = size;
    video.imageWidth = videoCoverW;
    video.imageHeight = videoCoverH;
    video.timeLength = time;
    video.URL = videoUrl;
    video.cover = videoCover;

    return video;
}

+ (ChatMessageInfo *)makeVideoChatMessageWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeVideo sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeVideoWithSize:size time:time videoCoverW:videoCoverW videoCoverH:videoCoverH videoUrl:videoUrl videoCover:videoCover];
    return chatMessage;
}

+ (PhotoMessage *)makePhotoWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage {
    PhotoMessage *photo = [PhotoMessage new];
    photo.imageWidth = ImageW;
    photo.imageHeight = imageH;
    photo.thum = thumImage;
    photo.URL = oriImage;
    return photo;
}

+ (ChatMessageInfo *)makePhotoChatMessageWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeImage sender:sender chatType:chatType];
    chatMessage.msgContent = [self makePhotoWithImageW:ImageW imageH:imageH oriImage:oriImage thumImage:thumImage];
    return chatMessage;
}

+ (ReadReceiptMessage *)makeReadReceiptWithMsgId:(NSString *)msgId {
    ReadReceiptMessage *readReceipt = [ReadReceiptMessage new];
    readReceipt.messageId = msgId;
    return readReceipt;
}

+ (ChatMessageInfo *)makeReadReceiptChatMessageWithMsgId:(NSString *)msgId msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeSnapChatReadedAck sender:sender chatType:chatType];
    chatMessage.msgContent = [self makeReadReceiptWithMsgId:msgId];
    return chatMessage;
}

+ (ChatMessageInfo *)makeDestructChatMessageWithTime:(int)time msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatFriendContentTypeSnapChat sender:sender chatType:0];
    chatMessage.msgContent = [self makeDestructWithTime:time];
    return chatMessage;
}

+ (DestructMessage *)makeDestructWithTime:(int)time {
    DestructMessage *destruct = [DestructMessage new];
    destruct.time = time;
    
    return destruct;
}

+ (NotifyMessage *)makeNotifyMessageWithTips:(NSString *)tips ext:(NSString *)ext notifyType:(NotifyMessageType)notifyType{
    NotifyMessage *notify = [self makeNotifyNormalMessageWithTips:tips];
    notify.extion = ext;
    notify.notifyType = notifyType;
    return notify;
}

+ (NotifyMessage *)makeNotifyNormalMessageWithTips:(NSString *)tips {
    NotifyMessage *notify = [NotifyMessage new];
    notify.content = tips;
    return notify;
}

+ (ChatMessageInfo *)makeNotifyMessageWithMessageOwer:(NSString *)messageOwer content:(NSString *)content noteType:(NotifyMessageType)noteType ext:(id)ext {
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = [ConnectTool generateMessageId];
    chatMessage.messageOwer = messageOwer;
    chatMessage.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMessage.messageType = GJGCChatFriendContentTypeStatusTip;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.msgContent = [self makeNotifyMessageWithTips:content ext:ext notifyType:noteType];
    return chatMessage;
}

+ (ChatMessageInfo *)makeJoinGroupChatMessageWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token msgOwer:(NSString *)msgOwer sender:(NSString *)sender {
    ChatMessageInfo *chatMessage = [self chatMessageInfoWithMessageOwer:msgOwer messageType:GJGCChatInviteToGroup sender:sender chatType:0];
    chatMessage.msgContent = [self makeJoinGroupWithAvatar:avatar groupId:groupId groupName:groupName token:token];
    return chatMessage;
}

+ (JoinGroupMessage *)makeJoinGroupWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token{
    JoinGroupMessage *joinGroup = [JoinGroupMessage new];
    joinGroup.avatar = avatar;
    joinGroup.groupId = groupId;
    joinGroup.groupName = groupName;
    joinGroup.token = token;
    return joinGroup;
}

+ (GPBMessage *)packageOriginMsgWithChatContent:(GJGCChatFriendContentModel *)messageContent snapTime:(int)snapTime {
    GPBMessage *msg = nil;
    switch (messageContent.contentType) {
            
        case GJGCChatFriendContentTypeText:
        {
            TextMessage *text = [self makeTextWithMessageText:messageContent.originTextMessage];
            text.snapTime = snapTime;
            if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypeGroup) {
                /// group at @@
                text.atAddressesArray = messageContent.noteGroupMemberAddresses;
            }
            msg = text;
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            LocationMessage *location = [self makeLocationWithLatitude:messageContent.locationLatitude longitude:messageContent.locationLatitude address:messageContent.originTextMessage];
            msg = location;
        }
            break;
            
        case GJGCChatFriendContentTypeAudio:
        {
            VoiceMessage *voice = [self makeVoiceWithSize:messageContent.audioModel.duration url:nil];
            voice.snapTime = snapTime;
            msg = voice;
        }
            break;
            
        case GJGCChatFriendContentTypeVideo:
        {
            VideoMessage *video = [self makeVideoWithSize:(int)messageContent.videoDuration time:messageContent.size videoCoverW:messageContent.originImageWidth videoCoverH:messageContent.originImageHeight videoUrl:nil videoCover:nil];
            video.snapTime = snapTime;
            msg = video;
        }
            break;
            
        case GJGCChatFriendContentTypeImage:
        {
            PhotoMessage *photo = [self makePhotoWithImageW:messageContent.originImageWidth imageH:messageContent.originImageHeight oriImage:nil thumImage:nil];
            photo.snapTime = snapTime;
            msg = photo;
        }
            break;
            
        case GJGCChatFriendContentTypeGif: {
            EmotionMessage *emotion = [self makeEmotionWithGifID:messageContent.gifLocalId];
            emotion.snapTime = snapTime;
            msg = emotion;
        }
            break;
        case GJGCChatFriendContentTypePayReceipt:
        {
            PaymentMessage *payment = [self makeRecipetWithHashId:messageContent.hashID paymentType:messageContent.isCrowdfundRceipt?1:0 amount:messageContent.amount tips:messageContent.tipNote memberSize:messageContent.memberCount];
            msg = payment;
        }
            break;

        case GJGCChatFriendContentTypeTransfer:
        {
            TransferMessage *transfer = [self makeTransferWithHashId:messageContent.hashID transferType:0 amount:messageContent.amount tips:messageContent.tipNote];
            msg = transfer;
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: {
            
            LuckPacketMessage *luck = [self makeLuckyPackageWithHashId:messageContent.hashID luckType:0 amount:messageContent.amount tips:messageContent.tipNote];
            msg = luck;
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            CardMessage *card = [self makeCardWithUsername:messageContent.contactName.string avatar:messageContent.contactAvatar uid:messageContent.contactPublickey];
            msg = card;
        }
            break;
            
        case GJGCChatWalletLink: {
            WebsiteMessage *website = [self makeWebSiteWithURL:messageContent.originTextMessage walletLinkType:messageContent.walletLinkType];;
            msg = website;
        }
            break;
            
        default:
            break;
    }

    return msg;
}


+ (ChatMessage *)chatMsgWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext {
    /// chat msg
    ChatMessage *chatMsg = [[ChatMessage alloc] init];
    chatMsg.from = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    chatMsg.to = to;
    chatMsg.msgType = msgType;
    chatMsg.ext = ext;
    chatMsg.msgTime = [[NSDate date] timeIntervalSince1970] * 1000;
    chatMsg.chatType = chatType;
    
    return chatMsg;
}


+ (ChatMessageInfo *)chatMsgInfoWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType msgContent:(GPBMessage *)msgContent {
    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = [ConnectTool generateMessageId];
    messageInfo.messageType = msgType;
    messageInfo.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    messageInfo.messageOwer = to;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.msgContent = msgContent;
    messageInfo.chatType = chatType;
    messageInfo.from = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    
    return messageInfo;
}

+ (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(ChatMessageInfo *)chatMessage {
    AccountInfo *user = nil;
    LMRamGroupInfo *group = nil;
    if ([[SessionManager sharedManager].chatObject isKindOfClass:[AccountInfo class]]) {
        user = (AccountInfo *)[SessionManager sharedManager].chatObject;
    } else if ([[SessionManager sharedManager].chatObject isKindOfClass:[LMRamGroupInfo class]]){
        group = (LMRamGroupInfo *)[SessionManager sharedManager].chatObject;
    }
    GJGCChatFriendContentType type = GJGCChatFriendContentTypeNotFound;
    if (!group && !user) {
        return type;
    }
    chatContentModel.localMsgId = chatMessage.messageId;
    switch (chatMessage.messageType) {
        case GJGCChatFriendContentTypeAudio:
        {
            VoiceMessage *voice = (VoiceMessage *)chatMessage.msgContent;
            chatContentModel.contentType = GJGCChatFriendContentTypeAudio;
            type = chatContentModel.contentType;
            chatContentModel.audioModel.remotePath = voice.URL;
            if (voice.URL.length && chatContentModel.isFromSelf) {
                chatContentModel.uploadSuccess = YES;
                chatContentModel.uploadProgress = 1.f;
            }
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainAudioCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            
            NSString *temWavName = [NSString stringWithFormat:@"%@.wav", chatMessage.messageId];
            NSString *temWavPath = [cacheDirectory stringByAppendingPathComponent:temWavName];
            
            NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", chatMessage.messageId];
            NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
            
            NSString *amrFileName = [NSString stringWithFormat:@"%@.amr", chatMessage.messageId];
            NSString *amrFilePath = [cacheDirectory stringByAppendingPathComponent:amrFileName];
            chatContentModel.audioModel.localAMRStorePath = amrFilePath;
            chatContentModel.audioModel.downloadEncodeCachePath = downloadEncodeCachePath;
            chatContentModel.audioModel.tempWamFilePath = temWavPath;
            chatContentModel.audioModel.duration = voice.timeLength;
            chatContentModel.audioDuration = [GJGCChatFriendCellStyle formateAudioDuration:GJCFStringFromInt(chatContentModel.audioModel.duration)];
            
            if (GJCFFileIsExist(chatContentModel.audioModel.localAMRStorePath)) {
                chatContentModel.audioIsDownload = YES;
            }
        }
            break;
        case GJGCChatFriendContentTypeText:{
            chatContentModel.contentType = GJGCChatFriendContentTypeText;
            type = chatContentModel.contentType;
            TextMessage *text = (TextMessage *)chatMessage.msgContent;
            if (!GJCFNSCacheGetValue(text.content)) {
                [GJGCChatFriendCellStyle formateSimpleTextMessage:text.content];
            }
            chatContentModel.originTextMessage = text.content;
        }
            break;
        case GJGCChatWalletLink:{
            chatContentModel.contentType = GJGCChatWalletLink;
            WebsiteMessage *webSite = (WebsiteMessage *)chatMessage.msgContent;
            type = chatContentModel.contentType;
            chatContentModel.originTextMessage = webSite.URL;
            if ([[GJGCChatContentEmojiParser sharedParser] isWalletUrlString:chatContentModel.originTextMessage]) {
                chatContentModel.contentType = GJGCChatWalletLink;
                type = chatContentModel.contentType;
                if ([webSite.URL containsString:@"transfer?"]) {
                    chatContentModel.walletLinkType = LMWalletlinkTypeOuterTransfer;
                } else if ([webSite.URL containsString:@"packet?"]) {
                    chatContentModel.walletLinkType = LMWalletlinkTypeOuterPacket;
                } else if ([webSite.URL containsString:@"pay?"]) {
                    chatContentModel.walletLinkType = LMWalletlinkTypeOuterCollection;
                }
            } else {
                chatContentModel.walletLinkType = LMWalletlinkTypeOuterOther;
                chatContentModel.linkTitle = webSite.title;
                chatContentModel.linkSubtitle = webSite.subtitle;
                chatContentModel.linkImageUrl = webSite.img;
            }
        }
            break;
        case GJGCChatInviteToGroup:{
            chatContentModel.contentType = GJGCChatInviteToGroup;
            type = chatContentModel.contentType;
            JoinGroupMessage *joinGroup = (JoinGroupMessage *)chatMessage.msgContent;
            chatContentModel.contactName = [GJGCChatSystemNotiCellStyle formatetGroupInviteGroupName:joinGroup.groupName reciverName:nil isSystemMessage:NO isSendFromMySelf:chatContentModel.isFromSelf];
            chatContentModel.groupIdentifier = joinGroup.groupId;
            chatContentModel.inviteToken = joinGroup.token;
            chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatInviteToGroup withNote:nil isCrowding:NO];
            chatContentModel.contactAvatar = joinGroup.avatar;
        }
            break;
        case GJGCChatApplyToJoinGroup:{
            ReviewedStatus *reviewedStatus = (ReviewedStatus *)chatMessage.msgContent;
            Reviewed *reviewed = reviewedStatus.review;
            chatContentModel.contentType = GJGCChatApplyToJoinGroup;
            type = chatContentModel.contentType;
            chatContentModel.contactName = [GJGCChatSystemNotiCellStyle formatetGroupInviteGroupName:reviewed.name reciverName:reviewed.userInfo.username isSystemMessage:YES isSendFromMySelf:chatContentModel.isFromSelf];
            chatContentModel.groupIdentifier = reviewed.identifier;
            chatContentModel.contactAvatar = reviewed.userInfo.avatar;
            chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatApplyToJoinGroup withNote:nil isCrowding:NO];
            LMOtherModel *model = [[LMOtherModel alloc] init];
            BOOL isNoted = reviewedStatus.newaccept;
            NSString *groupId = chatContentModel.groupIdentifier;
            NSString *applyUserPubkey = reviewed.userInfo.pubKey;
            BOOL userIsInGroup = [[GroupDBManager sharedManager] userWithAddress:[LMIMHelper getAddressByPubkey:applyUserPubkey] isinGroup:groupId];
            if (userIsInGroup) {
                chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:YES refused:NO isNoted:isNoted];
            } else{
                BOOL refused = reviewedStatus.refused;
                if (refused) {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:YES refused:refused isNoted:isNoted];
                    model.handled = YES;
                    model.refused = refused;
                } else {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:NO refused:NO isNoted:isNoted];
                }
            }
            model.userIsinGroup = userIsInGroup;
            model.userName = reviewed.userInfo.username;
            model.headImageViewUrl = reviewed.userInfo.avatar;
            model.contentName = reviewed.tips;
            model.sourceType = reviewed.source;
            model.verificationCode = reviewed.verificationCode;
            model.publickey = applyUserPubkey;
            model.groupIdentifier = groupId;
            chatContentModel.contentModel = model;
        }
            break;
        case GJGCChatFriendContentTypeNameCard:{
            chatContentModel.contentType = GJGCChatFriendContentTypeNameCard;
            type = chatContentModel.contentType;
            CardMessage *card = (CardMessage *)chatMessage.msgContent;
            chatContentModel.contactAvatar = card.avatar;
            chatContentModel.contactPublickey = card.uid;
            chatContentModel.contactAddress = nil;
            NSString *name = card.username;
            if (name != nil) {
                NSMutableAttributedString *nameText = [[NSMutableAttributedString alloc] initWithString:name];
                [nameText addAttribute:NSFontAttributeName
                                 value:[UIFont systemFontOfSize:FONT_SIZE(32)]
                                 range:NSMakeRange(0, name.length)];
                [nameText addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor whiteColor]
                                 range:NSMakeRange(0, name.length)];
                
                chatContentModel.contactName = nameText;
            }
            chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateNameCardSubTipsIsFromSelf:chatContentModel.isFromSelf];
        }
            break;
        case GJGCChatFriendContentTypeTransfer:{
            chatContentModel.contentType = GJGCChatFriendContentTypeTransfer;
            type = chatContentModel.contentType;
            TransferMessage *transfer = (TransferMessage *)chatMessage.msgContent;
            int status = [[LMMessageExtendManager sharedManager] getStatus:transfer.hashId];
            chatContentModel.transferMessage = [GJGCChatSystemNotiCellStyle formateTransferWithAmount:transfer.amount isSendToMe:!chatContentModel.isFromSelf isOuterTransfer:[SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem];
            chatContentModel.transferSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypeTransfer withNote:transfer.tips isCrowding:NO];
            if ([SessionManager sharedManager].talkType != GJGCChatFriendTalkTypePostSystem) {
                chatContentModel.transferStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:status == 0 ? 1 : status];
            }

            chatContentModel.hashID = transfer.hashId;
            chatContentModel.amount = transfer.amount;
            chatContentModel.isOuterTransfer = transfer.transferType == 3;
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope:{
            chatContentModel.contentType = GJGCChatFriendContentTypeRedEnvelope;
            type = chatContentModel.contentType;
            LuckPacketMessage *lucky = (LuckPacketMessage *)chatMessage.msgContent;
            chatContentModel.redBagTipMessage = [GJGCChatSystemNotiCellStyle formateRedBagWithMessage:lucky.tips isOuterTransfer:NO];
            chatContentModel.redBagSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypeRedEnvelope withNote:lucky.tips isCrowding:NO];
            chatContentModel.hashID = lucky.hashId;
        }
            break;
        case GJGCChatFriendContentTypePayReceipt:{
            chatContentModel.contentType = GJGCChatFriendContentTypePayReceipt;
            type = chatContentModel.contentType;
            PaymentMessage *payment = (PaymentMessage *)chatMessage.msgContent;
            
            long long int amount = payment.amount;
            int totalMember = payment.memberSize;
            BOOL isCrowdfundRceipt = payment.paymentType == 1;
            NSString *note = payment.tips;
            int status = [[LMMessageExtendManager sharedManager] getStatus:payment.hashId];
            int payCount = [[LMMessageExtendManager sharedManager] getPayCount:payment.hashId];
            chatContentModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:totalMember payCount:payCount isCrowding:isCrowdfundRceipt transStatus:status];
            chatContentModel.payOrReceiptMessage = [GJGCChatSystemNotiCellStyle formateRecieptWithAmount:amount isSendToMe:!chatContentModel.isFromSelf isCrowdfundRceipt:isCrowdfundRceipt withNote:note];
            chatContentModel.payOrReceiptSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypePayReceipt withNote:note isCrowding:isCrowdfundRceipt];
            chatContentModel.hashID = payment.hashId;
            chatContentModel.amount = amount;
            chatContentModel.memberCount = totalMember;
            chatContentModel.isCrowdfundRceipt = isCrowdfundRceipt;
        }
            break;
        case GJGCChatFriendContentTypeSnapChat:{
            chatContentModel.contentType = GJGCChatFriendContentTypeSnapChat;
            type = chatContentModel.contentType;
            DestructMessage *destruct = (DestructMessage *)chatMessage.msgContent;
            chatContentModel.snapChatTipString = [GJGCChatSystemNotiCellStyle formateOpensnapChatWithTime:destruct.time isSendToMe:![chatMessage.from isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key] chatUserName:user.normalShowName];
        }
            break;
        case GJGCChatFriendContentTypeImage:{
            chatContentModel.contentType = GJGCChatFriendContentTypeImage;
            type = chatContentModel.contentType;
            PhotoMessage *photo = (PhotoMessage *)chatMessage.msgContent;
            chatContentModel.encodeFileUrl = photo.URL;
            chatContentModel.encodeThumbFileUrl = photo.thum;
            
            if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem) {
                if (photo.URL.length && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            } else{
                if (photo.URL.length && photo.thum.length && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            }
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            
            NSString *temOriginName = [NSString stringWithFormat:@"%@.jpg", chatMessage.messageId];
            NSString *thumbImageName = [NSString stringWithFormat:@"%@-thumb.jpg", chatMessage.messageId];
            NSString *temOriginPath = [cacheDirectory stringByAppendingPathComponent:temOriginName];
            NSString *thumbImageNamePath = [cacheDirectory stringByAppendingPathComponent:thumbImageName];
            
            NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", chatMessage.messageId];
            NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
            
            NSString *downloadThumbencodeFileName = [NSString stringWithFormat:@"%@-thumb.encode", chatMessage.messageId];
            NSString *downloadThumbEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadThumbencodeFileName];
            
            chatContentModel.imageOriginDataCachePath = temOriginPath;
            chatContentModel.downEncodeImageCachePath = downloadEncodeCachePath;
            chatContentModel.downThumbEncodeImageCachePath = downloadThumbEncodeCachePath;
            chatContentModel.thumbImageCachePath = thumbImageNamePath;
            chatContentModel.originImageHeight = photo.imageHeight;
            chatContentModel.originImageWidth = photo.imageWidth;

            if (GJCFFileIsExist(chatContentModel.thumbImageCachePath)) {
                chatContentModel.isDownloadThumbImage = YES;
                NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.thumbImageCachePath];
                chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
            }
            if (GJCFFileIsExist(chatContentModel.imageOriginDataCachePath)) {
                chatContentModel.isDownloadImage = YES;
                if (!chatContentModel.messageContentImage) {
                    NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.imageOriginDataCachePath];
                    chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
                }
            }
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:{
            chatContentModel.contentType = GJGCChatFriendContentTypeMapLocation;
            type = chatContentModel.contentType;
            LocationMessage *location = (LocationMessage *)chatMessage.msgContent;
            chatContentModel.encodeFileUrl = location.screenShot;
            
            if (location.screenShot.length && chatContentModel.isFromSelf) {
                chatContentModel.uploadSuccess = YES;
                chatContentModel.uploadProgress = 1.f;
            }
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            
            NSString *temOriginName = [NSString stringWithFormat:@"%@.jpg", chatMessage.messageId];
            NSString *temOriginPath = [cacheDirectory stringByAppendingPathComponent:temOriginName];
            
            NSString *downloadencodeFileName = [NSString stringWithFormat:@"%@.encode", chatMessage.messageId];
            NSString *downloadEncodeCachePath = [cacheDirectory stringByAppendingPathComponent:downloadencodeFileName];
            
            chatContentModel.locationLongitude = location.longitude;
            chatContentModel.locationLatitude = location.latitude;
            chatContentModel.originTextMessage = location.address;
            chatContentModel.locationMessage = [GJGCChatSystemNotiCellStyle formatLocationMessage:chatContentModel.originTextMessage];
            
            chatContentModel.locationImageOriginDataCachePath = temOriginPath;
            chatContentModel.locationImageDownPath = downloadEncodeCachePath;
            
            if (GJCFFileIsExist(chatContentModel.locationImageOriginDataCachePath)) {
                NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.locationImageOriginDataCachePath];
                chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
            }
        }
            break;
        case GJGCChatFriendContentTypeVideo:{
            chatContentModel.contentType = GJGCChatFriendContentTypeVideo;
            type = chatContentModel.contentType;
            VideoMessage *video = (VideoMessage *)chatMessage.msgContent;
            chatContentModel.videoDuration = video.size;
            
            int fileSize = video.size;
            float nM = fileSize / 1024 / 1024.f;
            int nK = (fileSize % (1024 * 1024)) / 1024;
            NSString *videoSize = [NSString stringWithFormat:@"%dkb", nK];
            NSString *message = [NSString stringWithFormat:LMLocalizedString(@"Chat Video compress size Are yousend", nil), videoSize];
            if (nM >= 1) {
                videoSize = [NSString stringWithFormat:@"%.1fM", nM];
                message = [NSString stringWithFormat:LMLocalizedString(@"Chat Video compress size Are yousend", nil), videoSize];
            }
            
            chatContentModel.videoSize = videoSize;
            chatContentModel.encodeFileUrl = video.cover;
            chatContentModel.videoEncodeUrl = video.URL;
            
            if ([SessionManager sharedManager].talkType == GJGCChatFriendTalkTypePostSystem) {
                if (video.URL.length && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            } else{
                if (video.URL.length && video.cover.length && chatContentModel.isFromSelf) {
                    chatContentModel.uploadSuccess = YES;
                    chatContentModel.uploadProgress = 1.f;
                }
            }
            
            chatContentModel.originImageHeight = video.imageHeight;
            chatContentModel.originImageWidth = video.imageWidth;
            
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainVideoCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:group?group.groupIdentifer:user.address];
            
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }

            chatContentModel.videoDownCoverEncodePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-coverimage.decode", chatMessage.messageId]];
            chatContentModel.videoDownVideoEncodePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.decode", chatMessage.messageId]];

            chatContentModel.videoOriginCoverImageCachePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-coverimage.jpg", chatMessage.messageId]];
            chatContentModel.videoOriginDataPath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", chatMessage.messageId]];
            chatContentModel.videoIsDownload = GJCFFileRead(chatContentModel.videoOriginDataPath);
            
            if (GJCFFileIsExist(chatContentModel.videoOriginCoverImageCachePath)) {
                NSData *imageData = [NSData dataWithContentsOfFile:chatContentModel.videoOriginCoverImageCachePath];
                chatContentModel.messageContentImage = [UIImage imageWithData:imageData];
            }
        }
            break;
        case GJGCChatFriendContentTypeGif:{
            chatContentModel.contentType = GJGCChatFriendContentTypeGif;
            EmotionMessage *emotion = (EmotionMessage *)chatMessage.msgContent;
            chatContentModel.gifLocalId = emotion.content;
            type = chatContentModel.contentType;
        }
            break;
        case GJGCChatFriendContentTypeStatusTip:{
            chatContentModel.contentType = GJGCChatFriendContentTypeStatusTip;
            type = chatContentModel.contentType;
            NotifyMessage *notify = (NotifyMessage *)chatMessage.msgContent;
            switch (notify.notifyType) {
                case NotifyMessageTypeNormal:
                {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateTipStringWithTipMessage:notify.content];
                }
                    break;
                case NotifyMessageTypeGrabRULLuckyPackage:
                {
                    chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateTipStringWithTipMessage:notify.content];
                    chatContentModel.statusIcon = @"luckybag";
                    chatContentModel.hashID = notify.extion;
                }
                    break;
                case NotifyMessageTypeLuckyPackageSender_Reciver:
                {
                    NSArray *sender_reciverArray = [notify.content componentsSeparatedByString:@"/"];
                    if (sender_reciverArray.count == 2) {
                        NSString *senderAddress = [sender_reciverArray firstObject];
                        NSString *reciverAddress = [sender_reciverArray lastObject];
                        NSString *garbName = nil;
                        NSString *senderName = nil;
                        switch ([SessionManager sharedManager].talkType) {
                            case GJGCChatFriendTalkTypePrivate: {
                                //reciver is self
                                if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                    garbName = LMLocalizedString(@"Chat You", nil);
                                    senderName = user.normalShowName;
                                }
                                //sender is self
                                if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                    senderName = LMLocalizedString(@"Chat You", nil);
                                    garbName = user.normalShowName;
                                }
                            }
                                break;
                            case GJGCChatFriendTalkTypeGroup: {
                                for (LMRamMemberInfo *groupMember in group.membersArray) {
                                    //sender is self
                                    if ([senderAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                        senderName = LMLocalizedString(@"Chat You", nil);
                                    } else {
                                        if ([groupMember.address isEqualToString:senderAddress]) {
                                            senderName = groupMember.username;
                                        }
                                    }
                                    //reciver is self
                                    if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                        garbName = LMLocalizedString(@"Chat You", nil);
                                    } else {
                                        if ([groupMember.address isEqualToString:reciverAddress]) {
                                            garbName = groupMember.username;
                                        }
                                    }
                                }
                            }
                                break;
                            case GJGCChatFriendTalkTypePostSystem: {
                                garbName = LMLocalizedString(@"Chat You", nil);
                                senderName = LMLocalizedString(@"Connect term", nil);
                            }
                                break;
                            default:
                                break;
                        }
                        chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateRedbagTipWithSenderName:senderName garbName:garbName];
                        chatContentModel.statusIcon = @"luckybag";
                    }
                }
                    break;
                    
                case NotifyMessageTypePaymentReciver_Payer:
                {
                    NSArray *reciverPayerArray = [notify.content componentsSeparatedByString:@"/"];
                    if (reciverPayerArray.count == 2) { //reference socket tpe:5 extension :9
                        NSString *payName = nil;
                        NSString *reciverName = nil;
                        NSString *payAddress = [reciverPayerArray lastObject];
                        NSString *reciverAddress = [reciverPayerArray firstObject];
                        switch ([SessionManager sharedManager].talkType) {
                            case GJGCChatFriendTalkTypePrivate: {
                                if ([payAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                    payName = LMLocalizedString(@"Chat You", nil);
                                    reciverName = user.normalShowName;
                                }
                                if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                    reciverName = LMLocalizedString(@"Chat You", nil);
                                    payName = user.normalShowName;
                                }
                                chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:payName receiptName:reciverName isCrowding:NO];
                            }
                                break;
                            case GJGCChatFriendTalkTypeGroup: {
                                for (LMRamMemberInfo *groupMember in group.membersArray) {
                                    if ([payAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                        payName = LMLocalizedString(@"Chat You", nil);
                                    } else {
                                        if ([groupMember.address isEqualToString:payAddress]) {
                                            payName = groupMember.username;
                                        }
                                    }
                                    if ([reciverAddress isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                                        reciverName = LMLocalizedString(@"Chat You", nil);
                                    } else {
                                        if ([groupMember.address isEqualToString:reciverAddress]) {
                                            reciverName = groupMember.username;
                                        }
                                    }
                                }
                                chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateReceiptTipWithPayName:payName receiptName:reciverName isCrowding:YES];
                            }
                                break;
                            default:
                                break;
                        }
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case GJGCChatInviteNewMemberTip:{
            chatContentModel.contentType = GJGCChatFriendContentTypeStatusTip;
            type = chatContentModel.contentType;
        }
            break;
        case GJGCChatFriendContentTypeNoRelationShipTip:{
            chatContentModel.contentType = GJGCChatFriendContentTypeNoRelationShipTip;
            type = chatContentModel.contentType;
        }
            break;
            
        default:
            break;
    }
    return type;
}

+ (GJGCChatFriendContentModel *)packContentModelWithTalkModel:(GJGCChatFriendTalkModel *)talkModel contentType:(GJGCChatFriendContentType)contentType extData:(id)extData{
    GJGCChatFriendContentModel *chatContentModel = [[GJGCChatFriendContentModel alloc] init];
    chatContentModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    chatContentModel.contentType = contentType;
    chatContentModel.localMsgId = [ConnectTool generateMessageId];
    
    switch (contentType) {
        case GJGCChatFriendContentTypeVideo:{
            /*
             NSDictionary *dataDict = @{@"originUrl":originUrl,
             @"filePath":filePath,
             @"videoSize":videoSize};
             */
            NSDictionary *videoDict = (NSDictionary *)extData;
            NSURL *url = [videoDict valueForKey:@"originUrl"];
            NSString *filePath = [videoDict valueForKey:@"filePath"];
            NSString *videoSize = [videoDict valueForKey:@"videoSize"];
            UIImage *coverImage = [self frameImageFromVideoURL:url];
            NSString *cacheDirectory = [[GJCFCachePathManager shareManager] mainVideoCacheDirectory];
            cacheDirectory = [[cacheDirectory stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                              stringByAppendingPathComponent:talkModel.fileDocumentName];
            if (!GJCFFileDirectoryIsExist(cacheDirectory)) {
                GJCFFileProtectCompleteDirectoryCreate(cacheDirectory);
            }
            NSString *videoFileName = [NSString stringWithFormat:@"%@.mp4", chatContentModel.localMsgId];
            NSString *videoFileCoverImageName = [NSString stringWithFormat:@"%@-coverimage.jpg", chatContentModel.localMsgId];
            NSString *videoFileLocalPath = [cacheDirectory stringByAppendingPathComponent:videoFileName];
            NSString *videoFileCoverImageLocalPath = [cacheDirectory stringByAppendingPathComponent:videoFileCoverImageName];
            GJCFFileCopyFileIsRemove(filePath, videoFileLocalPath, YES);
            NSData *coverData = UIImageJPEGRepresentation(coverImage, 1);
            coverData = [CameraTool imageSizeLessthan2K:coverData withOriginImage:coverImage];
            GJCFFileWrite(coverData, videoFileCoverImageLocalPath);
            
            
            chatContentModel.messageContentImage = coverImage;
            chatContentModel.originImageWidth = coverImage.size.width;
            chatContentModel.originImageHeight = coverImage.size.height;
            chatContentModel.videoIsDownload = YES;
            chatContentModel.videoOriginDataPath = videoFileLocalPath;
            chatContentModel.videoOriginCoverImageCachePath = videoFileCoverImageLocalPath;
            chatContentModel.videoDuration = [self durationWithVideo:url];
            chatContentModel.videoSize = videoSize;
            chatContentModel.size = [[videoDict valueForKey:@"fileSize"] intValue];
            
        }
            break;
        case GJGCChatFriendContentTypeTransfer:{
            LMTransactionModel *transactionModel = (LMTransactionModel *)extData;
            chatContentModel.transferSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:contentType withNote:transactionModel.note isCrowding:YES];
            chatContentModel.transferStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:1 payCount:1 isCrowding:NO transStatus:1];
            chatContentModel.hashID = transactionModel.hashId;
            chatContentModel.tipNote = transactionModel.note;
            chatContentModel.amount = transactionModel.amount.longLongValue;
            chatContentModel.transferMessage = [GJGCChatSystemNotiCellStyle formateTransferWithAmount:chatContentModel.amount isSendToMe:NO isOuterTransfer:talkModel.talkType == GJGCChatFriendTalkTypePostSystem];
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope:{
            LMTransactionModel *transactionModel = (LMTransactionModel *)extData;
            chatContentModel.redBagTipMessage = [GJGCChatSystemNotiCellStyle formateRedBagWithMessage:transactionModel.note isOuterTransfer:talkModel.talkType == GJGCChatFriendTalkTypePostSystem];
            chatContentModel.redBagSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:GJGCChatFriendContentTypeRedEnvelope withNote:transactionModel.note isCrowding:NO];
            chatContentModel.hashID = transactionModel.hashId;
            chatContentModel.tipNote = transactionModel.note;
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:{
            NSDictionary *locationInfo = (NSDictionary *)extData;
            UIImage *image = [locationInfo valueForKey:@"image"];
            CGFloat locationLatitude = [[locationInfo valueForKey:@"locationLatitude"] doubleValue];
            CGFloat locationLongitude = [[locationInfo valueForKey:@"locationLongitude"] doubleValue];
            NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                        stringByAppendingPathComponent:talkModel.fileDocumentName];
            if (!GJCFFileDirectoryIsExist(filePath)) {
                GJCFFileProtectCompleteDirectoryCreate(filePath);
            }
            
            NSData *imageData = UIImageJPEGRepresentation(image, 1);
            NSString *imageName = [NSString stringWithFormat:@"%@.jpg", chatContentModel.localMsgId];
            NSString *imagePath = [filePath stringByAppendingPathComponent:imageName];
            GJCFFileWrite(imageData, imagePath);
            chatContentModel.locationImageOriginDataCachePath = imagePath;
            chatContentModel.locationLatitude = locationLatitude;
            chatContentModel.locationLongitude = locationLongitude;
            NSString *locationMessage = [locationInfo valueForKey:@"street"];
            chatContentModel.originTextMessage = locationMessage;
            NSMutableAttributedString *descText = [[NSMutableAttributedString alloc] initWithString:locationMessage];
            [descText addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                             range:NSMakeRange(0, locationMessage.length)];
            [descText addAttribute:NSForegroundColorAttributeName
                             value:[UIColor whiteColor]
                             range:NSMakeRange(0, locationMessage.length)];
            chatContentModel.locationMessage = descText;
        }
            break;
        case GJGCChatFriendContentTypeImage:{
            NSDictionary *imageInfo = (NSDictionary *)extData;
            NSString *originPath = [imageInfo objectForKey:@"origin"];
            NSString *thumbPath = [imageInfo objectForKey:@"thumb"];
            NSInteger originWidth = [[imageInfo objectForKey:@"originWidth"] intValue];
            NSInteger originHeight = [[imageInfo objectForKey:@"originHeight"] intValue];
            NSString *messageid = [imageInfo objectForKey:@"imageID"];
            chatContentModel.originImageWidth = originWidth;
            chatContentModel.originImageHeight = originHeight;
            chatContentModel.imageOriginDataCachePath = originPath;
            chatContentModel.thumbImageCachePath = thumbPath;
            chatContentModel.messageContentImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:chatContentModel.imageOriginDataCachePath]];
            NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            filePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                        stringByAppendingPathComponent:talkModel.fileDocumentName];
            if (!GJCFFileDirectoryIsExist(filePath)) {
                GJCFFileProtectCompleteDirectoryCreate(filePath);
            }
            NSString *fileName = [NSString stringWithFormat:@"%@.jpg", messageid];
            chatContentModel.imageOriginDataCachePath = [filePath stringByAppendingPathComponent:fileName];
            GJCFFileCopyFileIsRemove(originPath, chatContentModel.imageOriginDataCachePath, YES);
            
            
            //reset localMessage id
            chatContentModel.localMsgId = messageid;
        }
            break;
        case GJGCChatFriendContentTypeAudio:{
            chatContentModel.audioModel = (GJCFAudioModel *)extData;
            chatContentModel.audioDuration = [GJGCChatFriendCellStyle formateAudioDuration:GJCFStringFromInt(chatContentModel.audioModel.duration)];
            chatContentModel.audioIsDownload = YES;
        }
            break;
        case GJGCChatFriendContentTypeGif:{
            chatContentModel.gifLocalId = extData;
        }
            break;
        case GJGCChatFriendContentTypeText:{
            chatContentModel.originTextMessage = extData;
        }
            break;
        case GJGCChatFriendContentTypeNameCard:{
            AccountInfo *recommandUser = (AccountInfo *)extData;
            chatContentModel.contactAvatar = recommandUser.avatar;
            chatContentModel.contactAddress = recommandUser.address;
            chatContentModel.contactPublickey = recommandUser.pub_key;
            NSMutableAttributedString *nameText = [[NSMutableAttributedString alloc] initWithString:recommandUser.username];
            [nameText addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:FONT_SIZE(32)]
                             range:NSMakeRange(0, recommandUser.username.length)];
            [nameText addAttribute:NSForegroundColorAttributeName
                             value:[UIColor whiteColor]
                             range:NSMakeRange(0, recommandUser.username.length)];
            chatContentModel.contactName = nameText;
            chatContentModel.contactSubTipMessage = [GJGCChatSystemNotiCellStyle formateNameCardSubTipsIsFromSelf:YES];
        }
            break;
        case GJGCChatFriendContentTypePayReceipt:{
            LMTransactionModel *transactionModel = (LMTransactionModel *)extData;
            chatContentModel.tipNote = transactionModel.note;
            chatContentModel.payOrReceiptMessage = [GJGCChatSystemNotiCellStyle formateRecieptWithAmount:[transactionModel.amount longLongValue] isSendToMe:NO isCrowdfundRceipt:transactionModel.isCrowding withNote:transactionModel.note];
            chatContentModel.payOrReceiptSubTipMessage = [GJGCChatSystemNotiCellStyle formateCellLeftSubTipsWithType:contentType withNote:transactionModel.note isCrowding:transactionModel.isCrowding];
            chatContentModel.payOrReceiptStatusMessage = [GJGCChatSystemNotiCellStyle formateRecieptSubTipsWithTotal:transactionModel.size payCount:0 isCrowding:transactionModel.isCrowding transStatus:0];
            chatContentModel.hashID = transactionModel.hashId;
            chatContentModel.amount = [transactionModel.amount longLongValue];
            chatContentModel.memberCount = transactionModel.size;
            chatContentModel.isCrowdfundRceipt = transactionModel.isCrowding;
        }
            break;
        default:
            break;
    }
    chatContentModel.senderAddress = [[LKUserCenter shareCenter] currentLoginUser].address;
    chatContentModel.senderHeadUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
    chatContentModel.senderPublicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    chatContentModel.senderName = [NSMutableString stringWithFormat:@"%@", [[LKUserCenter shareCenter] currentLoginUser].username];
    
    chatContentModel.reciverAddress = talkModel.talkType == GJGCChatFriendTalkTypeGroup ?talkModel.chatGroupInfo.groupIdentifer:talkModel.chatUser.address;
    chatContentModel.reciverHeadUrl = talkModel.headUrl;
    chatContentModel.reciverPublicKey = talkModel.chatIdendifier;
    chatContentModel.reciverName = talkModel.name;
    
    chatContentModel.headUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
    chatContentModel.timeString = [GJGCChatSystemNotiCellStyle formateTime:GJCFDateToString([NSDate date])];
    chatContentModel.sendStatus = GJGCChatFriendSendMessageStatusSending;
    chatContentModel.isFromSelf = YES;
    chatContentModel.talkType = talkModel.talkType;
    
    chatContentModel.sendTime = [[NSDate date] timeIntervalSince1970] * 1000;

    return chatContentModel;
}



// Get the video's center frame as video poster image
+ (UIImage *)frameImageFromVideoURL:(NSURL *)videoURL {
    // result
    UIImage *image = nil;
    // AVAssetImageGenerator
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    // calculate the midpoint time of video
    Float64 duration = CMTimeGetSeconds([asset duration]);
    // 24 frames per second (fps) for film, 30 fps for NTSC (used for TV in North America and
    // Japan), and 25 fps for PAL (used for TV in Europe).
    // Using a timescale of 600, you can exactly represent any number of frames in these systems
    CMTime midpoint = CMTimeMakeWithSeconds(duration / 2.0, 600);
    
    // get the image from
    NSError *error = nil;
    CMTime actualTime;
    // Returns a CFRetained CGImageRef for an asset at or near the specified time.
    // So we should mannully release it
    CGImageRef centerFrameImage = [imageGenerator copyCGImageAtTime:midpoint
                                                         actualTime:&actualTime
                                                              error:&error];
    if (centerFrameImage != NULL) {
        image = [[UIImage alloc] initWithCGImage:centerFrameImage];
        // Release the CFRetained image
        CGImageRelease(centerFrameImage);
    }
    return image;
}

+ (NSUInteger)durationWithVideo:(NSURL *)videoUrl {
    NSUInteger second = 0;
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoUrl];
    Float64 duration = CMTimeGetSeconds(asset.duration);
    if (duration <= 1.0) {
        second = 1;
    } else {
        second = (NSUInteger) (duration + 0.5);
    }
    return second;
}


+ (BOOL)checkRichtextUploadStatuts:(ChatMessageInfo *)chatMessageInfo {
    switch (chatMessageInfo.messageType) {
        case GJGCChatFriendContentTypeAudio: {
            VoiceMessage *voice = (VoiceMessage *)chatMessageInfo.msgContent;
            return voice.URL.length;
        }
            break;
        case GJGCChatFriendContentTypeImage: {
            PhotoMessage *photo = (PhotoMessage *)chatMessageInfo.msgContent;
            return photo.URL.length && photo.thum.length;
        }
            break;
        case GJGCChatFriendContentTypeMapLocation:{
            LocationMessage *location = (LocationMessage *)chatMessageInfo.msgContent;
            return location.screenShot;
        }
            break;
        case GJGCChatFriendContentTypeVideo:{
            VideoMessage *video = (VideoMessage *)chatMessageInfo.msgContent;
            return video.URL.length && video.cover.length;
        }
            break;
        default:
            return YES;
            break;
    }
    return NO;
}

@end
