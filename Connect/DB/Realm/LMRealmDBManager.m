//
//  LMRealmDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRealmDBManager.h"
#import "MMGlobal.h"

@implementation LMRealmDBManager

+ (void)migartion{
    NSString *olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key.sha256String];
    if (GJCFFileIsExist(olddbPath)) {
    
    } else {
        olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
        if (GJCFFileIsExist(olddbPath)) {
            
        }
    }
}

+ (void)saveRecentChat:(LMRecentChat *)recentChat{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *realm = [RLMRealm defaultRealm];
        // Updating book with id = 1
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:recentChat];
        [realm commitWriteTransaction];
    });
}

@end
