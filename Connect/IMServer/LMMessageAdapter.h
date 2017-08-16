//
//  LMMessageAdapter.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"
#import "ChatMessageInfo.h"

@interface LMMessageAdapter : NSObject

+ (ChatMessageInfo *)decodeMessageWithMassagePost:(MessagePost *)msgPost;

+ (ChatMessageInfo *)decodeMessageWithMassagePost:(MessagePost *)msgPost groupECDH:(NSString *)groupECDH;

+ (ChatMessageInfo *)packSystemMessage:(MSMessage *)sysMsg;

+ (GPBMessage *)packageChatMsg:(ChatMessage *)chatMsg groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg;

+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg;

+ (MessageData *)packageChatMessageInfo:(ChatMessageInfo *)chatMessageInfo ext:(id)ext groupEcdh:(NSString *)groupEcdh;

@end
