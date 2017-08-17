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
#import "LMConnectIMChater.h"
#import "LMMessageTool.h"

@interface LMRetweetMessageManager ()

@property (copy ,nonatomic) void (^RetweetComplete)(NSError *error,float progress);

@end

@implementation LMRetweetMessageManager

CREATE_SHARED_MANAGER(LMRetweetMessageManager)

- (void)retweetMessageWithModel:(LMRerweetModel *)retweetModel
                       complete:(void (^)(NSError *error,float progress))complete{
    
    /// 封装一条消息
    self.RetweetComplete = complete;
    ChatMessageInfo *chatMessageInfo = [self packSendMessageWithRetweetMessage:retweetModel.retweetMessage toFriend:retweetModel.toFriendModel];
    /// 保存消息
    [self savaMessageToDB:chatMessageInfo];
    
    /// 迁移富文本数据 ,重新定义富文本的消息体的内容（清除之前消息的url信息，保留基本信息）
    switch (retweetModel.retweetMessage.messageType) {
        case GJGCChatFriendContentTypeImage:
        {
            ///重新定义富文本的消息体的内容（清除之前消息的url信息，保留基本信息）
            PhotoMessage *orginPhoto = (PhotoMessage *)retweetModel.retweetMessage.msgContent;
            chatMessageInfo.msgContent = [LMMessageTool makePhotoWithImageW:orginPhoto.imageWidth imageH:orginPhoto.imageHeight oriImage:nil thumImage:nil];
            
            /// 迁移富文本数据
            NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            NSString *originFilePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                        stringByAppendingPathComponent:retweetModel.retweetMessage.messageOwer];
            
            NSString *currentFilePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                                        stringByAppendingPathComponent:chatMessageInfo.messageOwer];
            ;
            
            NSString *originImagePath = [originFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", retweetModel.retweetMessage.messageId]];
            NSString *toImagePath = [currentFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", chatMessageInfo.messageId]];
            
            NSString *originThumbImagePath = [originFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-thumb.jpg", retweetModel.retweetMessage.messageId]];
            NSString *toThumbImagePath = [currentFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-thumb.jpg", chatMessageInfo.messageId]];
            
            GJCFFileCopyFileIsRemove(originImagePath, toImagePath, NO);
            GJCFFileCopyFileIsRemove(originThumbImagePath, toThumbImagePath, NO);
            
        }
            break;
            
        case GJGCChatFriendContentTypeVideo:
        {
            VideoMessage *orginVideo = (VideoMessage *)retweetModel.retweetMessage.msgContent;
            chatMessageInfo.msgContent = [LMMessageTool makeVideoWithSize:orginVideo.size time:orginVideo.timeLength videoCoverW:orginVideo.imageWidth videoCoverH:orginVideo.imageHeight videoUrl:nil videoCover:nil];
            
            /// 迁移富文本数据
            NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
            NSString *originFilePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                                        stringByAppendingPathComponent:retweetModel.retweetMessage.messageOwer];
            
            NSString *currentFilePath = [[filePath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address]
                                         stringByAppendingPathComponent:chatMessageInfo.messageOwer];
            ;
            
            NSString *originCoverPath = [originFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-coverimage.jpg", retweetModel.retweetMessage.messageId]];
            NSString *toImagePath = [currentFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@coverimage.jpg", chatMessageInfo.messageId]];
            
            NSString *originVideoPath = [originFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", retweetModel.retweetMessage.messageId]];
            NSString *toVideoPath = [currentFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", chatMessageInfo.messageId]];
            
            GJCFFileCopyFileIsRemove(originCoverPath, toImagePath, NO);
            GJCFFileCopyFileIsRemove(originVideoPath, toVideoPath, NO);
            
        }
            break;
        default:
            break;
    }
    
    /// 发送数据
    [[LMConnectIMChater sharedManager] sendChatMessageInfo:chatMessageInfo progress:^(NSString *to, NSString *msgId, CGFloat progress) {
        
    } complete:^(ChatMessageInfo *chatMsgInfo, NSError *error) {
        
    }];
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
