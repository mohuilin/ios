//
//  LMRamAccountInfo.m
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRamAccountInfo.h"
#import "LMRamGroupInfo.h"
@implementation LMRamAccountInfo

+(NSString *)primaryKey {
    return @"univerStr";
}

+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties{
    return @{
             @"group": [RLMPropertyDescriptor descriptorWithClass:LMRamGroupInfo.class propertyName:@"membersArray"],
             };
}

@end
