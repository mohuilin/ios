//
//  LMRealmDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//
#import "LMRealmDBManager.h"
#import "MMGlobal.h"
#import "NSDictionary+LMSafety.h"
#import "LMMessage.h"
#import "LMContactAccountInfo.h"
#import "LMRamGroupInfo.h"
#import "LMRamAddressBook.h"
#import "LMFriendRecommandInfo.h"
#import "LMFriendRequestInfo.h"
#import <FMDB/FMDB.h>


@implementation LMRealmDBManager
static FMDatabaseQueue *queue;


+ (void)dataMigrationWithComplete:(void (^)(CGFloat progress))complete {
    NSString *olddbPath = olddbPath = [[NSHomeDirectory() stringByAppendingPathComponent:RootPath]
                                       stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].pub_key.sha256String];
    if (GJCFFileIsExist(olddbPath)) {

    } else {
        olddbPath = [[NSHomeDirectory() stringByAppendingPathComponent:RootPath]
                     stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
        if (GJCFFileIsExist(olddbPath)) {
            //data migration
            if ([self saveMessagesToRealm]) {
                if (complete) {
                    complete(0.1);
                }
            }
            //t_conversion
            if ([self saveRecentChatToRealm]) {
                if (complete) {
                    complete(0.3);
                }
            }
            if ([self contactNewDataMigration]) {
                if (complete) {
                    complete(0.4);
                }
            }
            // t_group
            if ([self groupNewDataMigration]) {
                if (complete) {
                    complete(0.5);
                }
            }
            //t_addressbook
            if ([self addressbookNewDataMigration]) {
                if (complete) {
                    complete(0.7);
                }
            }
            //t_friend
            if ([self friendRequestNewDataMigration]) {
                if (complete) {
                    complete(0.9);
                }
            }
            //t_friend_recommand
            if ([self friendRecommandNewDataMigration]) {
                if (complete) {
                    complete(1);
                }
            }
            GJCFFileDeleteFile(olddbPath);
        }
    }
}

+ (NSArray *)queryWithSql:(NSString *)sql {
    NSString *dbName = [[LKUserCenter shareCenter] currentLoginUser].pub_key.sha256String;
    if (!dbName) {
        return nil;
    }
    if (GJCFStringIsNull(sql)) {
        return nil;
    }
    NSMutableArray __block *arrayM = @[].mutableCopy;
    NSString *dbPath = [MMGlobal getDBFile:dbName];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (int i = 0; i < result.columnCount; i++) {
                NSString *name = [result columnNameForIndex:i];
                [dict setObject:[result objectForColumnIndex:i] forKey:name];
            }
            [arrayM objectAddObject:dict];
        }
    }];
    [queue close];
    return arrayM.copy;
}

+ (NSArray *)recentQueryWithSql:(NSString *)sql {
    NSString *dbName = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    if (!dbName) {
        return nil;
    }
    if (GJCFStringIsNull(sql)) {
        return nil;
    }
    NSMutableArray __block *arrayM = @[].mutableCopy;
    NSString *dbPath = [MMGlobal getDBFile:dbName];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (int i = 0; i < result.columnCount; i++) {
                NSString *name = [result columnNameForIndex:i];
                [dict setObject:[result objectForColumnIndex:i] forKey:name];
            }
            [arrayM objectAddObject:dict];
        }
    }];
    [queue close];
    return arrayM.copy;
}

+ (BOOL)friendRequestNewDataMigration {
    NSString *querySql = @"select * from t_friendrequest";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *temM = [NSMutableArray array];
    for (NSDictionary *dic in resultArray) {
        LMFriendRequestInfo *accountInfo = [[LMFriendRequestInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.pubKey = [dic safeObjectForKey:@"pub_key"];
        accountInfo.status = [[dic safeObjectForKey:@"status"] intValue];
        accountInfo.read = [[dic safeObjectForKey:@"read"] intValue];
        accountInfo.status = [[dic safeObjectForKey:@"status"] intValue];
        accountInfo.tips = [dic safeObjectForKey:@"tips"];
        if (accountInfo.address.length > 0) {
            [temM objectAddObject:accountInfo];
        }
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;

}

+ (BOOL)addressbookNewDataMigration {
    NSString *querySql = @"select * from t_addressbook";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *temM = [NSMutableArray array];
    for (NSDictionary *temD in resultArray) {
        LMRamAddressBook *info = [[LMRamAddressBook alloc] init];
        info.address = [temD safeObjectForKey:@"address"];
        info.tag = [temD safeObjectForKey:@"tag"];
        info.creatTime = [NSDate date];
        [temM objectAddObject:info];
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;

}

+ (BOOL)friendRecommandNewDataMigration {
    NSString *querySql = @"select * from t_friendrequest";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *temM = [NSMutableArray array];
    for (NSDictionary *dic in resultArray) {
        LMFriendRecommandInfo *recommandInfo = [[LMFriendRecommandInfo alloc] init];
        recommandInfo.username = [dic safeObjectForKey:@"username"];
        recommandInfo.address = [dic safeObjectForKey:@"address"];
        recommandInfo.avatar = [dic safeObjectForKey:@"avatar"];
        recommandInfo.pubKey = [dic safeObjectForKey:@"pub_key"];
        recommandInfo.status = [[dic safeObjectForKey:@"status"] intValue];
        if (recommandInfo.username.length > 0) {
            [temM objectAddObject:recommandInfo];
        }
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;
}

+ (BOOL)groupNewDataMigration {
    NSString *querySql = @"select c.identifier,c.name,c.ecdh_key,c.common,c.verify,c.pub,c.avatar,c.summary from t_group c";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *groupsArray = [NSMutableArray array];
    for (NSDictionary *dict in resultArray) {

        LMRamGroupInfo *ramGroup = [[LMRamGroupInfo alloc] init];
        ramGroup.groupIdentifer = [dict safeObjectForKey:@"identifier"];
        ramGroup.groupName = [dict safeObjectForKey:@"name"];
        ramGroup.groupEcdhKey = [dict safeObjectForKey:@"ecdh_key"];
        ramGroup.isCommonGroup = [[dict safeObjectForKey:@"common"] boolValue];
        ramGroup.isGroupVerify = [[dict safeObjectForKey:@"verify"] boolValue];
        ramGroup.isPublic = [[dict safeObjectForKey:@"pub"] boolValue];
        ramGroup.avatarUrl = [dict safeObjectForKey:@"avatar"];
        ramGroup.summary = [dict safeObjectForKey:@"summary"];
        NSMutableArray *memberArray = [self getgroupMemberByGroupIdentifier:ramGroup.groupIdentifer];
        NSMutableArray <LMRamMemberInfo *> *ramMemberArray = [NSMutableArray array];
        for (AccountInfo *info in memberArray) {
            LMRamMemberInfo *ramInfo = [[LMRamMemberInfo alloc] initWithNormalInfo:info];
            ramInfo.identifier = ramGroup.groupIdentifer;
            if (info.isGroupAdmin) {
                ramGroup.admin = ramInfo;
            }
            ramInfo.univerStr = [[NSString stringWithFormat:@"%@%@", ramInfo.address, ramGroup.groupIdentifer] sha1String];
            [ramMemberArray addObject:ramInfo];
        }
        [ramGroup.membersArray addObjects:ramMemberArray];
        [groupsArray objectAddObject:ramGroup];
    }
    if (groupsArray.count > 0) {
        [self realmAddObject:groupsArray];
    }
    return YES;

}

+ (NSMutableArray *)getgroupMemberByGroupIdentifier:(NSString *)groupid {
    if (GJCFStringIsNull(groupid)) {
        return nil;
    }
    NSArray *memberArray = [self recentQueryWithSql:[NSString stringWithFormat:@"select gm.username,gm.avatar,gm.pub_key,gm.address,gm.role,gm.nick,c.remark from t_group_Member as gm left join t_contact as c on c.pub_key = gm.pub_key where gm.identifier = '%@'", groupid]];
    if (memberArray.count <= 0) {
        return nil;
    }
    NSMutableArray *mutableMembers = [NSMutableArray array];
    AccountInfo *admin = nil;
    for (NSDictionary *dic in memberArray) {
        AccountInfo *accountInfo = [[AccountInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        NSString *remark = [dic valueForKey:@"remarks"];
        if (GJCFStringIsNull(remark) || [remark isEqual:[NSNull null]]) {
            accountInfo.groupNickName = [dic safeObjectForKey:@"nick"];
        } else {
            accountInfo.groupNickName = remark;
        }
        accountInfo.isGroupAdmin = ([[dic safeObjectForKey:@"role"] intValue] != 0);
        accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
        if (accountInfo.isGroupAdmin) {
            admin = accountInfo;
        } else {
            [mutableMembers objectAddObject:accountInfo];
        }
    }

    if (admin) {
        [mutableMembers objectInsert:admin atIndex:0];
    }
    return mutableMembers;
}

+ (BOOL)saveMessagesToRealm {
    //query
    NSString *querySql = @"select message_id,message_ower,content,send_status,snap_time,read_time,state,createtime from t_message";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *chatMessages = [NSMutableArray array];
    for (NSDictionary *temD in resultArray) {
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.ID = [[temD safeObjectForKey:@"id"] integerValue];
        chatMessage.messageOwer = [temD safeObjectForKey:@"message_ower"];
        chatMessage.messageId = [temD safeObjectForKey:@"message_id"];
        chatMessage.createTime = [[temD safeObjectForKey:@"createtime"] integerValue];
        chatMessage.readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        chatMessage.snapTime = [[temD safeObjectForKey:@"snap_time"] integerValue];
        chatMessage.sendstatus = [[temD safeObjectForKey:@"send_status"] integerValue];
        chatMessage.state = [[temD safeObjectForKey:@"state"] intValue];
        if (chatMessage.state == 0) {
            chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
        }

        NSDictionary *contentDict = [[temD safeObjectForKey:@"content"] mj_JSONObject];
        NSString *aad = [contentDict safeObjectForKey:@"aad"];
        NSString *iv = [contentDict safeObjectForKey:@"iv"];
        NSString *tag = [contentDict safeObjectForKey:@"tag"];
        NSString *ciphertext = [contentDict safeObjectForKey:@"ciphertext"];
        NSString *messageString = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];

        LMMessage *realmModel = [[LMMessage alloc] initWithNormalInfo:chatMessage];
        [chatMessages objectAddObject:realmModel];
    }
    if (chatMessages.count) {
        [self realmAddObject:chatMessages];
    }
    
    return YES;
}

+ (BOOL)saveRecentChatToRealm {
    //query
    NSString *querySql = @"select c.identifier,c.name,c.avatar,c.draft,c.stranger,c.last_time,c.unread_count,c.top,c.notice,c.type,c.content,s.snap_time,s.disturb from t_conversion c,t_conversion_setting s where c.identifier = s.identifier";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *recentChatArrayM = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        RecentChatModel *model = [RecentChatModel new];
        model.identifier = [resultDict safeObjectForKey:@"identifier"];
        model.name = [resultDict safeObjectForKey:@"name"];
        model.headUrl = [resultDict safeObjectForKey:@"avatar"];
        model.draft = [resultDict safeObjectForKey:@"draft"];
        model.stranger = [[resultDict safeObjectForKey:@"stranger"] boolValue];
        model.createTime = [NSDate dateWithTimeIntervalSince1970:[[resultDict safeObjectForKey:@"last_time"] longLongValue] / 1000];
        model.unReadCount = [[resultDict safeObjectForKey:@"unread_count"] intValue];
        model.isTopChat = [[resultDict safeObjectForKey:@"top"] boolValue];
        model.groupNoteMyself = [[resultDict safeObjectForKey:@"notice"] boolValue];
        model.talkType = [[resultDict safeObjectForKey:@"type"] intValue];
        model.content = [resultDict safeObjectForKey:@"content"];
        model.snapChatDeleteTime = [[resultDict safeObjectForKey:@"snap_time"] intValue];
        model.notifyStatus = [[resultDict safeObjectForKey:@"disturb"] boolValue];

        //package bradge model
        LMRecentChat *realmModel = [[LMRecentChat alloc] initWithNormalInfo:model];

        [recentChatArrayM addObject:realmModel];
    }
    if (recentChatArrayM.count) {
        [self realmAddObject:recentChatArrayM];
    }
    return YES;
}

+ (BOOL)contactNewDataMigration {
    NSString *querySql = @"select c.address,c.pub_key,c.avatar,c.username,c.remark,c.source,c.blocked,c.common from t_contact c";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *findUsers = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        AccountInfo *findUser = [AccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.remarks = [resultDict safeObjectForKey:@"remark"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] intValue];
        findUser.isBlackMan = [[resultDict safeObjectForKey:@"blocked"] boolValue];
        findUser.isOffenContact = [[resultDict safeObjectForKey:@"common"] boolValue];


        LMContactAccountInfo *realmContact = [[LMContactAccountInfo alloc] initWithNormalInfo:findUser];
        [findUsers addObject:realmContact];
    }
    if (findUsers.count > 0) {
        [self realmAddObject:findUsers];
    }
    return YES;

}

+ (void)realmAddObject:(NSMutableArray *)realmArray {

    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    for (RLMObject *realmModel in realmArray) {
        [realm addOrUpdateObject:realmModel];
    }
    [realm commitWriteTransaction];
}

@end
