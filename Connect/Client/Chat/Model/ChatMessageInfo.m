//
//  ChatMessageInfo.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatMessageInfo.h"
#import "NSDictionary+LMSafety.h"

@implementation ChatMessageInfo

- (NSInteger)snapTime{
    switch (self.messageType) {
        case GJGCChatFriendContentTypeGif:{
            EmotionMessage *msg = (EmotionMessage *)self.msgContent;
            return msg.snapTime;
        }
            break;
            
        case GJGCChatFriendContentTypeText:{
            TextMessage *msg = (TextMessage *)self.msgContent;
            return msg.snapTime;
        }
            break;
            
        case GJGCChatFriendContentTypeImage:{
            PhotoMessage *msg = (PhotoMessage *)self.msgContent;
            return msg.snapTime;
        }
            break;
            
        case GJGCChatFriendContentTypeAudio:{
            VoiceMessage *msg = (VoiceMessage *)self.msgContent;
            return msg.snapTime;
        }
            break;
            
        case GJGCChatFriendContentTypeVideo:{
            VideoMessage *msg = (VideoMessage *)self.msgContent;
            return msg.snapTime;
        }
            break;
        default:
            break;
    }
    
    return 0;
}

@end
