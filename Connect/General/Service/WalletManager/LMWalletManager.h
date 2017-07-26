//
//  LMWalletManager.h
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTransferManager.h"
#import "LMSeedModel.h"
#import "LMCurrencyModel.h"

@interface LMWalletManager : NSObject
+ (instancetype)sharedManager;

- (LMSeedModel *)baseModel;

- (LMCurrencyModel *)currencyModelWith:(CurrencyType)currency;


- (void)creatWallet:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(NSError *error))complete;

/**
 *
 * get data from server
 */
- (void)getWalletData:(void(^)(RespSyncWallet *wallet,NSError *error))complete;

/**
 *  reset password methods
 *
 */
- (void)reSetPassWord:(NSString *)passWord baseSeed:(NSString *)baseSeed complete:(void(^)(NSError *error))complete;


- (void)checkWalletExistAndCreateWallet;

@end
