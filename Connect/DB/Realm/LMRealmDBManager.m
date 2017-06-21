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
#import "BaseDB.h"
#import "RecentChatModel.h"
#import "RLMRealm+LMRLMRealm.h"




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
                    //                    if ([self recentChatSettingDataMigration]) {
                    //                        if (complete) {
                    //                            complete(0.5);
                    //                        }
                    //                    }
                    //                    //t_recommand_friend
                    //                    if ([self recommandFriendDataMigration]) {
                    //                        if (complete) {
                    //                            complete(0.6);
                    //                        }
                    //                    }
                    //                    //t_friendrequest
                    //                    if ([self friendRequestDataMigration]) {
                    //                        if (complete) {
                    //                            complete(0.7);
                    //                        }
                    //                    }
                    //                    //t_transactiontable
                    //                    if ([self transactionDataMigration]) {
                    //                        if (complete) {
                    //                            complete(0.8);
                    //                        }
                    //                    }
                    //                    //t_tag
                    //                    if ([self tagDataMigration]) {
                    //                        if (complete) {
                    //                            complete(0.9);
                    //                        }
                    //                    }
                    //                    //t_usertag
                    //                    if ([self userTagDataMigration]) {
                    //                        if (complete) {
                    //                            complete(0.9);
                    //                        }
                    //                    }
                    //                    //t_message
                    //                    if ([self messageDataMigration]) {
                    //                        if (complete) {
                    //                            complete(1);
                    //                        }
                    //                    }
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
+ (BOOL)addressbookNewDataMigration {
    NSString *querySql = @"select * from t_addressbook c";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *temM = [NSMutableArray array];
    for (NSDictionary *temD in resultArray) {
        //        LMRamAddressBook *info = [[LMRamAddressBook alloc] init];
        //        info.address = [temD safeObjectForKey:@"address"];
        //        info.tag = [temD safeObjectForKey:@"tag"];
        //        [temM objectAddObject:info];
    }
    if (temM.count > 0) {
        [self realmAddObject:temM];
    }
    return YES;
    
}
+ (BOOL)groupNewMembersDataMigration {
    NSString *querySql = @"select * from t_group_member c";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    NSMutableArray *mutableMembers = [NSMutableArray array];
    long long indexNumber = 0;
    long long currenetTime = [[NSDate date] timeIntervalSince1970] * 1000;
    LMRamAccountInfo *admin = nil;
    for (NSDictionary *dic in resultArray) {
        indexNumber ++;
        NSString *currentString = [NSString stringWithFormat:@"%lld",(currenetTime + indexNumber)];
        LMRamAccountInfo *accountInfo = [[LMRamAccountInfo alloc] init];
        accountInfo.username = [dic safeObjectForKey:@"username"];
        accountInfo.identifier = [dic safeObjectForKey:@"identifier"];
        accountInfo.avatar = [dic safeObjectForKey:@"avatar"];
        accountInfo.address = [dic safeObjectForKey:@"address"];
        accountInfo.currentTime = currentString;
        NSString *remark = [dic valueForKey:@"remarks"];
        if (GJCFStringIsNull(remark) || [remark isEqual:[NSNull null]]) {
            accountInfo.groupNicksName = [dic safeObjectForKey:@"nick"];
        } else {
            accountInfo.groupNicksName = remark;
        }
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
        LMRamGroupInfo *lmGroup = [[LMRamGroupInfo alloc] init];
        lmGroup.groupIdentifer = [dict safeObjectForKey:@"identifier"];
        lmGroup.groupName = [dict safeObjectForKey:@"name"];
        lmGroup.groupEcdhKey = [dict safeObjectForKey:@"ecdh_key"];
        lmGroup.isCommonGroup = [[dict safeObjectForKey:@"common"] boolValue];
        lmGroup.isGroupVerify = [[dict safeObjectForKey:@"verify"] boolValue];
        lmGroup.isPublic = [[dict safeObjectForKey:@"pub"] boolValue];
        lmGroup.avatarUrl = [dict safeObjectForKey:@"avatar"];
        lmGroup.summary = [dict safeObjectForKey:@"summary"];
        //        lmGroup.groupMembers = [self getgroupMemberByGroupIdentifier:lmGroup.groupIdentifer];
        //        lmGroup.admin = [lmGroup.groupMembers firstObject];
        [groupsArray objectAddObject:lmGroup];
    }
    if (groupsArray.count > 0) {
        [self realmAddObject:groupsArray];
    }
    return YES;
    
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
