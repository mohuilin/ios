//
//  LMMessageValidationTool.h
//  Connect
//
//  Created by MoHuilin on 2016/12/29.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChatMessageInfo;

typedef NS_ENUM(NSInteger, MessageType) {
    MessageTypePersion = 0,
    MessageTypeGroup,
    MessageTypeSystem,
};

@interface LMMessageValidationTool : NSObject

/**
 * Check the legality of the message
 * @param message
 * @param msgType
 * @return
 */
+ (BOOL)checkMessageValidata:(ChatMessageInfo *)message messageType:(MessageType)msgType;

@end
