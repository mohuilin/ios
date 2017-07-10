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
+ (NSString *)signRawTranscationWithTvsArray:(NSArray *)tvsArray privkeys:(NSArray *)privkeys rawTranscation:(NSString *)rawTranscation;

/**
 * Create the original transaction
   *
   * @param tvsArray
   * @param
 *
 *  @return
 */
+ (NSString *)createRawTranscationWithTvsArray:(NSArray *)tvsArray outputs:(NSDictionary *)outputs;


+ (NSString *)creatPrivkeyBySeed:(NSString *)seed index:(int)index;

+ (NSString *)encodeWalletSeed:(NSString *)seed userAddress:(NSString *)address password:(NSString *)password;

+ (NSDictionary *)decodeEncryptSeed:(NSString *)encryptSeed password:(NSString *)password;


@end
