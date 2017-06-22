//
//  LMRealmDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRealmDBManager.h"
#import "MMGlobal.h"
#import "BaseDB.h"
#import "RecentChatModel.h"
#import "LMRecentChat.h"
#import "LMMessage.h"

@implementation LMRealmDBManager

+ (void)migartion{
    NSString *olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key.sha256String];
    if (GJCFFileIsExist(olddbPath)) {
        
    } else {
        olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
        if (GJCFFileIsExist(olddbPath)) {
            //data migration
//            [self saveRecentChatToRealm];
//            
//            
//            [self saveMessagesToRealm];
            
            //remove old database
            
        }
    }
}


+ (void)saveMessagesToRealm{
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
        
        chatMessage.message = [MMMessage mj_objectWithKeyValues:messageString];
        chatMessage.message.sendstatus = chatMessage.sendstatus;
        chatMessage.message.isRead = chatMessage.readTime > 0;
        chatMessage.messageType = chatMessage.message.type;
        
        LMMessage *realmModel = [[LMMessage alloc] initWithChatMessage:chatMessage];
        [chatMessages objectAddObject:realmModel];
    }
    if (chatMessages.count) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm addOrUpdateObjectsFromArray:chatMessages];
        [realm commitWriteTransaction];
    }
}


+ (void)saveRecentChatToRealm{
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
        model.talkType = [[resultDict safeObjectForKey:@"type"] integerValue];
        model.content = [resultDict safeObjectForKey:@"content"];
        model.snapChatDeleteTime = [[resultDict safeObjectForKey:@"snap_time"] intValue];
        model.notifyStatus = [[resultDict safeObjectForKey:@"disturb"] boolValue];
        
        
        //package bradge model
        LMRecentChat *realmModel = [[LMRecentChat alloc] initWithRecentModel:model];
        
        [recentChatArrayM addObject:realmModel];
    }
    if (recentChatArrayM.count) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm addOrUpdateObjectsFromArray:recentChatArrayM];
        [realm commitWriteTransaction];
    }
}


#pragma mark - private query method
+ (NSArray *)queryWithSql:(NSString *)sql {
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

@end
