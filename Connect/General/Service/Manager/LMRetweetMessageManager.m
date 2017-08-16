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
    
    self.RetweetComplete = complete;
    ChatMessageInfo *chatMessageInfo = [self packSendMessageWithRetweetMessage:retweetModel.retweetMessage toFriend:retweetModel.toFriendModel];
    // save message
    [self savaMessageToDB:chatMessageInfo];
    if (chatMessageInfo.messageType == GJGCChatFriendContentTypeImage || chatMessageInfo.messageType == GJGCChatFriendContentTypeVideo) {
        
    }
}


- (ChatMessageInfo *)packSendMessageWithRetweetMessage:(ChatMessageInfo *)retweetMessage toFriend:(id)toFriend{
    ChatMessageInfo *messageInfo = [[ChatMessageInfo alloc] init];
    messageInfo.messageId = [ConnectTool generateMessageId];
    messageInfo.messageType = retweetMessage.messageType;
    messageInfo.createTime = [[NSDate date] timeIntervalSince1970] * 1000;
    messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
    messageInfo.msgContent = retweetMessage.msgContent;
    
    if ([toFriend isKindOfClass:[LMRamGroupInfo class]]) {
        LMRamGroupInfo *group = (LMRamGroupInfo *)toFriend;
        retweetMessage.messageOwer = group.groupIdentifer;
    } else if([toFriend isKindOfClass:[AccountInfo class]]){
        AccountInfo *user = (AccountInfo *)toFriend;
        retweetMessage.messageOwer = user.pub_key;
        RecentChatModel *recent = [[RecentChatDBManager sharedManager] getRecentModelByIdentifier:user.pub_key];
        if (recent.snapChatDeleteTime > 0) {
            messageInfo.snapTime = recent.snapChatDeleteTime;
        }
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
