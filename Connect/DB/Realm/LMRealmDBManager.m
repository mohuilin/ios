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
#import "BaseDB.h"
#import "RecentChatModel.h"
#import "LMRecentChat.h"
#import "LMContactAccountInfo.h"
#import "RLMRealm+LMRLMRealm.h"
#import "LMRamGroupInfo.h"
#import "LMRamAccountInfo.h"



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
                if ([self recentChatDataMigration]) {
                    if (complete) {
                        complete(0.1);
                    }
                }
                //                // t_contact
                //                if ([self contactDataMigrations]) {
                //                    if (complete) {
                //                        complete(0.2);
                //                    }
                //                }
                //                // t_group
                //                if ([self groupDataMigration]) {
                //                    if (complete) {
                //                        complete(0.3);
                //                    }
                //                }
                //                //t_group_member
                //                if ([self groupMembersDataMigration]) {
                //                    if (complete) {
                //                        complete(0.4);
                //                    }
                //                }
                //                //t_addressbook
                //                if ([self addressbookDataMigration]) {
                //                    if (complete) {
                //                        complete(0.5);
                //                    }
                //                }
                //                if ([self recentChatSettingDataMigration]) {
                //                    if (complete) {
                //                        complete(0.5);
                //                    }
                //                }
                //                //t_recommand_friend
                //                if ([self recommandFriendDataMigration]) {
                //                    if (complete) {
                //                        complete(0.6);
                //                    }
                //                }
                //                //t_friendrequest
                //                if ([self friendRequestDataMigration]) {
                //                    if (complete) {
                //                        complete(0.7);
                //                    }
                //                }
                //                //t_transactiontable
                //                if ([self transactionDataMigration]) {
                //                    if (complete) {
                //                        complete(0.8);
                //                    }
                //                }
                //                //t_tag
                //                if ([self tagDataMigration]) {
                //                    if (complete) {
                //                        complete(0.9);
                //                    }
                //                }
                //                //t_usertag
                //                if ([self userTagDataMigration]) {
                //                    if (complete) {
                //                        complete(0.9);
                //                    }
                //                }
                //                //t_message
                //                if ([self messageDataMigration]) {
                //                    if (complete) {
                //                        complete(1);
                //                    }
                //                }
            }
            BOOL delete = GJCFFileDeleteFile(olddbPath);
            if (delete) {
                NSLog(@"delete success");
            }
        }
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
                    if ([self recentNewChatDataMigration]) {
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
+ (BOOL)recentNewChatDataMigration {
    
    NSMutableArray *recentArray = [NSMutableArray array];
    NSString *querySql = @"select c.identifier,c.name,c.avatar,c.draft,c.stranger,c.last_time,c.unread_count,c.top,c.notice,c.type,c.content,s.snap_time,s.disturb from t_conversion c,t_conversion_setting s where c.identifier = s.identifier order by c.last_time desc";
    NSArray *resultArray = [self recentQueryWithSql:querySql];
    
    for (NSDictionary *resultDict in resultArray) {
        LMRecentChat *model = [LMRecentChat new];
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
        [recentArray addObject:model];
    }
    if (recentArray.count) {
        [self realmAddObject:recentArray];
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
#pragma mark - old margon
+ (BOOL)recentChatSettingDataMigration {
    
    NSString *sql = @"select snapchat_luck_delete,identifier,notify_status from t_recent_conversion";
    NSArray *array = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"identifier"],
                                       [dict safeObjectForKey:@"snapchat_luck_delete"],
                                       [dict safeObjectForKey:@"notify_status"]]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_conversion_setting" fields:@[@"identifier", @"snap_time", @"disturb"] batchValues:bitchValues];
        
        
    }
    return YES;
}
+ (BOOL)recentChatDataMigration {
    
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    NSArray *contactRecentChats = [self queryWithSql:@"select c.public_key,c.is_friend,c.address,c.avatar,c.username,c.remarks,c.source,c.black_man,c.offen_contact,rc.identifier,rc.ecdh_aad,rc.ecdh_iv,rc.ecdh_tag,rc.ecdh_ciphertext,rc.last_time,rc.last_msg_content_type,rc.unread_count,rc.snapchat_luck_delete,rc.top_chat,rc.notify_status,rc.group_chat,rc.last_content from t_recent_conversion as rc inner join t_contact as c on rc.identifier = c.public_key where rc.group_chat = 0"];
    for (NSDictionary *dict in contactRecentChats) {
        NSString *identifier = [dict safeObjectForKey:@"public_key"];
        int type = 0;
        if ([identifier isEqualToString:kSystemIdendifier]) {
            type = 2;
        }
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"public_key"],
                                       [dict safeObjectForKey:@"username"],
                                       [dict safeObjectForKey:@"avatar"],
                                       @"",
                                       @(NO),
                                       [dict safeObjectForKey:@"last_time"],
                                       [dict safeObjectForKey:@"unread_count"],
                                       [dict safeObjectForKey:@"top_chat"],
                                       @(NO),
                                       @(type),
                                       [dict safeObjectForKey:@"last_content"]]];
    }
    
    NSArray *groupRecentChats = [self queryWithSql:@"select g.groupIdentifer,g.groupName,g.groupEcdhKey,g.commonGroup,g.groupVerify,g.groupPublic,g.avatarUrl,g.summary,g.backup,g.ecdh,rc.identifier,rc.ecdh_aad,rc.ecdh_iv,rc.ecdh_tag,rc.ecdh_ciphertext,rc.last_time,rc.last_msg_content_type,rc.group_note_myself,rc.unread_count,rc.snapchat_luck_delete,rc.top_chat,rc.notify_status,rc.group_chat,rc.last_content from t_recent_conversion as rc inner join t_group_information as g on rc.identifier = g.groupIdentifer where rc.group_chat = 1"];
    
    for (NSDictionary *dict in groupRecentChats) {
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"groupIdentifer"],
                                       [dict safeObjectForKey:@"groupName"],
                                       [dict safeObjectForKey:@"avatarUrl"],
                                       @"",
                                       @(NO),
                                       [dict safeObjectForKey:@"last_time"],
                                       [dict safeObjectForKey:@"unread_count"],
                                       [dict safeObjectForKey:@"top_chat"],
                                       [dict safeObjectForKey:@"group_note_myself"],
                                       @(1),
                                       [dict safeObjectForKey:@"last_content"]]];
    }
    
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_conversion" fields:@[@"identifier", @"name", @"avatar", @"draft", @"stranger", @"last_time", @"unread_count", @"top", @"notice", @"type", @"content"] batchValues:bitchValues];
    }
    return YES;
}
#pragma mark - private query method
+ (BOOL)contactDataMigrations {
    NSMutableArray *bitchValues = [NSMutableArray array];
    NSString *sql = @"select address,public_key,avatar,username,remarks,source,black_man,offen_contact from t_contact";
    NSArray *contactArray = [self queryWithSql:sql];
    for (NSDictionary *dict in contactArray) {
        
        NSMutableArray *temArray = [NSMutableArray array];
        [temArray addObject:[dict safeObjectForKey:@"address"]];
        [temArray addObject:[dict safeObjectForKey:@"public_key"]];
        [temArray addObject:[dict safeObjectForKey:@"avatar"]];
        [temArray addObject:[dict safeObjectForKey:@"username"]];
        [temArray addObject:[dict safeObjectForKey:@"remarks"]];
        [temArray addObject:@([[dict safeObjectForKey:@"source"] intValue])];
        [temArray addObject:@([[dict safeObjectForKey:@"black_man"] intValue])];
        [temArray addObject:@([[dict safeObjectForKey:@"offen_contact"] intValue])];
        
        [bitchValues objectAddObject:temArray];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_contact" fields:@[@"address", @"pub_key", @"avatar", @"username", @"remark", @"source", @"blocked", @"common"] batchValues:bitchValues.copy];
    }
    return YES;
}
+ (BOOL)groupDataMigration {
    
    NSString *sql = @"select groupIdentifer,groupName,groupEcdhKey,commonGroup,groupVerify,groupPublic,avatarUrl,summary from t_group_information";
    NSArray *array = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"groupIdentifer"],
                                       [dict safeObjectForKey:@"groupName"],
                                       [dict safeObjectForKey:@"groupEcdhKey"],
                                       [dict safeObjectForKey:@"commonGroup"],
                                       [dict safeObjectForKey:@"groupVerify"],
                                       [dict safeObjectForKey:@"groupPublic"],
                                       [dict safeObjectForKey:@"avatarUrl"],
                                       [dict safeObjectForKey:@"summary"]]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_group" fields:@[@"identifier", @"name", @"ecdh_key", @"common", @"verify", @"pub", @"avatar", @"summary"] batchValues:bitchValues];
        
        
    }
    return YES;
}

+ (BOOL)groupMembersDataMigration {
    NSString *sql = @"select groupIdentifer,username,avatar,address,role,nick,pubKey from t_group_Member";
    NSArray *array = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"groupIdentifer"],
                                       [dict safeObjectForKey:@"username"],
                                       [dict safeObjectForKey:@"avatar"],
                                       [dict safeObjectForKey:@"address"],
                                       [dict safeObjectForKey:@"role"],
                                       [dict safeObjectForKey:@"nick"],
                                       [dict safeObjectForKey:@"pubKey"]]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_group_member" fields:@[@"identifier", @"username", @"avatar", @"address", @"role", @"nick", @"pub_key"] batchValues:bitchValues];
        
        
    }
    return YES;
}

+ (BOOL)messageDataMigration {
    NSString *sql = @"select message_id ,message_ower,state,createtime,read_time,message_type,send_status,snap_time ,aad,iv,tag,ciphertext from t_messagetable";
    
    NSArray *messages = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (NSDictionary *temD in messages) {
        NSString *aad = [temD safeObjectForKey:@"aad"];
        NSString *iv = [temD safeObjectForKey:@"iv"];
        NSString *tag = [temD safeObjectForKey:@"tag"];
        NSString *ciphertext = [temD safeObjectForKey:@"ciphertext"];
        NSDictionary *contentDict = @{@"aad": aad,
                                      @"iv": iv,
                                      @"tag": tag,
                                      @"ciphertext": ciphertext};
        int state = [[temD safeObjectForKey:@"state"] intValue];
        NSInteger readTime = [[temD safeObjectForKey:@"read_time"] integerValue];
        if (state == 0) {
            state = readTime > 0 ? 1 : 0;
        }
        [bitchValues objectAddObject:@[[temD safeObjectForKey:@"message_id"],
                                       [temD safeObjectForKey:@"message_ower"],
                                       [contentDict mj_JSONString],
                                       [temD safeObjectForKey:@"send_status"],
                                       [temD safeObjectForKey:@"snap_time"],
                                       [temD safeObjectForKey:@"read_time"],
                                       @(state),
                                       [temD safeObjectForKey:@"createtime"]]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_message" fields:@[@"message_id", @"message_ower", @"content", @"send_status", @"snap_time", @"read_time", @"state", @"createtime"] batchValues:bitchValues];
        
        
    }
    return YES;
}

+ (BOOL)addressbookDataMigration {
    NSString *sql = @"select address,tag,create_time from t_addressbooktable";
    NSArray *array = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"address"],
                                       [dict safeObjectForKey:@"tag"],
                                       @([[dict safeObjectForKey:@"create_time"] integerValue])
                                       ]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_addressbook" fields:@[@"address", @"tag", @"create_time"] batchValues:bitchValues];
        
    }
    return YES;
}

+ (BOOL)recommandFriendDataMigration {
    NSString *sql = @"select username,address,avatar,pub_key,isSend from t_addMayMan";
    NSArray *selArray = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (NSDictionary *dic in selArray) {
        [bitchValues objectAddObject:@[[dic safeObjectForKey:@"username"],
                                       [dic safeObjectForKey:@"address"],
                                       [dic safeObjectForKey:@"avatar"],
                                       [dic safeObjectForKey:@"pub_key"],
                                       @([[dic safeObjectForKey:@"isSend"] intValue])]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_recommand_friend" fields:@[@"username", @"address", @"avatar", @"pub_key", @"status"] batchValues:bitchValues.copy];
        
        
    }
    return YES;
}

+ (BOOL)friendRequestDataMigration {
    NSString *sql = @"select address,public_key,avatar,username,source,role,status,create_time,request_msg_aad,request_msg_iv,request_msg_tag,request_msg_ciphertext from t_newfriendrequest";
    NSArray *array = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        GcmDataModel *msgModel = [GcmDataModel new];
        msgModel.aad = [dict safeObjectForKey:@"request_msg_aad"];
        msgModel.iv = [dict safeObjectForKey:@"request_msg_iv"];
        msgModel.tag = [dict safeObjectForKey:@"request_msg_tag"];
        msgModel.ciphertext = [dict safeObjectForKey:@"request_msg_ciphertext"];
        NSString *tips = @"";
        if (!GJCFStringIsNull(msgModel.ciphertext)) {
            NSData *data = [KeyHandle xtalkDecodeAES_GCMWithPassword:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:msgModel.ciphertext aad:msgModel.aad iv:msgModel.iv tag:msgModel.tag];
            tips = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        int role = [[dict safeObjectForKey:@"role"] intValue];
        int status = [[dict safeObjectForKey:@"status"] intValue];
        RequestFriendStatus requestStatus = RequestFriendStatusAccept;
        if (role == 1) {
            switch (status) {
                case 0: {
                    requestStatus = RequestFriendStatusVerfing;
                }
                    break;
                case 1: {
                    requestStatus = RequestFriendStatusAdded;
                }
                    break;
                    
                case 2: {
                    requestStatus = RequestFriendStatusAdd;
                }
                    break;
                default:
                    break;
            }
        }
        
        if (role == 2) {
            switch (status) {
                case 0: {
                    requestStatus = RequestFriendStatusAccept;
                }
                    break;
                case 1: {
                    requestStatus = RequestFriendStatusAdded;
                }
                    break;
                default:
                    break;
            }
        }
        
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"address"],
                                       [dict safeObjectForKey:@"public_key"],
                                       [dict safeObjectForKey:@"avatar"],
                                       [dict safeObjectForKey:@"username"],
                                       @([[dict safeObjectForKey:@"source"] intValue]),
                                       @(requestStatus),
                                       @(0),
                                       tips,
                                       [dict safeObjectForKey:@"create_time"]]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_friendrequest" fields:@[@"address", @"pub_key", @"avatar", @"username", @"source", @"status", @"read", @"tips", @"createtime"] batchValues:bitchValues.copy];
        
        
    }
    return YES;
    
}

+ (BOOL)transactionDataMigration {
    NSString *sql = @"select messageid,transactionid,transaction_status,aad,iv,tag,ciphertext,trasaction_type from t_transactiontable";
    NSArray *array = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    
    for (NSDictionary *dict in array) {
        int payCount = 0;
        int crowdCount = 0;
        if ([[dict safeObjectForKey:@"trasaction_type"] intValue] == 4) {
            NSString *ciphertext = [dict safeObjectForKey:@"ciphertext"];
            Crowdfunding *detailBill = nil;
            NSError *error = nil;
            if (!GJCFStringIsNull(ciphertext)) {
                NSString *tag = [dict safeObjectForKey:@"tag"];
                NSString *iv = [dict safeObjectForKey:@"iv"];
                NSString *aad = [dict safeObjectForKey:@"aad"];
                if (!GJCFStringIsNull(tag) && !GJCFStringIsNull(iv) && !GJCFStringIsNull(aad)) {
                    NSData *data = [KeyHandle xtalkDecodeAES_GCMWithPassword:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];
                    detailBill = [Crowdfunding parseFromData:data error:&error];
                }
                
            }
            crowdCount = (int) detailBill.remainSize;
            payCount = (int) (detailBill.size - detailBill.remainSize);
        }
        [bitchValues objectAddObject:@[[dict safeObjectForKey:@"messageid"],
                                       [dict safeObjectForKey:@"transactionid"],
                                       @([[dict safeObjectForKey:@"transaction_status"] intValue]),
                                       @(payCount),
                                       @(crowdCount)
                                       ]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_transactiontable" fields:@[@"message_id", @"hashid", @"status", @"pay_count", @"crowd_count"] batchValues:bitchValues.copy];
        
        
    }
    return YES;
}


+ (BOOL)tagDataMigration {
    NSString *sql = @"select tag from t_taglistt";
    NSArray *selArray = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (NSDictionary *dic in selArray) {
        [bitchValues objectAddObject:@[[dic safeObjectForKey:@"tag"]]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_tag" fields:@[@"tag"] batchValues:bitchValues.copy];
        
    }
    return YES;
}

+ (BOOL)userTagDataMigration {
    NSString *sql = @"select t.tag,t.auto_incrementid,ut.address,ut.tag from t_usertagtable as ut inner join t_taglistt as t on ut.tag = t.tag";
    NSArray *selArray = [self queryWithSql:sql];
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (NSDictionary *dic in selArray) {
        [bitchValues objectAddObject:@[@([[dic safeObjectForKey:@"auto_incrementid"] intValue]),
                                       [dic safeObjectForKey:@"address"]
                                       ]];
    }
    if (bitchValues.count) {
        //        return [self batchInsertTableName:@"t_usertag" fields:@[@"tag_id", @"address"] batchValues:bitchValues.copy];
        
    }
    return YES;
}
@end
