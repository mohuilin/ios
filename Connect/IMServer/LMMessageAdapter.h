//
//  LMMessageAdapter.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"
#import "MMMessage.h"

@interface LMMessageAdapter : NSObject
/**
 * Encapsulates the data body of the im message
 * @param message
 * @param talkType
 * @param ecdhKey
 * @return
 */
+ (GPBMessage *)sendAdapterIMPostWithMessage:(MMMessage *)message talkType:(GJGCChatFriendTalkType)talkType ecdhKey:(NSString *)ecdhKey;

+ (NSString *)decodeMessageWithMassagePost:(MessagePost *)msgPost;

+ (MMMessage *)packSystemMessage:(MSMessage *)sysMsg;


+ (MessageData *)packageMessageDataWithTo:(NSString *)to chatType:(int)chatType msgType:(int)msgType ext:(id)ext groupEcdh:(NSString *)groupEcdh cipherData:(GPBMessage *)originMsg;

@end
