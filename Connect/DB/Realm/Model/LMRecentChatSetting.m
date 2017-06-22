//
//  LMRecentChatSetting.m
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRecentChatSetting.h"

@implementation LMRecentChatSetting

+ (NSString *)primaryKey{
    return @"identifier";
}

+ (NSDictionary *)defaultPropertyValues{
    NSMutableDictionary *defaultValues = [super defaultPropertyValues].mutableCopy;
    if (defaultValues) {
        [defaultValues setObject:@(NO) forKey:@"notifyStatus"];
        [defaultValues setObject:@(0) forKey:@"snapChatDeleteTime"];
        return defaultValues;
    } else{
        return @{@"notifyStatus":@(NO),
                 @"snapChatDeleteTime":@(0)};
    }
}

@end
