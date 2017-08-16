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


+ (ChatMessageInfo *)makeTextChatMessageWithMessageText:(NSString *)msgText msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (TextMessage *)makeTextWithMessageText:(NSString *)msgText ;

+ (ChatMessageInfo *)makeEmotionChatMessageWithGifID:(NSString *)gifId  msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (EmotionMessage *)makeEmotionWithGifID:(NSString *)gifId ;


+ (ChatMessageInfo *)makeRecipetChatMessageWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (PaymentMessage *)makeRecipetWithHashId:(NSString *)hashId paymentType:(int)paymentType amount:(int64_t)amount tips:(NSString *)tips memberSize:(int)memberSize ;


+ (ChatMessageInfo *)makeTransferChatMessageWithHashId:(NSString *)hashId transferType:(int)transferType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (TransferMessage *)makeTransferWithHashId:(NSString *)hashId transferType:(int)transferType amount:(int64_t)amount tips:(NSString *)tips ;


+ (ChatMessageInfo *)makeLuckyPackageChatMessageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (LuckPacketMessage *)makeLuckyPackageWithHashId:(NSString *)hashId luckType:(int)luckType amount:(int64_t)amount tips:(NSString *)tips ;

+ (ChatMessageInfo *)makeCardChatMessageWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (CardMessage *)makeCardWithUsername:(NSString *)username avatar:(NSString *)avatar uid:(NSString *)uid ;


+ (ChatMessageInfo *)makeWebSiteChatMessageWithURL:(NSString *)url walletLinkType:(LMWalletlinkType)walletLinkType msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (WebsiteMessage *)makeWebSiteWithURL:(NSString *)url walletLinkType:(LMWalletlinkType)walletLinkType;


+ (ChatMessageInfo *)makeLocationChatMessageWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (LocationMessage *)makeLocationWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude address:(NSString *)address ;


+ (ChatMessageInfo *)makeVoiceChatMessageWithSize:(int)size url:(NSString *)url msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (VoiceMessage *)makeVoiceWithSize:(int)size url:(NSString *)url;


+ (ChatMessageInfo *)makeVideoChatMessageWithSize:(int)size timeStr:(NSString *)timeStr videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (VideoMessage *)makeVideoWithSize:(int)size timeStr:(NSString *)timeStr videoCoverW:(CGFloat)videoCoverW videoCoverH:(CGFloat)videoCoverH videoUrl:(NSString *)videoUrl videoCover:(NSString *)videoCover;


+ (ChatMessageInfo *)makePhotoChatMessageWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (PhotoMessage *)makePhotoWithImageW:(CGFloat )ImageW imageH:(CGFloat)imageH oriImage:(NSString *)oriImage thumImage:(NSString *)thumImage;

+ (ReadReceiptMessage *)makeReadReceiptWithMsgId:(NSString *)msgId;

+ (ChatMessageInfo *)makeDestructChatMessageWithTime:(int)time msgOwer:(NSString *)msgOwer sender:(NSString *)sender;
+ (DestructMessage *)makeDestructWithTime:(int)time;

+ (ChatMessageInfo *)makeNotifyMessageWithMessageOwer:(NSString *)messageOwer content:(NSString *)content noteType:(int)noteType ext:(id)ext;
+ (NotifyMessage *)makeNotifyMessageWithTips:(NSString *)tips;


@end
