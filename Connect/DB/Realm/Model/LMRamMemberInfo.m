//
//  LMRamMemberInfo.m
//  Connect
//
//  Created by Connect on 2017/6/23.
//  Copyright © 2017年 Connect. All rights reserved.
//
#import "LMRamMemberInfo.h"
#import "LMRamGroupInfo.h"

@implementation LMRamMemberInfo

+(NSString *)primaryKey {
    return @"univerStr";
}

+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties{
    return @{
             @"group": [RLMPropertyDescriptor descriptorWithClass:LMRamGroupInfo.class propertyName:@"membersArray"],
             };
}

@end
