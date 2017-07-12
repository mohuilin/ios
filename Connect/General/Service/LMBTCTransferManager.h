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

- (void)sendLuckyPackageWithTotal:(int)total amount:(NSInteger)amount fee:(NSInteger)fee amountType:(LuckypackageAmountType)amountType luckyPackageType:(LuckypackageType)luckyPackageType indexes:(NSArray *)indexes complete:(CompleteBlock)complete;

- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteBlock)complete;

- (void)sendCrowdfuningAmount:(NSInteger)amount total:(int)total complete:(void (^)(NSString *txId,NSError *error))complete;

- (void)payCrowdfuningWithTxId:(NSString *)txId indexes:(NSArray *)indexes complete:(CompleteBlock)complete;

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(void (^)(NSArray *,NSString * ,NSError *))complete;

@end
