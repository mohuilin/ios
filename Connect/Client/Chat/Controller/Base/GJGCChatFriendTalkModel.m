//
//  GJGCChatFriendTalkModel.m
//  Connect
//
//  Created by KivenLin on 14-11-24.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendTalkModel.h"

@implementation GJGCChatFriendTalkModel

- (NSString *)fileDocumentName {
    _fileDocumentName = self.chatIdendifier;
    return _fileDocumentName;
}

- (NSString *)group_ecdhKey {
    if (!_group_ecdhKey) {
        _group_ecdhKey = self.chatGroupInfo.groupEcdhKey;
    }
    return _group_ecdhKey;
}

- (LMRamGroupInfo *)chatGroupInfo{
    LMRamGroupInfo *group = [[LMRamGroupInfo objectsWhere:[NSString stringWithFormat:@"groupIdentifer = '%@'",self.chatIdendifier]] lastObject];
    return group;
}

@end
