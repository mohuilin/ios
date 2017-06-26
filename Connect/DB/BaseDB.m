//
//  BaseDB.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseDB.h"

@implementation BaseDB


- (void)executeRealmWithBlock:(void (^)())executeBlock {
    if (executeBlock) {
        
        [GCDQueue executeInGlobalQueue:^{
            RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
            [realm beginWriteTransaction];
            executeBlock();
            NSError *error = nil;
            [realm commitWriteTransaction:&error];
            if (error) {
                DDLogInfo(@"realm commit error %@",error);
            }
        }];
    }
}

- (void)executeRealmWithRealmBlock:(void (^)(RLMRealm *realm))executeBlock {
    if (executeBlock) {
        [GCDQueue executeInGlobalQueue:^{
            RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
            [realm beginWriteTransaction];
            executeBlock(realm);
            NSError *error = nil;
            [realm commitWriteTransaction:&error];
            if (error) {
                DDLogInfo(@"realm commit error %@",error);
            }
        }];
    }
}

@end
