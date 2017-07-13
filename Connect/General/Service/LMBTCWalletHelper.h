//
//  LMBTCWalletHelper.h
//  Connect
//
//  Created by MoHuilin on 2017/6/15.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMBTCWalletHelper : NSObject

/**
 * Signature trading
 * @param tvs
 * @param privkeys
 * @param rawTranscation
 * @return
 */
+ (NSString *)signRawTranscationWithTvs:(NSString *)tvs privkeys:(NSArray *)privkeys rawTranscation:(NSString *)rawTranscation;

/**
 * Create the original transaction
 * @param tvsArray
 * @param
 * @return
 */
+ (NSString *)createRawTranscationWithTvsArray:(NSArray *)tvsArray outputs:(NSDictionary *)outputs;

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

@end
