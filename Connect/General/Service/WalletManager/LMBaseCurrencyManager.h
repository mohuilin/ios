//
//  LMBaseCurrencyManager.h
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wallet.pbobjc.h"
#import "LMSeedModel.h"
#import "LMCurrencyAddress.h"

@interface LMBaseCurrencyManager : NSObject
#pragma mark - currency creat and get

/**
 *  creat currency
 *
 */
- (void)createCurrency:(CurrencyType)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess payLoad:(NSString *)payLoad complete:(void (^)(BOOL result ,NSError *error))complete;

/**
 *  get currrency list
 *
 */
- (void)getCurrencyListWithWalletId:(NSString *)walletId complete:(void (^)(BOOL result,NSArray<Coin *> *coinList))complete;

/**
 *  set currency messageInfo
 *
 */
- (void)setCurrencyStatus:(int)status currency:(CurrencyType)currency complete:(void (^)(BOOL result))complte;
/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 */
- (NSArray *)getCurrencyAddressList:(CurrencyType)currency;
#pragma mark - encryption methods
/**
 * address by privkey
 * @param prvkey
 * @return
 */
- (NSString *)getAddressByPrivKey:(NSString *)prvkey;

/**
 * get privkey from seed and index
 * @param seed
 * @param index
 * @return
 */
- (NSString *)getPrivkeyBySeed:(NSString *)seed index:(int)index;

/**
 * encode value by password  eg:privkey / seed, n default value is 17
 * @param value
 * @param password
 * @param n
 * @return
 */
- (NSString *)encodeValue:(NSString *)value password:(NSString *)password n:(int)n;

/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 * @param complete
 */
- (void)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password complete:(void (^)(NSString *decodeValue, BOOL success))complete;


/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 */
- (BOOL)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password;
#pragma mark - sign
/**
 * Signature trading
 * @param tvs
 * @param privkeys
 * @param rawTranscation
 * @return
 */

- (NSString *)signRawTranscationWithTvs:(NSString *)tvs rawTranscation:(NSString *)rawTranscation currency:(CurrencyType)currency inputs:(NSArray *)inputs seed:(NSString *)seed;
#pragma mark - water method
- (void)getWaterTransactions:(CurrencyType)currency address:(NSString *)address page:(int)page size:(int)size complete:(void (^)(BOOL result,NSArray *transactions))complete;







@end
