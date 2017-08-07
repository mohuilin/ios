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

@property (nonatomic ,assign) CurrencyType presentCurrency;

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
- (void)reEncryptBaseSeed:(NSString *)baseSeed priHex:(NSString *)priHex passWord:(NSString *)passWord category:(CategoryType)category complete:(void(^)(NSError *error))complete;


- (void)checkWalletExistAndCreateWalletOrCurrencyWithCurrency:(CurrencyType)currency complete:(void (^)(NSError *error))complete;
- (void)checkWalletExistWithBlock:(void (^)(BOOL existWallet))block;

@end
