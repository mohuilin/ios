//
//  LMBTCTransferManager.h
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTransferManager.h"

@interface LMBTCTransferManager : LMTransferManager

/**
 * send luckypackage
 * @param total
 * @param amount
 * @param fee
 * @param amountType
 * @param luckyPackageType
 * @param tips
 * @param indexes
 * @param complete
 */
- (void)sendLuckyPackageWithTotal:(int)total amount:(NSInteger)amount fee:(NSInteger)fee amountType:(LuckypackageAmountType)amountType luckyPackageType:(LuckypackageType)luckyPackageType tips:(NSString *)tips indexes:(NSArray *)indexes complete:(CompleteBlock)complete;

/**
 * send outer transfer
 * @param amount
 * @param fee
 * @param indexes
 * @param complete
 */
- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteBlock)complete;

/**
 * send crowdfuning
 * @param amount
 * @param total
 * @param tips
 * @param complete
 */
- (void)sendCrowdfuningAmount:(NSInteger)amount total:(int)total tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete;

/**
 * pay crowdfuning
 * @param txId
 * @param indexes
 * @param complete
 */
- (void)payCrowdfuningWithTxId:(NSString *)txId indexes:(NSArray *)indexes complete:(CompleteBlock)complete;

/**
 * transger from addresses to addresses
 * @param addresses
 * @param fee
 * @param toAddresses
 * @param perAddressAmount
 * @param tips
 * @param complete
 */
- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(NSString *,NSString * ,NSError *))complete;

@end
