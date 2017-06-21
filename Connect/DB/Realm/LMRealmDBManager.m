//
//  LMRealmDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//
#import <FMDBMigrationManager/FMDBMigrationManager.h>
#import "LMRealmDBManager.h"
#import "RLMRealm+LMRLMRealm.h"
#import "MMGlobal.h"
#import "NSDictionary+LMSafety.h"
#import "LMHistoryCacheManager.h"
#import "LMRecentChat.h"
#import "RecentChatModel.h"
#import "LMRecentChat.h"
#import "LMContactAccountInfo.h"
#import "RLMRealm+LMRLMRealm.h"
#import "LMRamGroupInfo.h"
#import "LMRamAccountInfo.h"
#import "LMRamAddressBook.h"
#import "BaseDB.h"
#import "RecentChatModel.h"
#import "RLMRealm+LMRLMRealm.h"
#import "LMFriendRequestInfo.h"
#import "LMRamTransationInfo.h"
#import "LMRamMessageInfo.h"
#import "MMMessage.h"

@implementation LMRealmDBManager
static FMDatabaseQueue *queue;
+ (void)saveInfo:(LMBaseModel *)ramModel{
    [GCDQueue executeInGlobalQueue:^{
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        // Updating book with id = 1
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:ramModel];
        [realm commitWriteTransaction];
    }];
}
+ (void)dataMigrationWithComplete:(void (^)(CGFloat progress))complete {
    NSString *olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key.sha256String];
    if (GJCFFileIsExist(olddbPath)) {
        
    } else {
        olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
        if (GJCFFileIsExist(olddbPath)) {
            //db path
            NSString *dbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
            queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
            if (queue) {
                DDLogInfo(@"Create encryptdatabase success! %@", dbPath);
                FMDBMigrationManager *manager = [FMDBMigrationManager managerWithDatabaseAtPath:dbPath migrationsBundle:[NSBundle mainBundle]];
                BOOL resultState = NO;
                NSError *error = nil;
                if (!manager.hasMigrationsTable) {
                    resultState = [manager createMigrationsTable:&error];
                }
                resultState = [manager migrateDatabaseToVersion:UINT64_MAX progress:nil error:&error];
                if (resultState) {
                    //data migration
                    //t_conversion
                    if ([self saveRecentChatToRealm]) {
                        if (complete) {
                            complete(0.1);
                        }
                    }
                    if ([self contactNewDataMigration]) {
                        if (complete) {
                            complete(0.1);
                        }
                    }
                    
                    // t_group
                    if ([self groupNewDataMigration]) {
                        if (complete) {
                            complete(0.3);
                        }
                    }
                    //t_group_member
                    if ([self groupNewMembersDataMigration]) {
                        if (complete) {
                            complete(0.4);
                        }
                    }
                    //t_addressbook
                    if ([self addressbookNewDataMigration]) {
                        if (complete) {
                            complete(0.5);
                        }
                    }
                    //t_friend
                    if ([self friendRequestNewDataMigration]) {
                        if (complete) {
                            complete(0.5);
                        }
                    }
                    if ([self transationNewDataMigration]) {
                        if (complete) {
                            complete(0.5);
                        }
                    }
                    if ([self messageNewDataMigration]) {
                        if (complete) {
                            complete(0.5);
                        }
                    }
                   
                
                }
//                BOOL delete = GJCFFileDeleteFile(olddbPath);
//                if (delete) {
//                    NSLog(@"delete success");
//                }
            }
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
#pragma mark - new margon
+ (BOOL)messageNewDataMigration {
    NSString *querySql = @"select * from t_message";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *temM = [NSMutableArray array];
    for (NSDictionary *temD in resultArray) {
        LMRamMessageInfo *chatMessage = [[LMRamMessageInfo alloc] init];
        chatMessage.iD = [[temD safeObjectForKey:@"id"] integerValue];
        chatMessage.messageOwer = [temD safeObjectForKey:@"message_ower"];
        chatMessage.messageId = [temD safeObjectForKey:@"message_id"];
        chatMessage.createTime = [[temD safeObjectForKey:@"createtime"] integerValue];
        chatMessage.readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        chatMessage.snapTime = [[temD safeObjectForKey:@"snap_time"] integerValue];
        chatMessage.sendStatus = [[temD safeObjectForKey:@"send_status"] intValue];
        chatMessage.state = [[temD safeObjectForKey:@"state"] intValue];
        if (chatMessage.state == 0) {
            chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
        }
        [temM objectAddObject:chatMessage];
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;
}
+ (BOOL)transationNewDataMigration {
    NSString *querySql = @"select * from t_transactiontable";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *temM = [NSMutableArray array];
    for (NSDictionary *dic in resultArray) {
        LMRamTransationInfo *accountInfo = [[LMRamTransationInfo alloc] init];
        accountInfo.messageId = [dic safeObjectForKey:@"message_id"];
        accountInfo.hashId = [dic safeObjectForKey:@"hashid"];
        accountInfo.status = [[dic safeObjectForKey:@"status"] intValue];
        accountInfo.payCount = [[dic safeObjectForKey:@"pay_count"] intValue];
        accountInfo.crowdCount = [[dic safeObjectForKey:@"crowd_count"] intValue];
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;
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
        [temM objectAddObject:info];
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;
    
}
+ (BOOL)groupNewMembersDataMigration {
    NSString *querySql = @"select * from t_group_member";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *mutableMembers = [NSMutableArray array];
    LMRamAccountInfo *admin = nil;
    for (NSDictionary *dic in resultArray) {
        LMRamAccountInfo *accountInfo = [[LMRamAccountInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.identifier = [dic safeObjectForKey:@"identifier"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        NSString *remark = [dic valueForKey:@"remarks"];
        if (GJCFStringIsNull(remark) || [remark isEqual:[NSNull null]]) {
            accountInfo.groupNicksName = [dic safeObjectForKey:@"nick"];
        } else {
            accountInfo.groupNicksName = remark;
        }
        accountInfo.univerStr = [NSString stringWithFormat:@"%@%@",accountInfo.address,accountInfo.identifier];
        accountInfo.roleInGroup = [[dic safeObjectForKey:@"role"] intValue];
        accountInfo.pubKey = [dic safeObjectForKey:@"pub_key"];
        if (accountInfo.roleInGroup == 1) {
            admin = accountInfo;
            accountInfo.isGroupAdmin = YES;
        } else {
            [mutableMembers objectAddObject:accountInfo];
        }
    }
    if (admin) {
        [mutableMembers objectInsert:admin atIndex:0];
    }
    if (mutableMembers.count > 0) {
        [self realmAddObject:mutableMembers];
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
        NSMutableArray <LMRamAccountInfo *> *ramMemberArray = [NSMutableArray array];
        for (AccountInfo *info in memberArray) {
            LMRamAccountInfo *ramInfo = [LMRamAccountInfo new];
            ramInfo.identifier = ramGroup.groupIdentifer;
            ramInfo.username = info.username;
            ramInfo.avatar = info.avatar;
            ramInfo.address = info.address;
            ramInfo.roleInGroup = info.roleInGroup;
            ramInfo.groupNicksName = info.groupNickName;
            ramInfo.pubKey = info.pub_key;
            ramInfo.isGroupAdmin = info.isGroupAdmin;
            ramInfo.univerStr = [NSString stringWithFormat:@"%@%@",ramInfo.address,ramGroup.groupIdentifer];
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
        accountInfo.roleInGroup = [[dic safeObjectForKey:@"role"] intValue];
        accountInfo.pub_key = [dic safeObjectForKey:@"pub_key"];
        if (accountInfo.roleInGroup == 1) {
            admin = accountInfo;
            accountInfo.isGroupAdmin = YES;
        } else {
            [mutableMembers objectAddObject:accountInfo];
        }
    }
    
    if (admin) {
        [mutableMembers objectInsert:admin atIndex:0];
    }
    return mutableMembers;
}

+ (BOOL)saveRecentChatToRealm{
    //query
    NSString *querySql = @"select c.identifier,c.name,c.avatar,c.draft,c.stranger,c.last_time,c.unread_count,c.top,c.notice,c.type,c.content,s.snap_time,s.disturb from t_conversion c,t_conversion_setting s where c.identifier = s.identifier order by c.last_time desc";
    NSArray *resultArray = [self queryWithSql:querySql];
    NSMutableArray *recentChatArrayM = [NSMutableArray array];
    for (NSDictionary *resultDict in resultArray) {
        RecentChatModel *model = [RecentChatModel new];
        model.identifier = [resultDict safeObjectForKey:@"identifier"];
        model.name = [resultDict safeObjectForKey:@"name"];
        model.headUrl = [resultDict safeObjectForKey:@"avatar"];
        model.draft = [resultDict safeObjectForKey:@"draft"];
        model.stranger = [[resultDict safeObjectForKey:@"stranger"] boolValue];
        model.time = [[resultDict safeObjectForKey:@"last_time"] stringValue];
        model.unReadCount = [[resultDict safeObjectForKey:@"unread_count"] intValue];
        model.isTopChat = [[resultDict safeObjectForKey:@"top"] boolValue];
        model.groupNoteMyself = [[resultDict safeObjectForKey:@"notice"] boolValue];
        model.talkType = [[resultDict safeObjectForKey:@"type"] intValue];
        model.content = [resultDict safeObjectForKey:@"content"];
        model.snapChatDeleteTime = [[resultDict safeObjectForKey:@"snap_time"] intValue];
        model.notifyStatus = [[resultDict safeObjectForKey:@"disturb"] boolValue];
        
        //package bradge model
        LMRecentChat *realmModel = [LMRecentChat new];
        realmModel.identifier = model.identifier;
        realmModel.name = model.name;
        realmModel.headUrl = model.headUrl;
        realmModel.time = model.time;
        realmModel.content = model.content;
        realmModel.isTopChat = model.isTopChat;
        realmModel.stranger = model.stranger;
        realmModel.notifyStatus = model.notifyStatus;
        realmModel.groupNoteMyself = model.groupNoteMyself;
        realmModel.snapChatDeleteTime = model.snapChatDeleteTime;
        realmModel.unReadCount = model.unReadCount;
        realmModel.talkType = (int)model.talkType;
        realmModel.draft = model.draft;
        
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
        LMContactAccountInfo *findUser = [LMContactAccountInfo new];
        findUser.address = [resultDict safeObjectForKey:@"address"];
        findUser.pub_key = [resultDict safeObjectForKey:@"pub_key"];
        findUser.avatar = [resultDict safeObjectForKey:@"avatar"];
        findUser.username = [resultDict safeObjectForKey:@"username"];
        findUser.remarks = [resultDict safeObjectForKey:@"remark"];
        findUser.source = [[resultDict safeObjectForKey:@"source"] intValue];
        findUser.isBlackMan = [[resultDict safeObjectForKey:@"blocked"] boolValue];
        findUser.isOffenContact = [[resultDict safeObjectForKey:@"common"] boolValue];
        [findUsers addObject:findUser];
        
    }
    if (findUsers.count > 0) {
        [self realmAddObject:findUsers];
    }
    return YES;
    
}
+ (void)realmAddObject:(NSMutableArray *)realmArray {
    
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObjectsFromArray:realmArray];
    [realm commitWriteTransaction];
    
    
}
#pragma mark - private query method
@end
