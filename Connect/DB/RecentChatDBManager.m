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
#import "LMBaseSSDBManager.h"
#import "LMConversionManager.h"
#import "LMRealmDBManager.h"


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
    RLMResults <LMRecentChat *> *results = [LMRecentChat allObjects];
    //model trasfer
    for (LMRecentChat *realmModel in results) {
        RecentChatModel *model = [realmModel recentModel];
        [recentChatArrayM addObject:model];
    }
    //sort
    [recentChatArrayM sortUsingSelector:@selector(comparedata:)];
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
        complete((int)results.count);
    }
}

- (void)save:(RecentChatModel *)model {
    if (!model) {
        return;
    }
    if (GJCFStringIsNull(model.identifier)) {
        return;
    }

    LMRecentChat *realmModel = [[LMRecentChat alloc] initWithRecentModel:model];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:realmModel];
    [realm commitWriteTransaction];
    
    //add to session
    [[SessionManager sharedManager] setRecentChat:model];
}

- (void)deleteByIdentifier:(NSString *)identifier {

    if (GJCFStringIsNull(identifier)) {
        return;
    }
    
    RLMResults <LMRecentChat *> *results = [LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]];
    if (results.firstObject) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm deleteObject:[results firstObject]];
        [realm commitWriteTransaction];
    }
    [[LMConversionManager sharedManager] deleteConversationWithIdentifier:identifier];
}

- (void)deleteRecentChatSettingWithIdentifier:(NSString *)identifier{
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    RLMResults <LMRecentChat *> *results = [LMRecentChatSetting objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]];
    if (results.firstObject) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm deleteObject:[results firstObject]];
        [realm commitWriteTransaction];
    }
}

- (void)getAllUnReadCountWithComplete:(void (^)(int count))complete {
    if (complete) {
        RLMResults <LMRecentChat *> *results = [LMRecentChat objectsWhere:@"chatSetting.notifyStatus == 0"];
        int count = 0;
        for (LMRecentChat *realmModel in results) {
            count += realmModel.unReadCount;
        }
        complete(count);
    }
}

- (void)openOrCloseSnapChatWithTime:(int)snapTime chatIdentifer:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    if (snapTime < 0) {
        snapTime = 0;
    }
    
    LMRecentChatSetting *setting = [[LMRecentChatSetting objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    setting.snapChatDeleteTime = snapTime;
    [realm commitWriteTransaction];
}

- (int)getSnapTimeWithChatIdentifer:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return 0;
    }
    LMRecentChatSetting *setting = [[LMRecentChatSetting objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    return setting.snapChatDeleteTime;
}


- (RecentChatModel *)getRecentModelByIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return nil;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    RecentChatModel *model = [realmModel recentModel];
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
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    if (!realmModel) {
        RecentChatModel *model = [RecentChatModel new];
        model.identifier = identifier;
        LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
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
        model.time = [NSString stringWithFormat:@"%lld",(long long)([[NSDate date] timeIntervalSince1970] * 1000)];
        [self save:model];
    } else {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.isTopChat = YES;
        [realm commitWriteTransaction];
    }
    [[LMConversionManager sharedManager] chatTop:YES identifier:identifier];
}

- (void)removeTopChat:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    if (realmModel) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.isTopChat = NO;
        [realm commitWriteTransaction];
        
        [[LMConversionManager sharedManager] chatTop:NO identifier:identifier];
    }
}

- (BOOL)isTopChat:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return NO;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    return realmModel.isTopChat;
}


- (void)updateDraft:(NSString *)draft withIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    draft = draft ? draft : @"";
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.draft = draft;
    [realm commitWriteTransaction];
}

- (void)removeDraftWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.draft = @"";
    [realm commitWriteTransaction];
}

- (void)removeLastContentWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.content = @"";
    [realm commitWriteTransaction];
}


- (void)removeAllLastContent {
    RLMResults <LMRecentChat *> *results = [LMRecentChat allObjects];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    for (LMRecentChat *realmModel in results) {
        realmModel.content = @"";
    }
    [realm commitWriteTransaction];
}


- (NSString *)getDraftWithIdentifier:(NSString *)identifier {
    if (GJCFStringIsNull(identifier)) {
        return @"";
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifier]] firstObject];
    return realmModel.draft;
}

- (void)updataUnReadCount:(int)unreadCount idetifier:(NSString *)idetifier {
    if (GJCFStringIsNull(idetifier)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",idetifier]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.unReadCount = unreadCount;
    [realm commitWriteTransaction];
}

- (void)updataStrangerStatus:(BOOL)stranger idetifier:(NSString *)idetifier{
    if (GJCFStringIsNull(idetifier)) {
        return;
    }
    
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",idetifier]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.stranger = stranger;
    [realm commitWriteTransaction];
}

- (void)clearUnReadCountWithIdetifier:(NSString *)idetifier {
    [self updataUnReadCount:0 idetifier:idetifier];
}

- (void)setGroupNoteMyselfWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifer]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.groupNoteMyself = YES;
    [realm commitWriteTransaction];
}

- (void)clearGroupNoteMyselfWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifer]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.groupNoteMyself = NO;
    [realm commitWriteTransaction];
}


- (void)setMuteWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifer]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.unReadCount = 0;
    realmModel.chatSetting.notifyStatus = YES;
    [realm commitWriteTransaction];
}

- (void)removeMuteWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifer]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.chatSetting.notifyStatus = NO;
    [realm commitWriteTransaction];
}


- (BOOL)getMuteStatusWithIdentifer:(NSString *)identifer {
    if (GJCFStringIsNull(identifer)) {
        return NO;
    }
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifer]] firstObject];
    return realmModel.chatSetting.notifyStatus;
}

- (void)openSnapChatWithIdentifier:(NSString *)identifier snapTime:(int)snapTime openOrCloseByMyself:(BOOL)flag {
    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }
    if (recentChat) {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (flag) {
            recentChat.unReadCount = 0;
        } else {
            recentChat.unReadCount += 1;
        }
        recentChat.time = last_time;
        recentChat.snapChatDeleteTime = snapTime;
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentChat.identifier]] firstObject];
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.unReadCount = recentChat.unReadCount;
        realmModel.time = recentChat.time;
        realmModel.chatSetting.snapChatDeleteTime = recentChat.snapChatDeleteTime;
        [realm commitWriteTransaction];
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
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        recentChat.time = [NSString stringWithFormat:@"%lld", time];
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
    int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
    //update
    LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",identifer]] firstObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    realmModel.time = [NSString stringWithFormat:@"%lld", time];
    [realm commitWriteTransaction];
}


- (RecentChatModel *)createNewChatWithIdentifier:(NSString *)identifier groupChat:(BOOL)groupChat lastContentShowType:(int)lastContentShowType lastContent:(NSString *)content {

    RecentChatModel *recentChat = [[SessionManager sharedManager] getRecentChatWithIdentifier:identifier];
    if (!recentChat) {
        recentChat = [self getRecentModelByIdentifier:identifier];
    }

    if (recentChat) {
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
            recentChat.unReadCount++;
        }
        recentChat.content = content;
        recentChat.time = last_time;
        recentChat.content = content;

        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentChat.identifier]] firstObject];
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.unReadCount = recentChat.unReadCount;
        realmModel.time = recentChat.time;
        realmModel.content = recentChat.content;
        [realm commitWriteTransaction];
    } else {
        if (groupChat) {
            int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
            NSString *timeStr = [NSString stringWithFormat:@"%lld", time];
            LMGroupInfo *groupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
            if (GJCFStringIsNull(groupInfo.groupEcdhKey)) {
                return nil;
            }
            recentChat = [[RecentChatModel alloc] init];
            recentChat.talkType = GJGCChatFriendTalkTypeGroup;
            recentChat.identifier = identifier;
            recentChat.time = timeStr;
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
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
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
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
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
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:identifier] && lastContentShowType == 0) {
            recentChat.unReadCount++;
        }
        recentChat.content = content;
        recentChat.time = last_time;
        
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentChat.identifier]] firstObject];
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.unReadCount = recentChat.unReadCount;
        realmModel.time = recentChat.time;
        realmModel.content = recentChat.content;
        [realm commitWriteTransaction];

        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectRecentChatChangeNotification, recentChat);
        }];

    } else {
        if (groupChat) {

            int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
            NSString *timeStr = [NSString stringWithFormat:@"%lld", time];
            LMGroupInfo *groupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
            if (GJCFStringIsNull(ecdhKey)) {
                ecdhKey = groupInfo.groupEcdhKey;
                if (GJCFStringIsNull(ecdhKey)) {
                    return;
                }
            }
            recentChat = [[RecentChatModel alloc] init];
            recentChat.talkType = GJGCChatFriendTalkTypeGroup;
            recentChat.identifier = identifier;
            recentChat.time = timeStr;
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
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
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
                int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
                recentChat.time = [NSString stringWithFormat:@"%lld", time];
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
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        if (![[SessionManager sharedManager].chatSession isEqualToString:user.pub_key]) {
            recentChat.unReadCount++;
        }
        recentChat.time = last_time;
        
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",recentChat.identifier]] firstObject];
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.unReadCount = recentChat.unReadCount;
        realmModel.time = recentChat.time;
        realmModel.content = recentChat.content;
        [realm commitWriteTransaction];

    } else {
        recentChat = [[RecentChatModel alloc] init];
        recentChat.headUrl = user.avatar;
        recentChat.name = user.username;
        recentChat.stranger = YES;
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        recentChat.time = [NSString stringWithFormat:@"%lld", time];
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
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *last_time = [NSString stringWithFormat:@"%lld", time];
        model.unReadCount = unRead;
        model.content = message.content;
        model.time = last_time;
        
        //update
        LMRecentChat *realmModel = [[LMRecentChat objectsWhere:[NSString stringWithFormat:@"identifier = '%@'",model.identifier]] firstObject];
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        realmModel.unReadCount = model.unReadCount;
        realmModel.time = model.time;
        realmModel.content = model.content;
        [realm commitWriteTransaction];

    } else {
        model = [[RecentChatModel alloc] init];
        model.talkType = GJGCChatFriendTalkTypePostSystem;
        int long long time = [[NSDate date] timeIntervalSince1970] * 1000;
        model.time = [NSString stringWithFormat:@"%lld", time];
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
