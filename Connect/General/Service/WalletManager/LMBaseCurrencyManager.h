//
//  LMBaseCurrencyManager.h
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMSeedModel.h"
#import "LMCurrencyAddress.h"
#import "Wallet.pbobjc.h"
#import "LMCurrencyModel.h"

@interface LMBaseCurrencyManager : NSObject
#pragma mark - currency creat and get

/**
 *  creat currency
 *
 */
- (void)createCurrency:(CurrencyType)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess payLoad:(NSString *)payLoad complete:(void (^)(LMCurrencyModel *currencyModel,NSError *error))complete;

/**
 *  set currency messageInfo
 *
 */
- (void)updateOldUserEncryptPrivatekey:(NSString *)decodePrivkey complete:(void (^)(NSError *error))complete;
/**
 * decode encrypt value by password
 * @param encryptValue
 * @param password
 */
- (NSArray *)getCurrencyAddressList:(CurrencyType)currency;


- (void)syncCurrencyDetailWithComplete:(void (^)(LMCurrencyModel *currencyModel,NSError *error))complete;

#pragma mark - encryption methods
/**
 * address by privkey
 * @param prvkey
 * @return
 */
- (NSString *)getAddressByPrivKey:(NSString *)prvkey;

+ (BOOL)checkAddress:(NSString *)address;

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

- (NSString *)signRawTranscationWithTvs:(NSString *)tvs category:(CategoryType)category rawTranscation:(NSString *)rawTranscation inputs:(NSArray *)inputs seed:(NSString *)seed;

#pragma mark - water method
- (void)getWaterTransactions:(CurrencyType)currency address:(NSString *)address page:(int)page size:(int)size complete:(void (^)(Transactions *transactions,NSError *error))complete;


@end
