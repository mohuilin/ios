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
#pragma mark - encryption methods
/**
 * address by privkey
 * @param prvkey
 * @return
 */
+ (NSString *)getAddressByPrivKey:(NSString *)prvkey;

/**
 * get privkey from seed and index
 * @param seed
 * @param index
 * @return
 */
+ (NSString *)getPrivkeyBySeed:(NSString *)seed index:(int)index;

/**
 * encode value by password  eg:privkey / seed, n default value is 17
 * @param value
 * @param password
 * @param n
 * @return
 */
+ (NSString *)encodeValue:(NSString *)value password:(NSString *)password n:(int)n;

/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 * @param complete
 */
+ (void)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password complete:(void (^)(NSString *decodeValue, BOOL success))complete;


/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 */
+ (BOOL)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password;
#pragma mark - sign
/**
 * Signature trading
 * @param tvs
 * @param privkeys
 * @param rawTranscation
 * @return
 */
+ (NSString *)signRawTranscationWithTvs:(NSString *)tvs privkeys:(NSArray *)privkeys rawTranscation:(NSString *)rawTranscation;


+ (NSString *)signRawTranscationWithTvs:(NSString *)tvs rawTranscation:(NSString *)rawTranscation currency:(CurrencyType)currency inputs:(NSArray *)inputs seed:(NSString *)seed;

/**
 * Create the original transaction
 * @param tvsArray
 * @param
 * @return
 */
+ (NSString *)createRawTranscationWithTvsArray:(NSArray *)tvsArray outputs:(NSDictionary *)outputs;



@end
