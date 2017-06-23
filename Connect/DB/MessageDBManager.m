//
//  MessageDBManager.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MessageDBManager.h"
#import "LMMessageExtendManager.h"
#import "ConnectTool.h"
#import "LMMessage.h"

@interface MessageDBManager ()

@end


static MessageDBManager *manager = nil;

@implementation MessageDBManager

+ (MessageDBManager *)sharedManager {
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


- (BOOL)isMessageIsExistWithMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageOwer) || GJCFStringIsNull(messageId)) {
        return NO;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    if (message) {
        return YES;
    } else {
        return NO;
    }
}

- (void)saveMessage:(ChatMessageInfo *)messageInfo {
    NSString *messageString = [messageInfo.message mj_JSONString];
    if (GJCFStringIsNull(messageInfo.messageId) ||
            GJCFStringIsNull(messageInfo.messageOwer) ||
            GJCFStringIsNull(messageString)) {
        return;
    }
    LMMessage *realmModel = [[LMMessage alloc] initWithChatMessage:messageInfo];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:realmModel];
    }];
}

- (void)saveBitchMessage:(NSArray *)messages {
    NSMutableArray *bitchRealmMessages = [NSMutableArray array];
    for (ChatMessageInfo *messageInfo in messages) {
        NSString *messageString = [messageInfo.message mj_JSONString];
        if (GJCFStringIsNull(messageInfo.messageId) ||
                GJCFStringIsNull(messageInfo.messageOwer) ||
                GJCFStringIsNull(messageString)) {
            continue;
        }
        LMMessage *realmModel = [[LMMessage alloc] initWithChatMessage:messageInfo];
        [bitchRealmMessages addObject:realmModel];
    }
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObjectsFromArray:bitchRealmMessages];
    }];
}


- (MMMessage *)createTransactionMessageWithUserInfo:(AccountInfo *)user hashId:(NSString *)hashId monney:(NSString *)money {

    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeTransfer;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = user.pub_key;
    message.user_id = user.address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSending;
    message.content = hashId;
    message.ext1 = @{@"amount": @([money doubleValue] * pow(10, 8)),
            @"tips": @""};

    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
            @"publickey": [[LKUserCenter shareCenter] currentLoginUser].pub_key,
            @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};

    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = user.pub_key;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.message = message;
    messageInfo.snapTime = 0;
    messageInfo.readTime = 0;


    [self saveMessage:messageInfo];

    return message;

}


- (MMMessage *)createSendtoOtherTransactionMessageWithMessageOwer:(AccountInfo *)ower hashId:(NSString *)hashId monney:(NSString *)money isOutTransfer:(BOOL)isOutTransfer {
    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeTransfer;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = ower.pub_key;
    message.user_id = ower.address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.content = hashId;
    message.ext1 = @{@"amount": [[NSDecimalNumber decimalNumberWithString:money] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]].stringValue,
            @"tips": @""};
    message.senderInfoExt = @{@"username": [[LKUserCenter shareCenter] currentLoginUser].username,
            @"address": [[LKUserCenter shareCenter] currentLoginUser].address,
            @"publickey": [[LKUserCenter shareCenter] currentLoginUser].pub_key,
            @"avatar": [[LKUserCenter shareCenter] currentLoginUser].avatar};

    message.locationExt = @(isOutTransfer);

    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = ower.pub_key;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    messageInfo.message = message;
    messageInfo.snapTime = 0;
    messageInfo.readTime = 0;

    [self saveMessage:messageInfo];

    return message;
}


- (MMMessage *)createSendtoMyselfTransactionMessageWithMessageOwer:(AccountInfo *)messageOwer hashId:(NSString *)hashId monney:(NSString *)money isOutTransfer:(BOOL)isOutTransfer {


    MMMessage *message = [[MMMessage alloc] init];
    message.type = GJGCChatFriendContentTypeTransfer;
    message.sendtime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.message_id = [ConnectTool generateMessageId];
    message.publicKey = messageOwer.pub_key;
    message.user_id = [[LKUserCenter shareCenter] currentLoginUser].address;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    message.content = hashId;
    message.ext1 = @{@"amount": [[NSDecimalNumber decimalNumberWithString:money] decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]].stringValue,
            @"tips": @""};
    message.senderInfoExt = @{@"username": messageOwer.username,
            @"address": messageOwer.address,
            @"publickey": messageOwer.pub_key,
            @"avatar": messageOwer.avatar};

    message.locationExt = @(isOutTransfer);
    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = message.message_id;
    messageInfo.messageType = message.type;
    messageInfo.createTime = message.sendtime;
    messageInfo.messageOwer = messageOwer.pub_key;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    messageInfo.message = message;
    messageInfo.snapTime = 0;
    messageInfo.readTime = 0;

    [self saveMessage:messageInfo];

    return message;

}


- (void)updateMessageSendStatus:(GJGCChatFriendSendMessageStatus)sendStatus withMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    [self executeRealmWithBlock:^{
        message.sendstatus = sendStatus;
    }];
}

- (BOOL)deleteMessageByMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageId)) {
        return NO;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    if (message) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:message];
        }];
    }
    return YES;
}

- (void)deleteSnapOutTimeMessageByMessageOwer:(NSString *)messageOwer {

}

- (void)updataMessage:(ChatMessageInfo *)messageInfo {
    if (messageInfo &&
        !GJCFStringIsNull(messageInfo.messageOwer) &&
        !GJCFStringIsNull(messageInfo.messageId)) {
        LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageInfo.messageOwer,messageInfo.messageId]] firstObject];
        LMMessage *realmMsg = [[LMMessage alloc] initWithChatMessage:messageInfo];
        //update message
        [self executeRealmWithBlock:^{
            message.messageContent = realmMsg.messageContent;
            message.createTime = realmMsg.createTime;
            message.readTime = realmMsg.readTime;
            message.snapTime = realmMsg.snapTime;
            message.sendstatus = realmMsg.sendstatus;
            message.state = realmMsg.state;
        }];
    }
}

- (void)updateMessageTimeWithMessageOwer:(NSString *)messageOwer messageId:(NSString *)messageId {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }
    long long createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    [self executeRealmWithBlock:^{
        message.createTime = createTime;
    }];
}

- (void)updateMessageReadTimeWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }
    long long readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@' and readTime = 0",messageOwer,messageId]] firstObject];
    [self executeRealmWithBlock:^{
        message.readTime = readTime;
    }];
}

- (void)updateAudioMessageWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }

    long long readTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);

    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@' and readTime = 0",messageOwer,messageId]] firstObject];
    [self executeRealmWithBlock:^{
        message.readTime = readTime;
        message.state = 2;
    }];
}

- (void)updateAudioMessageReadCompleteWithMsgID:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    
    [self executeRealmWithBlock:^{
        message.state = 2;
    }];
}


- (NSInteger)getReadTimeByMessageId:(NSString *)messageId messageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return 0;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    return message.readTime;
}


- (ChatMessageInfo *)getMessageInfoByMessageid:(NSString *)messageId messageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return nil;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    if (message) {
        return [message chatMessageInfo];
    } else {
        return nil;
    }
}


- (GJGCChatFriendSendMessageStatus)getMessageSendStatusByMessageid:(NSString *)messageId messageOwer:(NSString *)messageOwer {
    
    if (GJCFStringIsNull(messageId) || GJCFStringIsNull(messageOwer)) {
        return GJGCChatFriendSendMessageStatusFaild;
    }
    LMMessage *message = [[LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@' and messageId = '%@'",messageOwer,messageId]] firstObject];
    return message.sendstatus;
}



- (NSArray *)getAllMessagesWithMessageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageOwer)) {
        return @[];
    }
    RLMResults <LMMessage *> *results = [LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@'",messageOwer]];
    
    NSMutableArray *chatMessages = [NSMutableArray array];
    //model trasfer
    for (LMMessage *realmModel in results) {
        ChatMessageInfo *model = [realmModel chatMessageInfo];
        [chatMessages addObject:model];
    }
    return chatMessages;
}

- (long long int)messageCountWithMessageOwer:(NSString *)messageOwer {
    if (GJCFStringIsNull(messageOwer)) {
        return 0;
    }
    RLMResults <LMMessage *> *results = [LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@'",messageOwer]];
    return results.count;
}

- (void)deleteAllMessageByMessageOwer:(NSString *)messageOwer {

    if (GJCFStringIsNull(messageOwer)) {
        return;
    }
    RLMResults <LMMessage *> *results = [LMMessage objectsWhere:[NSString stringWithFormat:@"messageOwer = '%@'",messageOwer]];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        for (LMMessage *realmMsg in results) {
            [realm deleteObject:realmMsg];
        }
    }];
}

- (void)deleteAllMessages {
    RLMResults <LMMessage *> *results = [LMMessage allObjects];
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        for (LMMessage *realmMsg in results) {
            [realm deleteObject:realmMsg];
        }
    }];
}

- (NSArray *)getMessagesWithMessageOwer:(NSString *)messageOwer Limit:(int)limit beforeTime:(long long int)time messageAutoID:(NSInteger)autoMsgid {
    if (GJCFStringIsNull(messageOwer)) {
        return @[];
    }
    
    NSMutableString *where = [NSMutableString stringWithFormat:@"messageOwer = '%@'",messageOwer];
    if (time > 0) {
        [where appendFormat:@" and ID < %ld and createTime <= %lld",autoMsgid,time];
    }
    RLMResults<LMMessage *> *results = [[LMMessage objectsWhere:where]
                                     sortedResultsUsingKeyPath:@"createTime" ascending:YES];
    NSMutableArray *chatMessages = [NSMutableArray array];
    if (results.count <= limit) {
        for (LMMessage *realmModel in results) {
            ChatMessageInfo *chatMessage = [realmModel chatMessageInfo];
            [chatMessages addObject:chatMessage];
        }
    } else {
        
        for (int i = (int)results.count - limit; i < results.count; i ++) {
            LMMessage *realmModel = results[i];
            ChatMessageInfo *chatMessage = [realmModel chatMessageInfo];
            [chatMessages addObject:chatMessage];
        }
    }
    return chatMessages;
}

- (NSArray *)getMessagesWithMessageOwer:(NSString *)messageOwer Limit:(int)limit beforeTime:(long long int)time {
    if (GJCFStringIsNull(messageOwer)) {
        return @[];
    }
    NSMutableString *where = [NSMutableString stringWithFormat:@"messageOwer = '%@'",messageOwer];
    if (time > 0) {
        [where appendFormat:@" and createTime <= %lld",time];
    }
    RLMResults<LMMessage *> *results = [[LMMessage objectsWhere:where]
                                  sortedResultsUsingKeyPath:@"createTime" ascending:YES];
    
    NSMutableArray *chatMessages = [NSMutableArray array];
    if (results.count <= limit) {
        for (LMMessage *realmModel in results) {
            ChatMessageInfo *chatMessage = [realmModel chatMessageInfo];
            [chatMessages addObject:chatMessage];
        }
    } else {
        for (int i = (int)results.count - limit; i < results.count; i ++) {
            LMMessage *realmModel = results[i];
            ChatMessageInfo *chatMessage = [realmModel chatMessageInfo];
            [chatMessages addObject:chatMessage];
        }
    }
    return chatMessages;
}


- (void)createTipMessageWithMessageOwer:(NSString *)messageOwer isnoRelationShipType:(BOOL)isnoRelationShipType content:(NSString *)content{
    GJGCChatFriendContentType type = GJGCChatFriendContentTypeStatusTip;
    if (isnoRelationShipType) {
        type = GJGCChatFriendContentTypeNoRelationShipTip;
    }
    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.messageId = [ConnectTool generateMessageId];
    chatMessage.messageOwer = messageOwer;
    chatMessage.messageType = type;
    chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.createTime = (long long) ([[NSDate date] timeIntervalSince1970] * 1000);
    MMMessage *message = [[MMMessage alloc] init];
    message.type = type;
    message.content = content;
    message.sendtime = chatMessage.createTime;
    message.message_id = chatMessage.messageId;
    message.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
    chatMessage.message = message;
    [self saveMessage:chatMessage];
}

@end
