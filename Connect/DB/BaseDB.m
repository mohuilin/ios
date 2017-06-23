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
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        executeBlock();
        [realm commitWriteTransaction];
    }
}

- (void)executeRealmWithRealmBlock:(void (^)(RLMRealm *realm))executeBlock {
    if (executeBlock) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        executeBlock(realm);
        [realm commitWriteTransaction];
    }
}

@end
