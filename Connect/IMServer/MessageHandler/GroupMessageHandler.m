/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupMessageHandler.h"
#import "NSString+DictionaryValue.h"
#import "NetWorkOperationTool.h"
#import "GroupDBManager.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "SystemTool.h"
#import "ConnectTool.h"
#import "LMMessageValidationTool.h"
#import "LMConversionManager.h"
#import "LMMessageExtendManager.h"
#import "LMRamMemberInfo.h"
#import "LMRamGroupInfo.h"


@interface GroupMessageHandler ()

@property(nonatomic, strong) NSMutableArray *downloadGroupArray;
@property(nonatomic, strong) NSMutableDictionary *unHandleMessagees;

@end

@implementation GroupMessageHandler

+ (GroupMessageHandler *)instance {
    static GroupMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[GroupMessageHandler alloc] init];
        }
    });
    return m;
}

- (instancetype)init {
    if (self = [super init]) {
        self.recentChatObservers = [NSHashTable weakObjectsHashTable];
        self.getNewMessageObservers = [NSHashTable weakObjectsHashTable];
        self.downloadGroupArray = [NSMutableArray array];
        self.unHandleMessagees = [NSMutableDictionary dictionary];
    }

    return self;
}

/**
 * Batch processing group offline message
 */
- (BOOL)handleBatchGroupMessage:(NSArray *)messages {

    NSMutableDictionary *owerMessagesDict = [NSMutableDictionary dictionary];
    NSMutableArray *messageExtendArray = [NSMutableArray array];
    for (MessagePost *msg in messages) {
        NSString *identifer = msg.msgData.chatMsg.to;
        LMRamGroupInfo *group = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:identifer];
        if (GJCFStringIsNull(group.groupEcdhKey)) {
            NSMutableArray *messages = [self.unHandleMessagees valueForKey:identifer];
            if (messages) {
                [messages addObject:msg];
            } else {
                messages = [NSMutableArray array];
                [messages addObject:msg];
                [self.unHandleMessagees setObject:messages forKey:identifer];
            }
            CreateGroupMessage *createMsg = [[CreateGroupMessage alloc] init];
            createMsg.identifier = identifer;
            if (![self.downloadGroupArray containsObject:identifer]) {
                [self.downloadGroupArray objectAddObject:identifer];
                [SetGlobalHandler downGroupEcdhKeyWithGroupIdentifier:identifer complete:^(NSString *groupKey, NSError *error) {
                    if (!error && !GJCFStringIsNull(groupKey)) {
                        createMsg.secretKey = groupKey;
                        [self getGroupInfoFromNetWorkWithGroupInfo:createMsg];
                    } else {
                        [self.downloadGroupArray removeObject:identifer];
                    }
                }];
            }
            continue;
        }
        GcmData *gcmD = msg.msgData.chatMsg.cipherData;
        NSString *messageString = [ConnectTool decodeGroupGcmDataWithEcdhKey:group.groupEcdhKey GcmData:gcmD];
        MMMessage *messageInfo = [MMMessage mj_objectWithKeyValues:[messageString dictionaryValue]];
        if (![LMMessageValidationTool checkMessageValidata:messageInfo messageType:MessageTypeGroup]) {
            continue;
        }

        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.messageId = messageInfo.message_id;
        chatMessage.createTime = messageInfo.sendtime;
        chatMessage.messageType = messageInfo.type;
        chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        chatMessage.readTime = 0;
        chatMessage.message = messageInfo;
        chatMessage.messageOwer = identifer;

        NSMutableDictionary *msgDict = [owerMessagesDict valueForKey:chatMessage.messageOwer];
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        BOOL groupNoteMyself = [[msgDict valueForKey:@"groupNoteMyself"] boolValue];
        if (msgDict) {
            [messages objectAddObject:chatMessage];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessage.messageType]) {
                unReadCount++;

                [msgDict setValue:@(unReadCount) forKey:@"unReadCount"];
            }
            if (!groupNoteMyself && chatMessage.messageType == GJGCChatFriendContentTypeText) {
                NSArray *array = messageInfo.ext1;
                if (![messageInfo.ext1 isKindOfClass:[NSArray class]]) {
                    array = [messageInfo.ext1 mj_JSONObject];
                }
                if ([array containsObject:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    [msgDict setValue:@(YES) forKey:@"groupNoteMyself"];
                }
            }
        } else {
            messages = [NSMutableArray array];
            [messages objectAddObject:chatMessage];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessage.messageType]) {
                unReadCount = 1;
            }
            if (!groupNoteMyself && chatMessage.messageType == GJGCChatFriendContentTypeText) {
                NSArray *array = messageInfo.ext1;
                if (![messageInfo.ext1 isKindOfClass:[NSArray class]]) {
                    array = [messageInfo.ext1 mj_JSONObject];
                }
                if ([array containsObject:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    groupNoteMyself = YES;
                }
            }
            NSMutableDictionary *msgDict = @{@"messages": messages,
                    @"unReadCount": @(unReadCount),
                    @"groupNoteMyself": @(groupNoteMyself)}.mutableCopy;
            [owerMessagesDict setObject:msgDict forKey:chatMessage.messageOwer];
        }
        if (chatMessage.messageType == GJGCChatFriendContentTypeText) {
            messageInfo.ext1 = nil;
        }
        if (chatMessage.messageType == GJGCChatFriendContentTypePayReceipt ||
            chatMessage.messageType == GJGCChatFriendContentTypeTransfer) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict safeSetObject:messageInfo.message_id forKey:@"message_id"];
            [dict safeSetObject:messageInfo.content forKey:@"hashid"];
            if (chatMessage.messageType == GJGCChatFriendContentTypePayReceipt) {
                [dict safeSetObject:@(1) forKey:@"status"];
            } else {
                [dict safeSetObject:@(0) forKey:@"status"];
            }
            [dict safeSetObject:@(0) forKey:@"pay_count"];
            [dict safeSetObject:@(0) forKey:@"crowd_count"];
            [messageExtendArray addObject:dict];
        }
    }
    
    [[LMMessageExtendManager sharedManager] saveBitchMessageExtend:messageExtendArray];

    for (NSDictionary *msgDict in owerMessagesDict.allValues) {
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        BOOL groupNoteMyself = [[msgDict valueForKey:@"groupNoteMyself"] boolValue];
        [messages sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
            ChatMessageInfo *r1 = obj1;
            ChatMessageInfo *r2 = obj2;
            int long long time1 = r1.createTime;
            int long long time2 = r2.createTime;
            if (time1 < time2) {
                return NSOrderedAscending;
            } else if (time1 == time2) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        }];

        NSMutableArray *pushMessages = [NSMutableArray arrayWithArray:messages];
        while (pushMessages.count > 0) {
            if (pushMessages.count > 20) {
                NSInteger location = 0;
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:[pushMessages subarrayWithRange:NSMakeRange(location, 20)]];
                [pushMessages removeObjectsInRange:NSMakeRange(location, 20)];
                [self pushGetBitchNewMessages:pushArray];

                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];

                ChatMessageInfo *lastMsg = [pushArray lastObject];
                if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
                    unReadCount = 0;
                }

                [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount groupNoteMyself:groupNoteMyself];
                //notice onece, clear unread count
                unReadCount = 0;
                
            } else {
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:pushMessages];

                [self pushGetBitchNewMessages:pushArray];

                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];

                ChatMessageInfo *lastMsg = [pushArray lastObject];
                if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
                    unReadCount = 0;
                }

                [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount groupNoteMyself:groupNoteMyself];

                [pushMessages removeAllObjects];
            }
        }

    }
    return YES;
}

/**
 *  Update last message status
 *
 *  @param chatMsg
 *  @param messageCount
 */
- (void)updataRecentChatLastMessageStatus:(ChatMessageInfo *)chatMsg messageCount:(int)messageCount groupNoteMyself:(BOOL)groupNoteMyself {
    [[LMConversionManager sharedManager] getNewMessagesWithLastMessage:chatMsg newMessageCount:messageCount groupNoteMyself:groupNoteMyself];
}

- (BOOL)handleBatchGroupInviteMessage:(NSArray *)messages {

    for (MessagePost *msg in messages) {
        GcmData *gcmD = msg.msgData.chatMsg.cipherData;
        NSData *data = [ConnectTool decodeGcmDataGetDataWithEcdhKey:[[ServerCenter shareCenter] getCurrentServer_userEcdhkey] GcmData:gcmD];
        CreateGroupMessage *groupMessage = [CreateGroupMessage parseFromData:data error:nil];
        //upload Group encryption key
        [SetGlobalHandler uploadGroupEcdhKey:groupMessage.secretKey groupIdentifier:groupMessage.identifier];
        //download group info
        [self getGroupInfoFromNetWorkWithGroupInfo:groupMessage];
    }
    return YES;
}

- (BOOL)handleGroupInviteMessage:(MessagePost *)msg {
    GcmData *gcmD = msg.msgData.chatMsg.cipherData;
    NSData *data = [ConnectTool decodeGcmDataWithGcmData:gcmD publickey:msg.pubKey needEmptySalt:YES];
    if (data.length <= 0) {
        return NO;
    }
    CreateGroupMessage *groupMessage = [CreateGroupMessage parseFromData:data error:nil];
    //upload Group encryption key
    [SetGlobalHandler uploadGroupEcdhKey:groupMessage.secretKey groupIdentifier:groupMessage.identifier];
    [self getGroupInfoFromNetWorkWithGroupInfo:groupMessage];
    return NO;
}


- (BOOL)handleMessage:(MessagePost *)msg {
    if (![[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:msg.msgData.chatMsg.to] && [GJGCChatFriendConstans shouldNoticeWithType:msg.msgData.chatMsg.msgType]) {
        if (![[SessionManager sharedManager].chatSession isEqualToString:msg.msgData.chatMsg.to]) {
            [SystemTool vibrateOrVoiceNoti];
        }
    };

    [self handleBatchGroupMessage:@[msg]];
    return YES;
}

- (void)addGetNewMessageObserver:(id <MessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers addObject:oberver];
}

- (void)removeGetNewMessageObserver:(id <MessageHandlerGetNewMessage>)oberver {
    [self.getNewMessageObservers removeObject:oberver];
}

- (void)pushGetBitchNewMessages:(NSArray *)messages {

    ChatMessageInfo *lastMsg = [messages lastObject];
    if ([[SessionManager sharedManager].chatSession isEqualToString:lastMsg.messageOwer]) {
        for (id <MessageHandlerGetNewMessage> ob in self.getNewMessageObservers) {
            if ([ob respondsToSelector:@selector(getBitchNewMessage:)]) {
                [GCDQueue executeInMainQueue:^{
                    [ob getBitchNewMessage:messages];
                }];
            }
        }
    }
}

- (void)getGroupInfoFromNetWorkWithGroupInfo:(CreateGroupMessage *)groupInfo {

    GroupId *groupidProto = [[GroupId alloc] init];
    groupidProto.identifier = groupInfo.identifier;
    __weak __typeof(&*self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:GroupGetGroupInfoUrl postProtoData:groupidProto.data complete:^(id hresponse) {
        HttpResponse *httpResponse = (HttpResponse *) hresponse;
        if (httpResponse.code != successCode) {
            [self.downloadGroupArray removeObject:groupInfo.identifier];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hresponse];
        if (data) {
            GroupInfo *group = [GroupInfo parseFromData:data error:nil];
            [weakSelf savaToDBWith:group createGroupInfo:groupInfo];
        }
    }                                  fail:^(NSError *error) {
        [self.downloadGroupArray removeObject:groupInfo.identifier];
    }];

}


- (void)savaToDBWith:(GroupInfo *)group createGroupInfo:(CreateGroupMessage *)createGroupinfo {

    LMRamGroupInfo *lmGroup = [[LMRamGroupInfo alloc] init];
    lmGroup.groupIdentifer = createGroupinfo.identifier;
    lmGroup.groupEcdhKey = createGroupinfo.secretKey;
    lmGroup.groupName = group.group.name;
    lmGroup.avatarUrl = group.group.avatar;
    lmGroup.isPublic = group.group.public_p;
    lmGroup.isGroupVerify = group.group.reviewed;
    lmGroup.summary = group.group.summary;
    lmGroup.isGroupVerify = group.group.reviewed;
    lmGroup.avatarUrl = group.group.avatar;
    NSMutableArray *AccoutInfoArray = [NSMutableArray array];
    LMRamMemberInfo * admin = nil;
    for (GroupMember *member in group.membersArray) {
        LMRamMemberInfo *accountInfo = [[LMRamMemberInfo alloc] init];
        accountInfo.username = member.username;
        accountInfo.avatar = member.avatar;
        accountInfo.address = member.address;
        accountInfo.isGroupAdmin = (member.role != 0);
        accountInfo.groupNicksName = member.nick;
        if (accountInfo.groupNicksName.length <= 0) {
            accountInfo.groupNicksName = member.username;
        }
        accountInfo.pubKey = member.pubKey;
        accountInfo.identifier = lmGroup.groupIdentifer;
        accountInfo.univerStr = [[NSString stringWithFormat:@"%@%@",accountInfo.address,accountInfo.identifier] sha1String];
        if (!accountInfo.isGroupAdmin) {
            [AccoutInfoArray objectAddObject:accountInfo];
        }else {
            lmGroup.admin = accountInfo;
            admin = accountInfo;
        }
        
    }
    if (admin) {
         [AccoutInfoArray insertObject:admin atIndex:0];
    }
    [lmGroup.membersArray addObjects:AccoutInfoArray];
    
    [[GroupDBManager sharedManager] savegroup:lmGroup];
    
    //remove downloading
    [self.downloadGroupArray removeObject:createGroupinfo.identifier];

    //handle message
    [self handMessage:[self.unHandleMessagees objectForKey:createGroupinfo.identifier] groupInfo:lmGroup];
    
    [self.unHandleMessagees removeObjectForKey:createGroupinfo.identifier];
}

- (void)handMessage:(NSArray *)unHandleMessage groupInfo:(LMRamGroupInfo *)lmGroup{
    
    NSMutableDictionary *owerMessagesDict = [NSMutableDictionary dictionary];
    NSMutableArray *messageExtendArray = [NSMutableArray array];
    for (MessagePost *msg in unHandleMessage) {
        GcmData *gcmD = msg.msgData.chatMsg.cipherData;
        NSString *messageString = [ConnectTool decodeGroupGcmDataWithEcdhKey:lmGroup.groupEcdhKey GcmData:gcmD];
        MMMessage *messageInfo = [MMMessage mj_objectWithKeyValues:[messageString dictionaryValue]];
        if (![LMMessageValidationTool checkMessageValidata:messageInfo messageType:MessageTypeGroup]) {
            continue;
        }
        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
        chatMessage.messageId = messageInfo.message_id;
        chatMessage.createTime = messageInfo.sendtime;
        chatMessage.messageType = messageInfo.type;
        chatMessage.sendstatus = GJGCChatFriendSendMessageStatusSuccess;
        chatMessage.readTime = 0;
        chatMessage.message = messageInfo;
        chatMessage.messageOwer = lmGroup.groupIdentifer;
        
        NSMutableDictionary *msgDict = [owerMessagesDict valueForKey:chatMessage.messageOwer];
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        BOOL groupNoteMyself = [[msgDict valueForKey:@"groupNoteMyself"] boolValue];
        if (msgDict) {
            [messages objectAddObject:chatMessage];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessage.messageType]) {
                unReadCount++;
                
                [msgDict setValue:@(unReadCount) forKey:@"unReadCount"];
            }
            
            if (!groupNoteMyself && chatMessage.messageType == GJGCChatFriendContentTypeText) {
                NSArray *array = messageInfo.ext1;
                if (![messageInfo.ext1 isKindOfClass:[NSArray class]]) {
                    array = [messageInfo.ext1 mj_JSONObject];
                }
                if ([array containsObject:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    [msgDict setValue:@(YES) forKey:@"groupNoteMyself"];
                }
            }
        } else {
            messages = [NSMutableArray array];
            [messages addObject:chatMessage];
            if ([GJGCChatFriendConstans shouldNoticeWithType:chatMessage.messageType]) {
                unReadCount = 1;
            }
            
            if (!groupNoteMyself && chatMessage.messageType == GJGCChatFriendContentTypeText) {
                NSArray *array = messageInfo.ext1;
                if (![messageInfo.ext1 isKindOfClass:[NSArray class]]) {
                    array = [messageInfo.ext1 mj_JSONObject];
                }
                if ([array containsObject:[[LKUserCenter shareCenter] currentLoginUser].address]) {
                    groupNoteMyself = YES;
                }
            }
            NSMutableDictionary *msgDict = @{@"messages": messages,
                                             @"unReadCount": @(unReadCount),
                                             @"groupNoteMyself": @(groupNoteMyself)}.mutableCopy;
            [owerMessagesDict setObject:msgDict forKey:chatMessage.messageOwer];
        }
        
        if (chatMessage.messageType == GJGCChatFriendContentTypeText) {
            messageInfo.ext1 = nil;
        }
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict safeSetObject:chatMessage.messageId forKey:@"message_id"];
        [dict safeSetObject:chatMessage.message.content forKey:@"hashid"];
        [dict safeSetObject:@(0) forKey:@"status"];
        [dict safeSetObject:@(chatMessage.payCount) forKey:@"pay_count"];
        [dict safeSetObject:@(chatMessage.crowdCount) forKey:@"crowd_count"];
        [messageExtendArray addObject:dict];
    }
    [[LMMessageExtendManager sharedManager] saveBitchMessageExtend:messageExtendArray];
    for (NSDictionary *msgDict in owerMessagesDict.allValues) {
        NSMutableArray *messages = [msgDict valueForKey:@"messages"];
        int unReadCount = [[msgDict valueForKey:@"unReadCount"] intValue];
        BOOL groupNoteMyself = [[msgDict valueForKey:@"groupNoteMyself"] boolValue];
        [messages sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
            ChatMessageInfo *r1 = obj1;
            ChatMessageInfo *r2 = obj2;
            int long long time1 = r1.createTime;
            int long long time2 = r2.createTime;
            if (time1 < time2) {
                return NSOrderedAscending;
            } else if (time1 == time2) {
                return NSOrderedSame;
            } else {
                return NSOrderedDescending;
            }
        }];
        
        NSMutableArray *pushMessages = [NSMutableArray arrayWithArray:messages];
        while (pushMessages.count > 0) {
            if (pushMessages.count > 20) {
                NSInteger location = pushMessages.count - 20;
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:[pushMessages subarrayWithRange:NSMakeRange(location, 20)]];
                [pushMessages removeObjectsInRange:NSMakeRange(location, 20)];
                [self pushGetBitchNewMessages:pushArray];
                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];
            } else {
                NSMutableArray *pushArray = [NSMutableArray arrayWithArray:pushMessages];
                [self pushGetBitchNewMessages:pushArray];
                [[MessageDBManager sharedManager] saveBitchMessage:pushArray];
                [pushMessages removeAllObjects];
            }
        }
        
        ChatMessageInfo *lastMsg = [messages lastObject];
        [self updataRecentChatLastMessageStatus:lastMsg messageCount:unReadCount groupNoteMyself:groupNoteMyself];
    }

}


@end
