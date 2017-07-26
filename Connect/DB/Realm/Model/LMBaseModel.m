//
//  LMBaseModel.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@implementation LMBaseModel

- (LMBaseModel *)initWithNormalInfo:(id)info {
    if (self = [super init]) {}
    return self;
}

- (id)normalInfo {
    return nil;
}

+ (NSString *)primaryKey {
    return @"ID";
}

+ (NSDictionary *)defaultPropertyValues {
    return @{
            @"ID": @((long long) ([[NSDate date] timeIntervalSince1970] * 1000))
    };
}

@end
