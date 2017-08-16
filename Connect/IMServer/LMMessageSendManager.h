//
//  LMMessageSendManager.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"

typedef void(^SendMessageCallBlock)(ChatMessage *message, NSError *error);

@interface SendMessageModel : NSObject

@property(nonatomic, strong) ChatMessage *sendMsg;
@property(nonatomic, strong) GPBMessage *originContent;
@property(nonatomic, assign) long long sendTime;
@property(nonatomic, copy) SendMessageCallBlock callBack;

@end

@interface LMMessageSendManager : NSObject

+ (instancetype)sharedManager;

- (void)addSendingMessage:(ChatMessage *)message originContent:(GPBMessage *)originContent callBack:(SendMessageCallBlock)callBack;

/**
 * message send success and callback
 * @param messageId
 */
- (void)messageSendSuccessMessageId:(NSString *)messageId;

/**
 * message send failed
 * @param messageId
 */
- (void)messageSendFailedMessageId:(NSString *)messageId;

/**
 * message send failed
 * cause your friend remove you , you are not in group
 * @param rejectMsg
 */
- (void)messageRejectedMessage:(RejectMessage *)rejectMsg;

@end
