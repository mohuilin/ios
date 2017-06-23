//
//  LMMessage.m
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessage.h"
#import "NSDictionary+LMSafety.h"

@implementation LMMessage

+ (NSString *)primaryKey{
    return @"uniqueId";
}


- (LMMessage *)initWithChatMessage:(ChatMessageInfo *)chatMessage{

    if (self = [super init]) {
        self.messageId = chatMessage.messageId;
        self.messageOwer = chatMessage.messageOwer;
        
        //set uniqueid  ,ensure message unique
        self.uniqueId = [[NSString stringWithFormat:@"%@_%@",self.messageId,self.messageOwer] sha1String];
        
        //message encrypt
        NSString *aad = [[NSString stringWithFormat:@"%d", arc4random() % 100 + 1000] sha1String];
        NSString *iv = [[NSString stringWithFormat:@"%d", arc4random() % 100 + 1000] sha1String];
        NSDictionary *encodeDict = [KeyHandle xtalkEncodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:[chatMessage.message mj_JSONString] aad:aad iv:iv];
        NSString *ciphertext = encodeDict[@"encryptedDatastring"];
        NSString *tag = encodeDict[@"tagstring"];
        NSMutableDictionary *content = [NSMutableDictionary dictionary];
        [content safeSetObject:aad forKey:@"aad"];
        [content safeSetObject:iv forKey:@"iv"];
        [content safeSetObject:ciphertext forKey:@"ciphertext"];
        [content safeSetObject:tag forKey:@"tag"];
        
        self.messageContent = [content mj_JSONString];
        self.createTime = chatMessage.createTime;
        self.readTime = chatMessage.readTime;
        self.snapTime = chatMessage.snapTime;
        self.sendstatus = chatMessage.sendstatus;
        self.state = chatMessage.state;
        switch (chatMessage.messageType) {
            case GJGCChatFriendContentTypeTransfer:{
                LMMessageExt *msgExt = [[LMMessageExt alloc] init];
                msgExt.messageId = chatMessage.messageId;
                msgExt.status = 1;
                self.msgExt = msgExt;
            }
                break;
            case GJGCChatFriendContentTypePayReceipt:{
                LMMessageExt *msgExt = [[LMMessageExt alloc] init];
                msgExt.messageId = chatMessage.messageId;
                self.msgExt = msgExt;
            }
                break;
                
            default:
                break;
        }
    }
    return self;
}

- (ChatMessageInfo *)chatMessageInfo{

    ChatMessageInfo *chatMessage = [[ChatMessageInfo alloc] init];
    chatMessage.ID = self.ID;
    chatMessage.messageOwer = self.messageOwer;
    chatMessage.messageId = self.messageId;
    chatMessage.createTime = self.createTime;
    chatMessage.readTime = self.readTime;
    chatMessage.snapTime = self.snapTime;
    chatMessage.sendstatus = self.sendstatus;
    chatMessage.state = self.state;
    if (chatMessage.state == 0) {
        chatMessage.state = chatMessage.readTime > 0 ? 1 : 0;
    }
    NSDictionary *contentDict = [self.messageContent mj_JSONObject];
    NSString *aad = [contentDict safeObjectForKey:@"aad"];
    NSString *iv = [contentDict safeObjectForKey:@"iv"];
    NSString *tag = [contentDict safeObjectForKey:@"tag"];
    NSString *ciphertext = [contentDict safeObjectForKey:@"ciphertext"];
    NSString *messageString = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];
    chatMessage.message = [MMMessage mj_objectWithKeyValues:messageString];
    chatMessage.message.sendstatus = chatMessage.sendstatus;
    chatMessage.message.isRead = chatMessage.readTime > 0;
    chatMessage.messageType = chatMessage.message.type;
    
    return chatMessage;
}

@end
