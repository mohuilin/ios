//
//  LMTransferManager.h
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger ,LuckypackageType) {
    LuckypackageTypeInner = 1,
    LuckypackageTypeOuter = 2
};

typedef NS_ENUM(NSInteger ,LuckypackageAmountType) {
    LuckypackageAmountTypeRandom = 0,
    LuckypackageAmountTypeSame
};

typedef void (^CompleteBlock)(NSError *error);

typedef void (^CompleteWithDataBlock)(id data,NSError *error);

@interface LMTransferManager : NSObject

/**
 * transfer from addresses
 * @param addresses
 * @param fee
 * @param toAddresses
 * @param perAddressAmount
 * @param complete
 */
- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(void (^)(NSString *vts,NSString *rawTransaction ,NSError *error))complete;

/**
 * transfer from indexes
 * @param indexes
 * @param fee
 * @param toAddresses
 * @param perAddressAmount
 * @param complete
 */
- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(CompleteBlock)complete;

/**
 * transaction history
 * @param complete
 */
- (void)transactionFlowingComplete:(CompleteWithDataBlock)complete;

@end
