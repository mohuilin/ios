//
//  LMChatMsgUploadManager.m
//  Connect
//
//  Created by MoHuilin on 2017/8/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMChatMsgUploadManager.h"
#import "ConnectTool.h"
#import "LMIMHelper.h"
#import "GJCFFileUploadManager.h"


@implementation LMChatMsgUploadManager

CREATE_SHARED_MANAGER(LMChatMsgUploadManager)

- (void)uploadMainData:(NSData *)mainData minorData:(NSData *)minorData encryptECDH:(NSData *)ecdhkey to:(NSString *)to msgId:(NSString *)msgId chatType:(int)chatType originMsg:(GPBMessage *)originMsg progress:(void (^)(NSString *to,NSString *msgId,CGFloat progress))progress  complete:(void(^)(GPBMessage *originMsg,NSString *to,NSString *msgId,NSError *error))completion {
    
    if (chatType != ChatType_ConnectSystem) {
        ecdhkey = [LMIMHelper getAes256KeyByECDHKeyAndSalt:ecdhkey salt:[ConnectTool get64ZeroData]];
        if (!mainData) {
            if (completion) {
                completion(nil,nil,nil,[NSError errorWithDomain:@"" code:-1 userInfo:nil]);
            }
            return;
        }
        GcmData *mainGcmdata = [ConnectTool createGcmDataWithStructDataEcdhkey:ecdhkey data:mainData aad:nil];
        
        RichMedia *richMedia = [[RichMedia alloc] init];
        richMedia.entity = mainGcmdata.data;
        if (minorData) {
            GcmData *minorGcmdata = [ConnectTool createGcmDataWithStructDataEcdhkey:ecdhkey data:minorData aad:nil];
            richMedia.thumbnail = minorGcmdata.data;
        }
        
        NSString *taskIdentifier = nil;
        GJCFFileUploadTask *uploadTask = [GJCFFileUploadTask taskWithUploadData:richMedia.data taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
        uploadTask.userInfo = @{@"originMsg":originMsg,
                                @"system":@(chatType == ChatType_ConnectSystem),
                                @"to":to,
                                @"msgId":msgId};
        [[GJCFFileUploadManager shareUploadManager] addTask:uploadTask];
    } else {
        RichMedia *richMedia = [[RichMedia alloc] init];
        richMedia.entity = mainData;
        richMedia.thumbnail = minorData;
        NSString *taskIdentifier = nil;
        GJCFFileUploadTask *uploadTask = [GJCFFileUploadTask taskWithUploadData:richMedia.data taskObserver:nil getTaskUniqueIdentifier:&taskIdentifier];
        uploadTask.userInfo = @{@"originMsg":originMsg,
                                @"system":@(chatType == ChatType_ConnectSystem),
                                @"to":to,
                                @"msgId":msgId};
        [[GJCFFileUploadManager shareUploadManager] addTask:uploadTask];
    }
    
    [[GJCFFileUploadManager shareUploadManager] setFaildBlock:^(GJCFFileUploadTask *task, NSError *error) {
        if (completion) {
            completion(nil,nil,nil,error);
        }
        /// 发送上传成功的通知
        SendNotify(ConnnectUploadFileFailedNotification, task.userInfo);
    } forObserver:self];

    [[GJCFFileUploadManager shareUploadManager] setCompletionBlock:^(GJCFFileUploadTask *task, FileData *fileData) {
        if (completion) {
            GPBMessage *originMsg = [task.userInfo valueForKey:@"originMsg"];
            BOOL system = [[task.userInfo valueForKey:@"system"] boolValue];
            NSString *chatId = [task.userInfo valueForKey:@"to"];
            NSString *msgId = [task.userInfo valueForKey:@"msgId"];

            NSString *fileUrl = nil;
            if (system) {
                fileUrl = [NSString stringWithFormat:@"%@?token=%@", fileData.URL, fileData.token];
            } else {
                fileUrl = [NSString stringWithFormat:@"%@?pub_key=%@&token=%@", fileData.URL, chatId, fileData.token];
            }
            if (originMsg) {
                if ([originMsg isKindOfClass:[VoiceMessage class]]) {
                    VoiceMessage *voice = (VoiceMessage *)originMsg;
                    voice.URL = fileUrl;
                } else if ([originMsg isKindOfClass:[VideoMessage class]]) {
                    VideoMessage *video = (VideoMessage *)originMsg;
                    video.URL = fileUrl;
                    video.cover = [NSString stringWithFormat:@"%@/thumb?pub_key=%@&token=%@", fileData.URL, chatId, fileData.token];
                } else if ([originMsg isKindOfClass:[PhotoMessage class]]) {
                    PhotoMessage *photo = (PhotoMessage *)originMsg;
                    photo.URL = fileUrl;
                    if (!system) {
                        photo.thum = [NSString stringWithFormat:@"%@/thumb?pub_key=%@&token=%@", fileData.URL, chatId, fileData.token];
                    }
                } else if ([originMsg isKindOfClass:[LocationMessage class]]) {
                    LocationMessage *location = (LocationMessage *)originMsg;
                    location.screenShot = fileUrl;
                }
                completion(originMsg,chatId,msgId,nil);
            }
            /// 发送上传成功的通知
            SendNotify(ConnnectUploadFileSuccessNotification, task.userInfo);
        }
    } forObserver:self];
    [[GJCFFileUploadManager shareUploadManager] setProgressBlock:^(GJCFFileUploadTask *task, CGFloat progressValue) {
        if (progress) {
            NSString *chatId = [task.userInfo valueForKey:@"to"];
            NSString *msgId = [task.userInfo valueForKey:@"msgId"];
            progress(chatId,msgId,progressValue);
        }
    } forObserver:self];
}

@end
