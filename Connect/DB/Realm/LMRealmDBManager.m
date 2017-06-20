//
//  LMRealmDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRealmDBManager.h"

@implementation LMRealmDBManager

+ (void)saveRecentChat:(LMRecentChat *)recentChat{
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [docPath objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:@"test.realm"];
    NSLog(@"数据库目录 = %@",filePath);
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.fileURL = [NSURL URLWithString:filePath];
    config.readOnly = NO;
    int currentVersion = 2.0;
    config.schemaVersion = currentVersion;
    
    config.migrationBlock = ^(RLMMigration *migration , uint64_t oldSchemaVersion) {
        if (oldSchemaVersion < currentVersion) {
            [migration enumerateObjects:LMRecentChat.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                if (currentVersion == 2) {
                    newObject[@"identifier2"] = @"";
                }
            }];
        }
    };
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        RLMRealm *realm = [RLMRealm defaultRealm];
        // Updating book with id = 1
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:recentChat];
        [realm commitWriteTransaction];
    });
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    recentChat.unReadCount = 1234;
    [realm commitWriteTransaction];
}

@end
