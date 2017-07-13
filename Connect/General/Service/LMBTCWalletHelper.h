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
 Signature trading
   *
   * @param tvsArray
   * @param privkeys
   * @param rawTranscation
   *
   * @return
 */
+ (NSString *)signRawTranscationWithTvs:(NSString *)tvs privkeys:(NSArray *)privkeys rawTranscation:(NSString *)rawTranscation;

/**
 * Create the original transaction
   *
   * @param tvsArray
   * @param
 *
 *  @return
 */
+ (NSString *)createRawTranscationWithTvsArray:(NSArray *)tvsArray outputs:(NSDictionary *)outputs;

+ (NSString *)getAddressByPrivKey:(NSString *)prvkey;

+ (NSString *)getPrivkeyBySeed:(NSString *)seed index:(int)index;

+(NSString *)encodeValue:(NSString *)value password:(NSString *)password n:(int)n;

+(NSString *)decodeEncryptValue:(NSString *)encryptValue password:(NSString *)password;

@end
