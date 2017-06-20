//
//  LMBaseModel.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@implementation LMBaseModel

+ (NSString *)primaryKey{
    return @"ID";
}

+ (NSDictionary *)defaultPropertyValues{
    NSString *ID = [NSString stringWithFormat:@"%lld",(long long)[[NSDate date] timeIntervalSince1970]];
    return @{
        @"ID":ID
             };
}

@end
