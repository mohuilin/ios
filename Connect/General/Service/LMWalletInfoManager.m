//
//  LMWalletInfoManager.m
//  Connect
//
//  Created by Connect on 2017/7/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletInfoManager.h"
#import "LMSeedModel.h"
#import "LMBTCWalletHelper.h"

@implementation LMWalletInfoManager
static LMWalletInfoManager *manager = nil;
CREATE_SHARED_MANAGER(LMWalletInfoManager)

- (NSString *)encryPtionSeed{
    if (_encryPtionSeed.length <= 0) {
        LMSeedModel *baseModel = [[LMSeedModel allObjects] lastObject];
        return baseModel.encryptSeed;
    }
    return _encryPtionSeed;
}

@end
