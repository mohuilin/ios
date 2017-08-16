//
//  LMRetweetMessageManager.m
//  Connect
//
//  Created by MoHuilin on 2017/1/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRetweetMessageManager.h"
#import "ReconmandChatListPage.h"
#import "MessageDBManager.h"
#import "LMRamGroupInfo.h"
#import "RecentChatDBManager.h"
#import "IMService.h"
#import "LMConversionManager.h"
#import "StringTool.h"

@interface LMRetweetMessageManager ()

@property (copy ,nonatomic) void (^RetweetComplete)(NSError *error,float progress);

@end

@implementation LMRetweetMessageManager

CREATE_SHARED_MANAGER(LMRetweetMessageManager)

- (void)retweetMessageWithModel:(LMRerweetModel *)retweetModel
                       complete:(void (^)(NSError *error,float progress))complete{
    
    /// 迁移数据
    switch (retweetModel.retweetMessage.messageType) {
        case GJGCChatFriendContentTypeImage:
        {
            
        }
            break;
            
        case GJGCChatFriendContentTypeVideo:
        {
            
        }
            break;
        default:
            break;
    }
    
    self.RetweetComplete = complete;
    ChatMessageInfo *chatMessageInfo = [self packSendMessageWithRetweetMessage:retweetModel.retweetMessage toFriend:retweetModel.toFriendModel];
    // save message
    [self savaMessageToDB:chatMessageInfo];
}


- (ChatMessageInfo *)packSendMessageWithRetweetMessage:(ChatMessageInfo *)retweetMessage toFriend:(id)toFriend{
    
    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = [ConnectTool generateMessageId];
    messageInfo.messageType = retweetMessage.messageType;
    messageInfo.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.msgContent = retweetMessage.msgContent;
    messageInfo.from = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
    
    if ([toFriend isKindOfClass:[LMRamGroupInfo class]]) {
        LMRamGroupInfo *group = (LMRamGroupInfo *)toFriend;
        messageInfo.messageOwer = group.groupIdentifer;
        messageInfo.chatType = ChatType_Groupchat;
    } else if([toFriend isKindOfClass:[AccountInfo class]]){
        AccountInfo *user = (AccountInfo *)toFriend;
        messageInfo.messageOwer = user.pub_key;
        messageInfo.chatType = ChatType_Private;
        RecentChatModel *recent = [[RecentChatDBManager sharedManager] getRecentModelByIdentifier:user.pub_key];
        messageInfo.snapTime = recent.snapChatDeleteTime;
    }
    return messageInfo;
}

- (void)updateMessageToDB:(ChatMessageInfo *)messageInfo{
    [[MessageDBManager sharedManager] updataMessage:messageInfo];
}


- (void)savaMessageToDB:(ChatMessageInfo *)chatMessageInfo{

    [[MessageDBManager sharedManager] saveMessage:chatMessageInfo];
    // send message
    [GCDQueue executeInMainQueue:^{
        SendNotify(RereweetMessageNotification, chatMessageInfo);
    }];
    
}

@end
