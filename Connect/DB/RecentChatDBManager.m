//
//  RecentChatDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/8/2.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatDBManager.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "ConnectTool.h"
#import "LMConversionManager.h"
#import "LMRealmDBManager.h"
#import "LMRamGroupInfo.h"

static RecentChatDBManager *manager = nil;

@implementation RecentChatDBManager

+ (RecentChatDBManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (void)tearDown {
    manager = nil;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}

- (NSArray *)getAllRecentChat {
    NSMutableArray *recentChatArrayM = [NSMutableArray array];
    RLMResults <LMRecentChat *> *topResults = [[LMRecentChat objectsWhere:@"isTopChat = 1"] sortedResultsUsingKeyPath:@"createTime" ascending:NO];
    RLMResults <LMRecentChat *> *normalResults = [[LMRecentChat objectsWhere:@"isTopChat = 0"] sortedResultsUsingKeyPath:@"createTime" ascending:NO];
    //model trasfer
    for (LMRecentChat *realmModel in topResults) {
        RecentChatModel *model = realmModel.normalInfo;
        [recentChatArrayM addObject:model];
    }
    for (LMRecentChat *realmModel in normalResults) {
        RecentChatModel *model = realmModel.normalInfo;
        [recentChatArrayM addObject:model];
    }
    return recentChatArrayM;

}

- (void)getAllRecentChatWithComplete:(void (^)(NSArray *))complete {
    if (complete) {
        [GCDQueue executeInGlobalQueue:^{
            complete([self getAllRecentChat]);
        }];
    }
}

- (void)getTopChatCountWithComplete:(void (^)(int count))complete {
    RLMResults <LMRecentChat *> *results = [LMRecentChat objectsWhere:@"top_chat = 1"];
    if (complete) {
        complete((int) results.count);
    }
}

- (void)save:(RecentChatModel *)model {
    if (!model) {
        return;
    }
    if (GJCFStringIsNull(model.identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat alloc] initWithNormalInfo:model];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:realmModel];
    }];
    //add to session
    [[SessionManager sharedManager] setRecentChat:model];
}

- (void)deleteByIdentifier:(NSString *)identifier {

    if (GJCFStringIsNull(identifier)) {
        return;
    }
    RLMResults <LMRecentChat *> *results = [LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]];
    if (results.firstObject) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:[results firstObject]];
        }];
        [[LMConversionManager sharedManager] deleteConversationWithIdentifier:identifier];
    }
}

- (void)deleteRecentChatSettingWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    RLMResults <LMRecentChat *> *results = [LMRecentChatSetting objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]];
    if (results.firstObject) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:[results firstObject]];
        }];
    }
}

- (void)getAllUnReadCountWithComplete:(void (^)(int count))complete {
    if (complete) {
        RLMResults <LMRecentChat *> *results = [LMRecentChat objectsWhere:@"chatSetting.notifyStatus = 0"];
        int count = 0;
        for (LMRecentChat *realmModel in results) {
            count += realmModel.unReadCount;
        }
        complete(0);
    }
}

- (void)openOrCloseSnapChatWithTime:(int)snapTime chatIdentifer:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    if (snapTime < 0) {
        snapTime = 0;
    }
    LMRecentChatSetting *setting = [[LMRecentChatSetting objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    [self executeRealmWithBlock:^{
        setting.snapChatDeleteTime = snapTime;
    }];
}

- (int)getSnapTimeWithChatIdentifer:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return 0;
    }
    LMRecentChatSetting *setting = [[LMRecentChatSetting objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    return setting.snapChatDeleteTime;
}


- (RecentChatModel *)getRecentModelByIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return nil;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    RecentChatModel *model = realmModel.normalInfo;
    if (model) {
        [[SessionManager sharedManager] setRecentChat:model];
        return model;
    } else {
        return nil;
    }
}


- (void)topChat:(NSString *)identifier {

    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    if (!realmModel) {
        RecentChatModel *model = [RecentChatModel new];
        model.identifier = identifier;
        LMRamGroupInfo *group = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:identifier];
        if (group) {
            model.talkType = GJGCChatFriendTalkTypeGroup;
            model.chatGroupInfo = group;
            model.name = group.groupName;
            model.headUrl = group.avatarUrl;
        } else {
            AccountInfo *user = [[UserDBManager sharedManager] getUserByPublickey:identifier];
            if (user) {
                model.talkType = GJGCChatFriendTalkTypePrivate;
                model.chatUser = user;
                model.name = user.username;
                model.headUrl = user.avatar;
            }
        }
        model.createTime = [NSDate date];
        [self save:model];
    } else {
        [self executeRealmWithBlock:^{
            realmModel.isTopChat = YES;
        }];
    }
    [[LMConversionManager sharedManager] chatTop:YES identifier:identifier];
}

- (void)removeTopChat:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    if (realmModel) {
        [self executeRealmWithBlock:^{
            realmModel.isTopChat = NO;
        }];
        [[LMConversionManager sharedManager] chatTop:NO identifier:identifier];
    }
}

- (BOOL)isTopChat:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return NO;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    return realmModel.isTopChat;
}


- (void)updateDraft:(NSString *)draft withIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    draft = draft ? draft : @"";
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.draft = draft;
    }];
}

- (void)removeDraftWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.draft = @"";
    }];
}

- (void)removeLastContentWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.content = @"";
    }];
}


- (void)removeAllLastContent {
    RLMResults <LMRecentChat *> *results = [LMRecentChat allObjects];
    [self executeRealmWithBlock:^{
        for (LMRecentChat *realmModel in results) {
            realmModel.content = @"";
        }
    }];
}


- (NSString *)getDraftWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return @"";
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifier]] firstObject];
    return realmModel.draft;
}

- (void)updataUnReadCount:(int)unreadCount idetifier:(NSString *)idetifier {
    if (GJCFStringIsNull(idetifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", idetifier]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.unReadCount = unreadCount;
    }];
}

- (void)updataStrangerStatus:(BOOL)stranger idetifier:(NSString *)idetifier {
    if (GJCFStringIsNull(idetifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", idetifier]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.stranger = stranger;
    }];
}

- (void)clearUnReadCountWithIdetifier:(NSString *)idetifier {
    [self updataUnReadCount:0 idetifier:idetifier];
}

- (void)setGroupNoteMyselfWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifer]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.groupNoteMyself = YES;
    }];
}

- (void)clearGroupNoteMyselfWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifer]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.groupNoteMyself = NO;
    }];
}


- (void)setMuteWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifer]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.unReadCount = 0;
        realmModel.chatSetting.notifyStatus = YES;
    }];
}

- (void)removeMuteWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifer]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.chatSetting.notifyStatus = NO;
    }];
}


- (BOOL)getMuteStatusWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return NO;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifer]] firstObject];
    return realmModel.chatSetting.notifyStatus;
}

- (void)openSnapChatWithIdentifier:(NSString *)identifier snapTime:(int)snapTime openOrCloseByMyself:(BOOL)flag {
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }
    if (recentChat) {
        NSDate *time = [NSDate date];
        if (flag) {
            recentChat.unReadCount = 0;
        } else {
            recentChat.unReadCount += 1;
        }
        recentChat.createTime = time;
        recentChat.snapChatDeleteTime = snapTime;
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", recentChat.identifier]] firstObject];
        [self executeRealmWithBlock:^{
            realmModel.unReadCount = recentChat.unReadCount;
            realmModel.createTime = time;
            realmModel.chatSetting.snapChatDeleteTime = recentChat.snapChatDeleteTime;
        }];
    } else {
        AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:identifier];
        if (!contact) {
            contact = [[UserDBManager sharedManager] getFriendRequestBy:[KeyHandle getAddressByPubkey:identifier]];
            if (!contact && contact.status == 1) {
                return;
            }
        }
        recentChat = [[RecentChatModel alloc] init];
        recentChat.headUrl = contact.avatar;
        recentChat.name = contact.username;
        recentChat.createTime = [NSDate date];
        recentChat.identifier = identifier;

        recentChat.unReadCount = 0;
        recentChat.snapChatDeleteTime = snapTime;
        recentChat.chatUser = contact;

        [self save:recentChat];
    }
    if (flag) {

        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectRecentChatChangeNotification, recentChat);
        }];
    }
}


- (void)updataRecentChatLastTimeByIdentifer:(NSString *)identifer {

    if (GJCFStringIsNull(identifer)) {
        return;
    }
    //update
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", identifer]] firstObject];
    [self executeRealmWithBlock:^{
        realmModel.createTime = [NSDate date];
    }];
}


- (RecentChatModel *)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content {

    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }

    if (recentChat) {
        NSDate *time = [NSDate date];
        if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
            recentChat.unReadCount++;
        }
        recentChat.content = content;
        recentChat.createTime = time;
        recentChat.content = content;
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", recentChat.identifier]] firstObject];
        [self executeRealmWithBlock:^{
            realmModel.unReadCount = recentChat.unReadCount;
            realmModel.createTime = time;
            realmModel.content = recentChat.content;
        }];
    } else {
        if (groupChat) {
            LMRamGroupInfo *groupInfo = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:identifier];
            if (GJCFStringIsNull(groupInfo.groupEcdhKey)) {
                return nil;
            }
            recentChat = [[RecentChatModel alloc] init];
            recentChat.talkType = GJGCChatFriendTalkTypeGroup;
            recentChat.identifier = identifier;
            recentChat.createTime = [NSDate date];
            recentChat.content = content;
            if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                recentChat.unReadCount = 1;
            }
            recentChat.name = groupInfo.groupName;
            recentChat.headUrl = groupInfo.avatarUrl;
            recentChat.chatGroupInfo = groupInfo;
        } else {

            AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:identifier];
            if (!contact) {

                contact = [[UserDBManager sharedManager] getFriendRequestBy:[KeyHandle getAddressByPubkey:identifier]];
                if (!contact && contact.status == 1) {

                    return nil;
                }
            }

            if (![contact.pub_key isEqualToString:kSystemIdendifier]) {
                [[IMService instance] addNewSessionWithAddress:contact.address complete:^(NSError *erro, id data) {
                    DDLogInfo(@"create session %@", contact.address);
                }];
                recentChat = [[RecentChatModel alloc] init];
                recentChat.headUrl = contact.avatar;
                recentChat.name = contact.normalShowName;
                recentChat.createTime = [NSDate date];
                recentChat.identifier = identifier;
                recentChat.talkType = GJGCChatFriendTalkTypePrivate;
                recentChat.content = content;
                if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                    recentChat.unReadCount = 1;
                }
                recentChat.chatUser = contact;
            } else {
                recentChat = [[RecentChatModel alloc] init];
                recentChat.headUrl = contact.avatar;
                recentChat.name = contact.normalShowName;
                recentChat.createTime = [NSDate date];
                recentChat.talkType = GJGCChatFriendTalkTypePostSystem;
                recentChat.identifier = identifier;
                recentChat.content = content;
                if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                    recentChat.unReadCount = 1;
                }
                recentChat.chatUser = contact;
            }
        }
        recentChat.notifyStatus = [self getMuteStatusWithIdentifer:recentChat.identifier];
        recentChat.snapChatDeleteTime = [self getSnapTimeWithChatIdentifer:recentChat.identifier];
        [self save:recentChat];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRecentChatChangeNotification, recentChat);
    }];
    return recentChat;
}

- (void)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content ecdhKey:(NSString *)ecdhKey talkName:(NSString *)name {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }

    if (recentChat) {
        NSDate *time = [NSDate date];
        if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
            recentChat.unReadCount++;
        }
        recentChat.content = content;
        recentChat.createTime = time;
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", recentChat.identifier]] firstObject];

        [self executeRealmWithBlock:^{
            realmModel.unReadCount = recentChat.unReadCount;
            realmModel.createTime = time;
            realmModel.content = recentChat.content;
        }];

        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectRecentChatChangeNotification, recentChat);
        }];

    } else {
        if (groupChat) {
            LMRamGroupInfo *groupInfo = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:identifier];
            if (GJCFStringIsNull(ecdhKey)) {
                ecdhKey = groupInfo.groupEcdhKey;
                if (GJCFStringIsNull(ecdhKey)) {
                    return;
                }
            }
            recentChat = [[RecentChatModel alloc] init];
            recentChat.talkType = GJGCChatFriendTalkTypeGroup;
            recentChat.identifier = identifier;
            recentChat.createTime = [NSDate date];
            recentChat.content = content;
            if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                recentChat.unReadCount = 1;
            }
            recentChat.name = groupInfo.groupName;
            recentChat.headUrl = groupInfo.avatarUrl;
            recentChat.chatGroupInfo = groupInfo;

        } else {
            AccountInfo *contact = [[UserDBManager sharedManager] getUserByPublickey:identifier];
            if (!contact) {

                contact = [[UserDBManager sharedManager] getFriendRequestBy:[KeyHandle getAddressByPubkey:identifier]];
                if (!contact && contact.status == 1) {

                    return;
                }
            } else {
                [[IMService instance] addNewSessionWithAddress:contact.address complete:^(NSError *erro, id data) {
                    DDLogInfo(@"创建会话成功 %@", contact.address);
                }];
            }

            if ([contact.pub_key isEqualToString:kSystemIdendifier]) {
                recentChat = [[RecentChatModel alloc] init];
                recentChat.talkType = GJGCChatFriendTalkTypePostSystem;
                recentChat.createTime = [NSDate date];
                recentChat.unReadCount = 0;
                recentChat.name = @"Connect";
                recentChat.headUrl = @"connect_logo";
                recentChat.identifier = kSystemIdendifier;
                recentChat.chatUser = contact;
                recentChat.content = content;
            } else {
                recentChat = [[RecentChatModel alloc] init];
                recentChat.headUrl = contact.avatar;
                recentChat.name = contact.normalShowName;
                recentChat.createTime = [NSDate date];
                recentChat.identifier = identifier;
                recentChat.talkType = GJGCChatFriendTalkTypePrivate;
                recentChat.content = content;
                if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
                    recentChat.unReadCount = 1;
                }
                recentChat.chatUser = contact;

                recentChat.notifyStatus = [self getMuteStatusWithIdentifer:recentChat.identifier];
                recentChat.snapChatDeleteTime = [self getSnapTimeWithChatIdentifer:recentChat.identifier];
            }
        }
        [self save:recentChat];
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectNewChatChangeNotification, recentChat);
        }];
    }

}

- (void)createNewChatNoRelationShipWihtRegisterUser:(AccountInfo *)user {

    user.stranger = YES;
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:user.pub_key];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:user.pub_key];
    }
    if (recentChat) {
        NSDate *time = [NSDate date];
        if (![[SessionManager sharedManager].chatSession isEqualToString:user.pub_key]) {
            recentChat.unReadCount++;
        }
        recentChat.createTime = time;
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", recentChat.identifier]] firstObject];
        [self executeRealmWithBlock:^{
            realmModel.unReadCount = recentChat.unReadCount;
            realmModel.createTime = time;
            realmModel.content = recentChat.content;
        }];

    } else {
        recentChat = [[RecentChatModel alloc] init];
        recentChat.headUrl = user.avatar;
        recentChat.name = user.username;
        recentChat.stranger = YES;
        recentChat.createTime = [NSDate date];
        recentChat.identifier = user.pub_key;
        if (![[SessionManager sharedManager].chatSession isEqualToString:recentChat.identifier]) {
            recentChat.unReadCount = 1;
        }
        recentChat.chatUser = user;
        [self save:recentChat];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRecentChatChangeNotification, recentChat);
    }];
}

- (void)createConnectTermWelcomebackChatAndMessage {

    MMMessage *message = [[MMMessage alloc] init];
    message.user_name = @"Connect";
    message.type = GJGCChatFriendContentTypeText;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.content = LMLocalizedString(@"Login Welcome", nil);
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = message.message_id;
    chatMessage.createTime = (NSInteger) message.sendtime;
    chatMessage.messageType = GJGCChatFriendContentTypeText;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.readTime = 0;
    chatMessage.message = message;
    chatMessage.messageOwer = kSystemIdendifier;

    [[MessageDBManager sharedManager] saveBitchMessage:@[chatMessage]];

    RecentChatModel *model = [[SessionManager sharedManager] getRecentChatWithIdentifier:kSystemIdendifier];
    if (!model) {
        model = [self getRecentModelByIdentifier:kSystemIdendifier];
    }

    if (model) {
        int unRead = model.unReadCount;
        if (![[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
            unRead++;
        }
        NSDate *time = [NSDate date];
        model.unReadCount = unRead;
        model.content = message.content;
        model.createTime = time;

        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'", model.identifier]] firstObject];
        [self executeRealmWithBlock:^{
            realmModel.unReadCount = model.unReadCount;
            realmModel.createTime = time;
            realmModel.content = model.content;
        }];
    } else {
        model = [[RecentChatModel alloc] init];
        model.talkType = GJGCChatFriendTalkTypePostSystem;
        model.createTime = [NSDate date];
        if (![[SessionManager sharedManager].chatSession isEqualToString:kSystemIdendifier]) {
            model.unReadCount = 1;
        }
        model.name = @"Connect";
        model.headUrl = @"connect_logo";
        model.identifier = kSystemIdendifier;
        model.content = message.content;
        [self save:model];
    }
    [GCDQueue executeInMainQueue:^{
        SendNotify(ConnnectRecentChatChangeNotification, model);
    }];
}

@end
