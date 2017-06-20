//
//  LMRealmDBManager.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRealmDBManager.h"
#import "MMGlobal.h"
#import "RLMRealm+LMRLMRealm.h"

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

+ (void)saveInfo:(LMBaseModel *)ramModel{
    [GCDQueue executeInGlobalQueue:^{
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        // Updating book with id = 1
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:ramModel];
        [realm commitWriteTransaction];
    }];
}

@end
