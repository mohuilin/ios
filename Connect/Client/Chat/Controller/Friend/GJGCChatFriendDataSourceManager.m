//
//  GJGCChatFriendDataSourceManager.m
//  Connect
//
//  Created by KivenLin on 14-11-12.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendDataSourceManager.h"
#import "NSString+DictionaryValue.h"
#import "GJCFFileDownloadManager.h"

@interface GJGCChatFriendDataSourceManager () {

}

@end

@implementation GJGCChatFriendDataSourceManager

- (void)dealloc {

}

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id <GJGCChatDetailDataSourceManagerDelegate>)aDelegate {
    if (self = [super initWithTalk:talk withDelegate:aDelegate]) {
        self.title = talk.name;
        [self readLastMessagesFromDB];
    }
    return self;
}

- (GJGCChatFriendContentModel *)addMMMessage:(ChatMessageInfo *)chatMessage {

    [self.orginMessageListArray objectAddObject:chatMessage];

    GJGCChatFriendContentModel *chatContentModel = [[GJGCChatFriendContentModel alloc] init];
    chatContentModel.contentType = chatMessage.messageType;
    chatContentModel.autoMsgid = chatMessage.ID;
    chatContentModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    chatContentModel.sendStatus = chatMessage.sendstatus;
    chatContentModel.sendTime = chatMessage.createTime;
    chatContentModel.publicKey = chatMessage.messageOwer;
    chatContentModel.localMsgId = chatMessage.messageId;
    chatContentModel.talkType = self.taklInfo.talkType;
    chatContentModel.isRead = chatMessage.state > 0;
    chatContentModel.isSnapChatMode = chatMessage.snapTime > 0;
    chatContentModel.snapTime = chatMessage.snapTime;
        
    chatContentModel.isFriend = YES;
    chatContentModel.downloadTaskIdentifier = [[GJCFFileDownloadManager shareDownloadManager] getDownloadIdentifierWithMessageId:[NSString stringWithFormat:@"%@_%@", self.taklInfo.chatIdendifier, chatContentModel.localMsgId]];
    chatContentModel.isDownloading = chatContentModel.downloadTaskIdentifier != nil;

    if (chatMessage.messageType != GJGCChatFriendContentTypeSnapChat) {
        if (![chatMessage.from isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) { //if senderAddress is self ,the message is sent to me
            chatContentModel.isFromSelf = NO;
            chatContentModel.headUrl = self.taklInfo.headUrl;
            chatContentModel.senderName = self.taklInfo.name;
        } else {
            chatContentModel.headUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
            chatContentModel.isFromSelf = YES;
            chatContentModel.senderName = [[LKUserCenter shareCenter] currentLoginUser].normalShowName;
        }
    }
    GJGCChatFriendContentType contentType = [self formateChatFriendContent:chatContentModel withMsgModel:chatMessage];
    if (contentType != GJGCChatFriendContentTypeNotFound) {
        if (![self contentModelByMsgId:chatMessage.messageId]) {
            [self addChatContentModel:chatContentModel];
        }
        if (contentType != GJGCChatFriendContentTypeSnapChat) {
            chatContentModel.isSnapChatMode = self.taklInfo.snapChatOutDataTime > 0;
            chatContentModel.readState = chatMessage.state;
            chatContentModel.readTime = chatMessage.readTime;
            if (chatMessage.messageType == GJGCChatFriendContentTypeAudio &&
                    chatMessage.state != 2) { //Voice message not played complete
                chatContentModel.readTime = 0;
            }
            if (![self.ignoreMessageTypes containsObject:@(chatContentModel.contentType)]) {
                if (chatContentModel.snapTime > 0) {
                    if (chatContentModel.readTime > 0) {
                        [self openSnapMessageCounterState:chatContentModel];
                    }
                }
            }
        }
    }

    return chatContentModel;
}


#pragma mark - Database read the last twenty messages

- (void)readLastMessagesFromDB {

    [super readLastMessagesFromDB];

    NSArray *messages = [[MessageDBManager sharedManager] getMessagesWithMessageOwer:self.taklInfo.chatIdendifier Limit:20 beforeTime:0];

    //Show encrypted chat tips
    ChatMessageInfo *fristMessage = [messages firstObject];
    if (self.taklInfo.talkType != GJGCChatFriendTalkTypePostSystem && messages.count != 20) {
        [self showfirstChatSecureTipWithTime:fristMessage.createTime];
    }

    for (ChatMessageInfo *messageInfo in messages) {
        if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSending) {
            [self.sendingMessages objectAddObject:messageInfo];
        }
        [self addMMMessage:messageInfo];
    }
    //Send message is being sent
    [self reSendUnSendingMessages];


    [self updateAllMsgTimeShowString];

    [self resetFirstAndLastMsgId];
    self.isFinishFirstHistoryLoad = YES;
}

#pragma mark -load more messages

- (void)pushAddMoreMsg:(NSArray *)messages {

    for (ChatMessageInfo *messageInfo in messages) {
        [self addMMMessage:messageInfo];
    }

    [self resortAllChatContentBySendTime];

    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
        [self.delegate dataSourceManagerRequireFinishRefresh:self];
        self.isLoadingMore = NO;
    }
}

@end
