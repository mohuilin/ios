//
//  LMMessageTool.h
//  Connect
//
//  Created by MoHuilin on 2017/3/29.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendContentModel.h"
#import "GJGCChatFriendTalkModel.h"
#import "LMTransactionModel.h"
#import "ChatMessageInfo.h"

@interface LMMessageTool : NSObject

/**
 * fomart audio local save path
 */
+ (NSData *)formateVideoLoacalPath:(GJGCChatFriendContentModel *)messageContent;


+ (ChatMessage *)chatMsgWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext;
+ (GPBMessage *)packageOriginMsgWithChatContent:(GJGCChatFriendContentModel *)messageContent snapTime:(int)snapTime;

/**
 * formart message to chatmessage model
 */
+ (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(ChatMessageInfo *)chatMessage;


+ (GJGCChatFriendContentModel *)packContentModelWithTalkModel:(GJGCChatFriendTalkModel *)talkModel contentType:(GJGCChatFriendContentType)contentType extData:(id)extData;

+ (ChatMessageInfo *)chatMsgInfoWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType msgContent:(GPBMessage *)msgContent;

+ (BOOL)checkRichtextUploadStatuts:(ChatMessageInfo *)chatMessage;

#pragma mark - create message


+ (ChatMessageInfo *)makeTextChatMessageWithMessageText:(NSString *)msgText msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (TextMessage *)makeTextWithMessageText:(NSString *)msgText ;

+ (ChatMessageInfo *)makeEmotionChatMessageWithGifID:(NSString *)gifId  msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (EmotionMessage *)makeEmotionWithGifID:(NSString *)gifId ;


+ (ChatMessageInfo *)makeRecipetChatMessageWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (PaymentMessage *)makeRecipetWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize ;


+ (ChatMessageInfo *)makeTransferChatMessageWithHashId:(NSString *)hashId transferType:(TransferMessageType)transferType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (TransferMessage *)makeTransferWithHashId:(NSString *)hashId transferType:(int)transferType amount:(int64_t)amount tips:(NSString *)tips ;


+ (ChatMessageInfo *)makeLuckyPackageChatMessageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (LuckPacketMessage *)makeLuckyPackageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips ;

+ (ChatMessageInfo *)makeCardChatMessageWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (CardMessage *)makeCardWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid ;


+ (ChatMessageInfo *)makeWebSiteChatMessageWithURL:(NSString *)url walletLinkType:(LMWalletlinkType)walletLinkType msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (WebsiteMessage *)makeWebSiteWithURL:(NSString *)url walletLinkType:(LMWalletlinkType)walletLinkType;


+ (ChatMessageInfo *)makeLocationChatMessageWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (LocationMessage *)makeLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address ;


+ (ChatMessageInfo *)makeVoiceChatMessageWithSize:(int)size url:(NSString *)url msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (VoiceMessage *)makeVoiceWithSize:(int)size url:(NSString *)url;


+ (ChatMessageInfo *)makeVideoChatMessageWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (VideoMessage *)makeVideoWithSize:(int)size time:(int)time videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover;


+ (ChatMessageInfo *)makePhotoChatMessageWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (PhotoMessage *)makePhotoWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage;

+ (ReadReceiptMessage *)makeReadReceiptWithMsgId:(NSString *)msgId;

+ (ChatMessageInfo *)makeDestructChatMessageWithTime:(int)time msgOwer:(NSString *)msgOwer sender:(NSString *)sender chatType:(int)chatType;
+ (DestructMessage *)makeDestructWithTime:(int)time;

+ (ChatMessageInfo *)makeNotifyMessageWithMessageOwer:(NSString *)messageOwer content:(NSString *)content noteType:(NotifyMessageType)noteType ext:(id)ext;
+ (NotifyMessage *)makeNotifyNormalMessageWithTips:(NSString *)tips;
+ (NotifyMessage *)makeNotifyMessageWithTips:(NSString *)tips ext:(NSString *)ext notifyType:(NotifyMessageType)notifyType;

+ (ChatMessageInfo *)makeJoinGroupChatMessageWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (JoinGroupMessage *)makeJoinGroupWithAvatar:(NSString *)avatar groupId:(NSString *)groupId groupName:(NSString *)groupName token:(NSString *)token;


@end
