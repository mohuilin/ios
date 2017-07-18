//
//  LMCurrencyManager.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wallet.pbobjc.h"
#import "LMSeedModel.h"
@interface LMCurrencyManager : NSObject
#pragma mark - save data to db
/**
 *  sync model to db
 *
 */
+ (void)saveModelToDB:(LMSeedModel *)seedModel;
/**
 * get data from db
 *
 */
+ (LMSeedModel *)getModelFromDB;
#pragma mark - Interface data
/**
 *  sync wallet data
 *
 */
+ (void)syncWalletData:(void (^)(BOOL result))complete;

/**
 *  creat currency
 *
 */
+ (void)createCurrency:(int)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess complete:(void (^)(BOOL result))complete;

/**
 *  get currrency list
 *
 */
+ (void)getCurrencyListWithWalletId:(NSString *)walletId complete:(void (^)(BOOL result,NSArray<Coin *> *coinList))complete;

/**
 *  set currency messageInfo
 *
 */
+ (void)setCurrencyStatus:(int)status currency:(int)currency complete:(void (^)(BOOL result))complte;

/**
 *  add currency address
 *
 */
+ (void)addCurrencyAddressWithCurrency:(int)currency label:(NSString *)label index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete;

/**
 *  get currency addresss list
 *
 */
+ (void)getCurrencyAddressListWithCurrency:(int)currency complete:(void (^)(BOOL result,NSMutableArray<CoinInfo *> *addressList)) complte;

/**
 * set currency address message
 *
 */
+ (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete;




@end
