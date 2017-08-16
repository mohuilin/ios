//
//  GJGCSystemNotiDataManager.m
//  ZYChat
//
//  Created by ZYVincent on 14-11-11.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCChatSystemNotiDataManager.h"

@interface GJGCChatSystemNotiDataManager ()

@property(nonatomic, assign) NSInteger pageIndex;
@property(nonatomic, assign) BOOL isFinishLoadDataBaseMsg;

@end

@implementation GJGCChatSystemNotiDataManager

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id <GJGCChatDetailDataSourceManagerDelegate>)aDelegate {
    if (self = [super initWithTalk:talk withDelegate:aDelegate]) {
        self.title = LMLocalizedString(@"Chat Connect", nil);
        self.pageIndex = 0;
        [self readLastMessagesFromDB];
    }
    return self;
}

#pragma mark - load messages

- (void)readLastMessagesFromDB {
    [super readLastMessagesFromDB];
    //Read the last 20 messages
    NSArray *messages = [[MessageDBManager sharedManager] getMessagesWithMessageOwer:self.taklInfo.chatIdendifier Limit:20 beforeTime:0];

    NSMutableArray *temA = [NSMutableArray arrayWithArray:messages];
    messages = temA.copy;

    for (ChatMessageInfo *messageInfo in messages) {
        if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSending) {
            [self.sendingMessages objectAddObject:messageInfo];
        }
        [self addMMMessage:messageInfo];
    }

    //Send message is being sent
    [self reSendUnSendingMessages];

    [self updateAllMsgTimeShowString];

    /* Set the first and last message after loading */
    [self resetFirstAndLastMsgId];
    self.isFinishFirstHistoryLoad = YES;
}


- (GJGCChatFriendContentModel *)addMMMessage:(ChatMessageInfo *)chatMessage {

    [self.orginMessageListArray objectAddObject:chatMessage];
    int type = chatMessage.messageType;
    switch (type) {
        case 101:
        case 102: {
            return [self addSystemAnnouncementWithMessage:chatMessage];
        }
            break;
        default:
            break;
    }

    GJGCChatFriendContentModel *chatContentModel = [[GJGCChatFriendContentModel alloc] init];
    chatContentModel.contentType = chatMessage.messageType;
    chatContentModel.autoMsgid = chatMessage.ID;
    chatContentModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    chatContentModel.sendStatus = chatMessage.sendstatus;
    chatContentModel.sendTime = chatMessage.createTime;
    chatContentModel.publicKey = chatMessage.messageOwer;
    chatContentModel.localMsgId = chatMessage.messageId;
    chatContentModel.talkType = self.taklInfo.talkType;

    chatContentModel.isSnapChatMode = self.taklInfo.snapChatOutDataTime > 0;
    chatContentModel.isFriend = YES;
    if (![chatMessage.from isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
        chatContentModel.isFromSelf = NO;
        chatContentModel.headUrl = self.taklInfo.headUrl;
        chatContentModel.senderName = self.taklInfo.name;
    } else {
        chatContentModel.headUrl = [[LKUserCenter shareCenter] currentLoginUser].avatar;
        chatContentModel.isFromSelf = YES;
        chatContentModel.senderName = [[LKUserCenter shareCenter] currentLoginUser].normalShowName;
    }
    GJGCChatFriendContentType contentType = [self formateChatFriendContent:chatContentModel withMsgModel:chatMessage];
    if (contentType != GJGCChatFriendContentTypeNotFound) {
        if (![self contentModelByMsgId:chatMessage.messageId]) {
            [self addChatContentModel:chatContentModel];
        }
    }
    return chatContentModel;
}


- (void)observeSystemNotiMessage:(NSNotification *)noti {
}

- (void)observeHistoryMessage:(NSNotification *)noti {
    dispatch_async(dispatch_get_main_queue(), ^{

        [self recieveHistoryMessage:noti];

    });
}

- (void)recieveHistoryMessage:(NSNotification *)noti {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
        [self.delegate dataSourceManagerRequireFinishRefresh:self];
    }
    self.isFinishLoadAllHistoryMsg = YES;
}

#pragma mark - more messagees

- (void)pushAddMoreMsg:(NSArray *)messages {

    /* 分发到UI层，添加一组消息 */
    for (ChatMessageInfo *messageInfo in messages) {
        [self addMMMessage:messageInfo];
    }
    /* 重排时间顺序 */
    [self resortAllChatContentBySendTime];

    /* 上一次悬停的第一个cell的索引 */
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
        [self.delegate dataSourceManagerRequireFinishRefresh:self];
        self.isLoadingMore = NO; //标记刷新结束
    }
}


#pragma mark - announcement

- (GJGCChatFriendContentModel *)addSystemAnnouncementWithMessage:(ChatMessageInfo *)chatMessage {

    /*
     @{@"title":announcement.title,
     @"jumpUrl":announcement.URL,
     @"createAt":@(announcement.createdAt),
     @"coversURL":announcement.coversURL,
     @"category":@(announcement.category),
     @"content":announcement.content};
     */
    NSDictionary *announcementDict = nil;
    NSString *url = [announcementDict valueForKey:@"jumpUrl"];
    // card title
    NSString *title = [announcementDict valueForKey:@"title"];
    // desc
    NSString *desc = [announcementDict valueForKey:@"content"];
    // type
    NSInteger type = [[announcementDict valueForKey:@"category"] integerValue];
    NSString *pic = [announcementDict valueForKey:@"coversURL"];
    NSString *buttonTitle = LMLocalizedString(@"Wallet Detail", nil);
    GJGCChatSystemNotiModel *notiModel = [[GJGCChatSystemNotiModel alloc] init];
    notiModel.systemActiveImageUrl = pic;
    notiModel.localMsgId = chatMessage.messageId;
    notiModel.autoMsgid = chatMessage.ID;
    notiModel.canShowHighlightState = YES;
    notiModel.assistType = GJGCChatSystemNotiAssistTypeTemplate;
    notiModel.baseMessageType = GJGCChatBaseMessageTypeSystemNoti;
    notiModel.notiType = GJGCChatSystemNotiTypeSystemActiveGuide;
    notiModel.postSystemContent = [[NSAttributedString alloc] initWithString:desc];
    notiModel.systemNotiTitle = [GJGCChatSystemNotiCellStyle formateNameString:title];
    notiModel.systemJumpUrl = url;
    notiModel.systemJumpType = type;
    notiModel.systemGuideButtonTitle = [GJGCChatSystemNotiCellStyle formateActiveDescription:buttonTitle];
    notiModel.talkType = GJGCChatFriendTalkTypePostSystem;
    notiModel.sendTime = chatMessage.createTime;
    notiModel.timeString = [GJGCChatSystemNotiCellStyle formateSystemNotiTime:notiModel.sendTime / 1000];
    notiModel.systemOperationTip = [GJGCChatSystemNotiCellStyle formateActiveDescription:desc];
    [self addChatContentModel:notiModel];

    return notiModel;
}

- (void)requireListUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireUpdateListTable:)]) {
        [self.delegate dataSourceManagerRequireUpdateListTable:self];
    }
}
@end
