//
//  LMWalletInfoManager.m
//  Connect
//
//  Created by Connect on 2017/7/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletInfoManager.h"
#import "LMSeedModel.h"
#import "LMSeedModel.h"
#import "LMCurrencyModel.h"
#import "LMCurrencyManager.h"

@implementation LMWalletInfoManager
static LMWalletInfoManager *manager = nil;
CREATE_SHARED_MANAGER(LMWalletInfoManager)

- (NSString *)encryPtionSeed{
    if (_encryPtionSeed.length <= 0) {
        LMSeedModel *baseModel = [LMCurrencyManager getModelFromDB];
        return baseModel.encryptSeed;
    }
    return _encryPtionSeed;
}
- (BOOL)isHaveWallet{
    LMSeedModel *baseModel = [LMCurrencyManager getModelFromDB];
    if (baseModel.encryptSeed.length > 0) {
        return YES;
    }else {
        return NO;
    }
}
-(CategoryType)categorys{
  LMSeedModel *baseModel = [LMCurrencyManager getModelFromDB];
    switch (baseModel.status) {
        case 3:
        {
            return CategoryTypeOldUser;
        }
            break;
        case 0:
        {
            return CategoryTypeNewUser;
        }
            break;
        default:
        {
          LMCurrencyModel *currencyModel = [[LMCurrencyModel allObjects] lastObject];
            switch (currencyModel.category) {
                case 1:
                   return  CategoryTypeOldUser;
                    break;
                case 2:
                    return  CategoryTypeNewUser;
                    break;
                default:
                    return  CategoryTypeNewUser;
                    break;
            }
        }
            break;
    }
}
@end
