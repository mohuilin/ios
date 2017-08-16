//
//  LMConversionManager.m
//  Connect
//
//  Created by MoHuilin on 2017/1/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMConversionManager.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "GroupDBManager.h"
#import "UserDBManager.h"
#import "IMService.h"
#import "ConnectTool.h"
#import "LMRecentChat.h"
#import "LMIMHelper.h"
#import "LMMessageTool.h"

@interface LMConversionManager ()

@property (assign ,nonatomic)BOOL syncContacting;
@property (strong ,nonatomic)NSMutableDictionary *unNotiMessageCountDict;
@property (strong ,nonatomic)NSMutableArray *noFriendShipPulickArray;


@property (nonatomic ,strong) RLMResults *recentResults;
@property (nonatomic ,strong) RLMNotificationToken *recentResultsToken;

@end

@implementation LMConversionManager

CREATE_SHARED_MANAGER(LMConversionManager)

- (instancetype)init{
    if (self = [super init]) {
        
        self.unNotiMessageCountDict = [NSMutableDictionary dictionary];
        self.noFriendShipPulickArray = [NSMutableArray array];
        RegisterNotify(kAcceptNewFriendRequestNotification, @selector(acceptRequest:));
        
    }
    return self;
}


- (void)clearAllModel{
    [[SessionManager sharedManager] clearAllModel];
    [self.unNotiMessageCountDict removeAllObjects];
    [self.noFriendShipPulickArray removeAllObjects];
    
    
    [self.recentResultsToken stop];
    self.recentResults = nil;
    self.recentResultsToken = nil;
}

- (void)getAllConversationFromDB{
    if (!self.recentResults) {
        self.recentResults = [LMRecentChat allObjects];
        __weak __typeof(&*self)weakSelf = self;
        self.recentResultsToken = [self.recentResults addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            NSMutableArray *recentChatArrayM = [NSMutableArray array];
            RLMResults <LMRecentChat *> *topResults = [[results objectsWhere:@"isTopChat = 1"] sortedResultsUsingKeyPath:@"createTime" ascending:NO];
            RLMResults <LMRecentChat *> *normalResults = [[results objectsWhere:@"isTopChat = 0"] sortedResultsUsingKeyPath:@"createTime" ascending:NO];
            //model trasfer
            for (LMRecentChat *realmModel in topResults) {
                RecentChatModel *model = realmModel.normalInfo;
                [recentChatArrayM addObject:model];
            }
            for (LMRecentChat *realmModel in normalResults) {
                RecentChatModel *model = realmModel.normalInfo;
                [recentChatArrayM addObject:model];
            }
            [SessionManager sharedManager].allRecentChats = recentChatArrayM;
            [SessionManager sharedManager].topChatCount = (int)topResults.count;
            [weakSelf reloadRecentChatWithRecentChatModel:nil needReloadBadge:YES];
        }];
    }
}

- (void)getNewMessagesWithLastMessage:(ChatMessageInfo *)lastMessage newMessageCount:(int)messageCount type:(GJGCChatFriendTalkType)type withSnapChatTime:(long long)snapChatTime{
    
    RecentChatModel *recentModel = nil;
    
    switch (type) {
        case GJGCChatFriendTalkTypePrivate:
        {
            recentModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:lastMessage.messageOwer];
            if (!recentModel) {
                AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:lastMessage.messageOwer];
                if (!contact) {
                    contact = [[AccountInfo alloc] init];
                    contact.pub_key = lastMessage.messageOwer;
                    //Sync contacts
                    if (![[UserDBManager sharedManager] isFriendByAddress:contact.address] && !self.syncContacting) {
                        self.syncContacting = YES;
                        [[IMService instance] syncFriendsWithComlete:^(NSError *erro, id data) {
                            self.syncContacting = NO;
                        }];
                    }
                }
                recentModel = [[RecentChatModel alloc] init];
                recentModel.headUrl = contact.avatar;
                recentModel.name = contact.username;
                recentModel.talkType = GJGCChatFriendTalkTypePrivate;
                recentModel.createTime = [NSDate date];
                recentModel.identifier = lastMessage.messageOwer;
                recentModel.unReadCount = messageCount;
                recentModel.chatUser = contact;
                recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@""];
                recentModel.snapChatDeleteTime = (int)snapChatTime;
                recentModel.notifyStatus = [[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:recentModel.identifier];
                if (lastMessage.messageType == GJGCChatFriendContentTypeSnapChat) {
                    recentModel.unReadCount = 0;
                    recentModel.snapChatDeleteTime = 0;
                }
                [[RecentChatDBManager sharedManager] save:recentModel];
            } else{
                
                recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@""];
                if (recentModel.stranger) {
                    recentModel.stranger = NO;
                    recentModel.chatUser.stranger = NO;
                }
                recentModel.unReadCount += messageCount;
                if ([[SessionManager sharedManager].chatSession isEqualToString:recentModel.identifier]) {
                    recentModel.unReadCount = 0;
                }
                NSDate *time = [NSDate date];
                recentModel.createTime = time;

                if (lastMessage.messageType == GJGCChatFriendContentTypeSnapChat) {
                    recentModel.snapChatDeleteTime = 0;
                }
                
                //update
                LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentModel.identifier]] firstObject];
                [[RecentChatDBManager sharedManager] executeRealmWithBlock:^{
                    realmModel.unReadCount = recentModel.unReadCount;
                    realmModel.createTime = time;
                    realmModel.stranger = recentModel.stranger;
                    realmModel.content = recentModel.content;
                    if (snapChatTime >= 0 &&
                        snapChatTime != recentModel.snapChatDeleteTime) {
                        recentModel.snapChatDeleteTime = (int)snapChatTime;
                        realmModel.chatSetting.snapChatDeleteTime = recentModel.snapChatDeleteTime;
                    }
 
                }];
            }
        }
            break;
            
        case GJGCChatFriendTalkTypeGroup:
        {
            LMRamGroupInfo *group = nil;
            recentModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:lastMessage.messageOwer];
            if (!recentModel) {
                recentModel = [[RecentChatModel alloc] init];
                recentModel.headUrl = group.avatarUrl;
                recentModel.name = group.groupName;
                recentModel.createTime = [NSDate date];
                recentModel.identifier = lastMessage.messageOwer;
                recentModel.unReadCount = messageCount;
                NSString *sendName = nil;
                LMRamMemberInfo *senderUser = nil;
                recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@"" senderUserName:sendName];
                recentModel.talkType = GJGCChatFriendTalkTypeGroup;
                recentModel.chatGroupInfo = group;
                recentModel.notifyStatus = [[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:recentModel.identifier];
                [[RecentChatDBManager sharedManager] save:recentModel];
            } else{
                NSString *sendName = nil;
                LMRamMemberInfo *senderUser = nil;
                recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@"" senderUserName:sendName];
                if ([[SessionManager sharedManager].chatSession isEqualToString:recentModel.identifier]) {
                    recentModel.unReadCount = 0;
                } else{
                    recentModel.unReadCount += messageCount;
                }
                NSDate *time = [NSDate date];
                recentModel.createTime = time;
                
                //update
                LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentModel.identifier]] firstObject];
                [[RecentChatDBManager sharedManager] executeRealmWithBlock:^{
                    realmModel.unReadCount = recentModel.unReadCount;
                    realmModel.createTime = time;
                    realmModel.content = recentModel.content;
                }];
            }
        }
            break;
            
        case GJGCChatFriendTalkTypePostSystem:
        {
            
            recentModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:kSystemIdendifier];
            if (recentModel) {
                if ([[SessionManager sharedManager].chatSession isEqualToString:recentModel.identifier]) {
                    recentModel.unReadCount = 0;
                } else{
                    recentModel.unReadCount += messageCount;
                }
                NSDate *time = [NSDate date];
                recentModel.createTime = time;
                recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@""];
                
                
                //update
                LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentModel.identifier]] firstObject];
                [[RecentChatDBManager sharedManager] executeRealmWithBlock:^{
                    realmModel.unReadCount = recentModel.unReadCount;
                    realmModel.createTime = time;
                    realmModel.content = recentModel.content;
                }];
            } else{
                recentModel = [[RecentChatModel alloc] init];
                recentModel.talkType = GJGCChatFriendTalkTypePostSystem;
                recentModel.createTime = [NSDate date];
                recentModel.unReadCount = messageCount;
                recentModel.name = @"Connect";
                recentModel.headUrl = @"connect_logo";
                recentModel.identifier = kSystemIdendifier;
                recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@""];
                [[RecentChatDBManager sharedManager] save:recentModel];
            }
        }
            break;
        default:
            break;
    }
    [self reloadRecentChatWithRecentChatModel:recentModel needReloadBadge:messageCount > 0];
}

- (void)getNewMessagesWithLastMessage:(ChatMessageInfo *)lastMessage newMessageCount:(int)messageCount  groupNoteMyself:(BOOL)groupNoteMyself{
    RecentChatModel *recentModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:lastMessage.messageOwer];
    if (!recentModel) {
        LMRamGroupInfo *group = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:lastMessage.messageOwer];
        recentModel = [[RecentChatModel alloc] init];
        recentModel.headUrl = group.avatarUrl;
        recentModel.name = group.groupName;
        recentModel.createTime = [NSDate date];
        recentModel.identifier = lastMessage.messageOwer;
        recentModel.content = @"";
        recentModel.unReadCount = messageCount;
        recentModel.groupNoteMyself = groupNoteMyself;
        NSString *sendName = nil;

        LMRamMemberInfo *senderUser = nil;
        
        recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@"" senderUserName:sendName];
        recentModel.talkType = GJGCChatFriendTalkTypeGroup;
        recentModel.chatGroupInfo = group;
        recentModel.notifyStatus = [[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:recentModel.identifier];
        [[RecentChatDBManager sharedManager] save:recentModel];
    } else{
        if ([[SessionManager sharedManager].chatSession isEqualToString:lastMessage.messageOwer]) {
            recentModel.groupNoteMyself = NO;
        } else{
            if (!recentModel.groupNoteMyself) {
                recentModel.groupNoteMyself = groupNoteMyself;
            }
        }
        NSString *sendName = nil;
        LMRamMemberInfo *senderUser = nil;
        recentModel.content = [GJGCChatFriendConstans lastContentMessageWithType:lastMessage.messageType textMessage:@"" senderUserName:sendName];
        if ([[SessionManager sharedManager].chatSession isEqualToString:recentModel.identifier]) {
            recentModel.unReadCount = 0;
        } else{
            recentModel.unReadCount += messageCount;
        }
        NSDate *time = [NSDate date];
        recentModel.createTime = time;
        
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentModel.identifier]] firstObject];
        [[RecentChatDBManager sharedManager]executeRealmWithBlock:^{
            realmModel.unReadCount = recentModel.unReadCount;
            realmModel.createTime = time;
            realmModel.groupNoteMyself = recentModel.groupNoteMyself;
            realmModel.content = recentModel.content;
        }];
    }
    
    [self reloadRecentChatWithRecentChatModel:recentModel needReloadBadge:messageCount > 0];
}

- (void)reloadRecentChatWithRecentChatModel:(RecentChatModel *)recentModel needReloadBadge:(BOOL)needReloadBadge{
    [GCDQueue executeInMainQueue:^{
        if (recentModel) {
            NSMutableArray *recentChatArray = [NSMutableArray arrayWithArray:[SessionManager sharedManager].allRecentChats];
            if ([recentChatArray containsObject:recentModel]) {
                [recentChatArray moveObject:recentModel toIndex:recentModel.isTopChat?0:[SessionManager sharedManager].topChatCount];
            } else{
                [recentChatArray objectInsert:recentModel atIndex:recentModel.isTopChat?0:[SessionManager sharedManager].topChatCount];
            }
            if ([self.conversationListDelegate respondsToSelector:@selector(conversationListDidChanged:)]) {
                [self.conversationListDelegate conversationListDidChanged:recentChatArray];
            }
            //The elements inside a container are copied by pointers. Crashes caused by modifications to prevent traversal of arrays
            [SessionManager sharedManager].allRecentChats = recentChatArray.mutableCopy;
        } else {
            if ([self.conversationListDelegate respondsToSelector:@selector(conversationListDidChanged:)]) {
                [self.conversationListDelegate conversationListDidChanged:[SessionManager sharedManager].allRecentChats];
            }
        }
        if (needReloadBadge) {
            if ([self.conversationListDelegate respondsToSelector:@selector(unreadMessageNumberDidChanged)]) {
                [self.conversationListDelegate unreadMessageNumberDidChanged];
            }
        }
    }];
}


- (void)sendMessage:(ChatMessage *)chatMsg content:(NSString *)content snapChat:(BOOL)snapChat type:(GJGCChatFriendTalkType)type{
    
    NSString *lastContentString = nil;
    if (snapChat) {
        lastContentString = LMLocalizedString(@"Chat send a snap chat message", nil);
    } else {
        if (type == GJGCChatFriendTalkTypeGroup) {
            lastContentString = [GJGCChatFriendConstans lastContentMessageWithType:chatMsg.msgType textMessage:content senderUserName:[[LKUserCenter shareCenter] currentLoginUser].username];
        } else{
            lastContentString = [GJGCChatFriendConstans lastContentMessageWithType:chatMsg.msgType textMessage:content];
        }
    }
    RecentChatModel *recentModel = [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:chatMsg.to groupChat:type == GJGCChatFriendTalkTypeGroup lastContentShowType:0 lastContent:lastContentString];
    if (recentModel.stranger && recentModel.talkType == GJGCChatFriendTalkTypePrivate) {
        recentModel.stranger = ![[UserDBManager sharedManager] isFriendByAddress:[LMIMHelper getAddressByPubkey:recentModel.identifier]];
        recentModel.chatUser.stranger = recentModel.stranger;
    }
    [self reloadRecentChatWithRecentChatModel:recentModel needReloadBadge:NO];
}

- (void)chatWithNewFriend:(AccountInfo *)chatUser{
    if (!chatUser || [chatUser.pub_key isEqualToString:kSystemIdendifier]) {
        return;
    }
    
    ChatMessageInfo *messageInfo = [LMMessageTool makeTextChatMessageWithMessageText:!GJCFStringIsNull(chatUser.message)?chatUser.message:[NSString stringWithFormat:LMLocalizedString(@"Link Hello I am", nil),chatUser.username] msgOwer:chatUser.pub_key sender:chatUser.address];
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    [[MessageDBManager sharedManager] saveMessage:messageInfo];
    [self getNewMessagesWithLastMessage:messageInfo newMessageCount:1 type:GJGCChatFriendTalkTypePrivate withSnapChatTime:0];
}

- (BOOL)deleteConversationWithIdentifier:(NSString *)identifier{
    RecentChatModel *recentModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    return [self deleteConversation:recentModel];
}

- (BOOL)deleteConversation:(RecentChatModel *)conversationModel{
    if (!conversationModel) {
        return NO;
    }
    if (conversationModel.talkType != GJGCChatFriendTalkTypeGroup) {
        [[IMService instance] deleteSessionWithAddress:conversationModel.chatUser.address complete:nil];
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:conversationModel.chatUser.address];
    } else{
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:conversationModel.identifier];
    }
    if (conversationModel.isTopChat && [SessionManager sharedManager].topChatCount >= 1) {
        [SessionManager sharedManager].topChatCount--;
    }
    
    
    //delete recentchat
    [[SessionManager sharedManager] removeRecentChatWithIdentifier:conversationModel.identifier];
    [[RecentChatDBManager sharedManager] deleteByIdentifier:conversationModel.identifier];
    
    //delete all message
    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:conversationModel.identifier];
    if (conversationModel.unReadCount > 0) {
        [GCDQueue executeInMainQueue:^{
            if ([self.conversationListDelegate respondsToSelector:@selector(unreadMessageNumberDidChanged)]) {
                [self.conversationListDelegate unreadMessageNumberDidChanged];
            }
        }];
    }
    return YES;
}

- (void)setConversationMute:(RecentChatModel *)model complete:(void (^)(BOOL complete))complete{
    BOOL notify = model.notifyStatus;
    if (model.talkType != GJGCChatFriendTalkTypeGroup) {
        [[IMService instance] openOrCloseSesionMuteWithAddress:model.chatUser.address mute:model.notifyStatus complete:^(NSError *error, id data) {
            if (!error) {
                [self setMuteWithNotify:notify recentChatModel:model];
                if (complete) {
                    complete(YES);
                }
            } else {
                if (complete) {
                    complete(NO);
                }
            }
        }];
    } else {
        [SetGlobalHandler GroupChatSetMuteWithIdentifer:model.identifier mute:!notify complete:^(NSError *error) {
            if (!error) {
                [self setMuteWithNotify:notify recentChatModel:model];
                if (complete) {
                    complete(YES);
                }
            } else {
                if (complete) {
                    complete(NO);
                }
            }
        }];
    }
}

- (void)setMuteWithNotify:(BOOL)notify recentChatModel:(RecentChatModel *)model {
    if (!notify) {
        [[RecentChatDBManager sharedManager] setMuteWithIdentifer:model.identifier];
        if (model.unReadCount) {
            model.notifyStatus = YES;
            model.unReadCount = 0;
            [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:YES];
        } else{
            model.notifyStatus = YES;
            [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:NO];
        }
    } else {
        [[RecentChatDBManager sharedManager] removeMuteWithIdentifer:model.identifier];
        model.notifyStatus = NO;
        [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:model.unReadCount > 0];
    }
}

- (void)markAllMessagesAsRead:(RecentChatModel *)conversation{
    if (conversation) {
        conversation.unReadCount = 0;
        [[RecentChatDBManager sharedManager] clearUnReadCountWithIdetifier:conversation.identifier];
        [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:YES];
    }
}

- (void)setRecentStrangerStatusWithIdentifier:(NSString *)identifier stranger:(BOOL)stranger{
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    RecentChatModel *model = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (model && model.stranger != stranger) {
        model.stranger = stranger;
        [[RecentChatDBManager sharedManager] updataStrangerStatus:stranger idetifier:identifier];
        [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:NO];
    }
}

- (void)markConversionMessagesAsReadWithIdentifier:(NSString *)conversationIdentifier{
    if (GJCFStringIsNull(conversationIdentifier)) {
        return;
    }
    RecentChatModel *model = [[SessionManager sharedManager] getRecentChatWithIdentifier:conversationIdentifier];
    [self markAllMessagesAsRead:model];
}

- (void)clearConversionUnreadAndGroupNoteWithIdentifier:(NSString *)conversationIdentifier{
    if (GJCFStringIsNull(conversationIdentifier)) {
        return;
    }
    BOOL needSyncBadge = NO;
    BOOL needReload = NO;
    RecentChatModel *recentModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:conversationIdentifier];
    if (recentModel.unReadCount != 0) {
        recentModel.unReadCount = 0;
        [[RecentChatDBManager sharedManager] clearUnReadCountWithIdetifier:conversationIdentifier];
        needSyncBadge = YES;
        needReload = YES;
    }
    
    if (recentModel.groupNoteMyself) {
        recentModel.groupNoteMyself = NO;
        [[RecentChatDBManager sharedManager] clearGroupNoteMyselfWithIdentifer:recentModel.identifier];
        needReload = YES;
    }
    [GCDQueue executeInMainQueue:^{
        if (needReload) {
            if ([self.conversationListDelegate respondsToSelector:@selector(conversationListDidChanged:)]) {
                [self.conversationListDelegate conversationListDidChanged:[SessionManager sharedManager].allRecentChats];
            }
        }
        if (needSyncBadge) {
            if ([self.conversationListDelegate respondsToSelector:@selector(unreadMessageNumberDidChangedNeedSyncbadge)]) {
                [self.conversationListDelegate unreadMessageNumberDidChangedNeedSyncbadge];
            }
        }
    }];
}

/**
 @{@"identifier":publiKeyOrGroupid,
 @"status":@(NO)};
 */
- (void)chatTop:(BOOL)topChat identifier:(NSString *)identifier {
    if (topChat) {
        [SessionManager sharedManager].topChatCount++;
    } else{
        [SessionManager sharedManager].topChatCount--;
    }
    RecentChatModel *findModel = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    findModel.isTopChat = topChat;

    if (findModel) {
        if (topChat) {
            [[SessionManager sharedManager].allRecentChats moveObject:findModel toIndex:0];
        } else{
            [[SessionManager sharedManager].allRecentChats moveObject:findModel toIndex:[SessionManager sharedManager].topChatCount];
        }
    }
    [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:NO];
}

- (void)enterForeground{
    [self reloadRecentChatWithRecentChatModel:nil needReloadBadge:YES];
}


- (void)acceptRequest:(NSNotification *)note{
    AccountInfo *user = note.object;
    [self chatWithNewFriend:user];
}

@end
