//
//  LMBaseModel.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@implementation LMBaseModel

+ (void)initialize{
    [self setDefaultRealm];
}

+ (void)setDefaultRealm {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];

    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [docPath objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.realm",[[LKUserCenter shareCenter] currentLoginUser].address];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSLog(@"数据库目录 = %@",filePath);
    // Use the default directory, but replace the filename with the username
    config.fileURL = [NSURL URLWithString:filePath];
    config.readOnly = NO;
    config.schemaVersion = 1.0;
    // Set this as the configuration used for the default Realm
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

+ (NSString *)primaryKey{
    return @"ID";
}

+ (NSDictionary *)defaultPropertyValues{
    return @{
        @"ID":@((long long)([[NSDate date] timeIntervalSince1970] * 1000))
             };
}

@end
