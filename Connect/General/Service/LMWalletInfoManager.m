//
//  LMWalletInfoManager.m
//  Connect
//
//  Created by Connect on 2017/7/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletInfoManager.h"

@implementation LMWalletInfoManager
static LMWalletInfoManager *manager = nil;
CREATE_SHARED_MANAGER(LMWalletInfoManager)
+ (void)tearDown {
    manager = nil;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}
@end
