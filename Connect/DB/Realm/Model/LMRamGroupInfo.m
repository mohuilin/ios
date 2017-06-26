//
//  LMRamGroupInfo.m
//  Connect
//
//  Created by Connect on 2017/6/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRamGroupInfo.h"
#import "LMGroupInfo.h"
@implementation LMRamGroupInfo

+ (NSString *)primaryKey {
    return @"groupIdentifer";
}
- (LMRamGroupInfo *)initWithNormalInfo:(id)groupInfos {
    if (self = [super init]) {
        if ([groupInfos isKindOfClass:[LMGroupInfo class]]) {
            LMGroupInfo *groupInfo = (LMGroupInfo *)groupInfos;
            self.groupIdentifer = groupInfo.groupIdentifer;
            self.groupName = groupInfo.groupName;
            self.groupEcdhKey = groupInfo.groupEcdhKey;
            self.isCommonGroup = groupInfo.isCommonGroup;
            self.isGroupVerify = groupInfo.isGroupVerify;
            self.isPublic = groupInfo.isPublic;
            self.avatarUrl = groupInfo.avatarUrl;
            self.summary = groupInfo.summary;
            NSMutableArray *memberArray = groupInfo.groupMembers;
            for (AccountInfo *info in memberArray) {
                LMRamMemberInfo *ramInfo = [[LMRamMemberInfo alloc] initWithNormalInfo:info];
                ramInfo.identifier = self.groupIdentifer;
                if (info.isGroupAdmin) {
                    self.admin = ramInfo;
                    
                }
                ramInfo.univerStr = [[NSString stringWithFormat:@"%@%@", ramInfo.address, self.groupIdentifer] sha1String];
                [self.membersArray addObject:ramInfo];
        }
      }
    }
    return self;
        
}
- (id)normalInfo {
    LMGroupInfo *groupInfo = [[LMGroupInfo alloc] init];
    groupInfo.groupIdentifer = self.groupIdentifer;
    groupInfo.groupName = self.groupName;
    groupInfo.groupEcdhKey = self.groupEcdhKey;
    groupInfo.isCommonGroup = self.isCommonGroup;
    groupInfo.isGroupVerify = self.isGroupVerify;
    groupInfo.isPublic = self.isPublic;
    groupInfo.avatarUrl = self.avatarUrl;
    groupInfo.summary = self.summary;
    NSMutableArray *temArray = [NSMutableArray array];
    RLMArray<LMRamMemberInfo *> *membersArray = self.membersArray;
    AccountInfo * admin = nil;
    for (LMRamMemberInfo *info in membersArray) {
        
        AccountInfo *accountInfo = (AccountInfo *)info.normalInfo;
        if (info.isGroupAdmin) {
            groupInfo.admin = accountInfo;
            admin = accountInfo;
        }else {
            [temArray addObject:accountInfo];
        }
        
    }
    if (admin) {
        [temArray insertObject:admin atIndex:0];
    }
    groupInfo.groupMembers = temArray;
    return groupInfo;
}
@end
