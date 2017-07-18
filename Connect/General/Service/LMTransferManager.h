//
//  LMTransferManager.h
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wallet.pbobjc.h"
#import "Protofile.pbobjc.h"

typedef NS_ENUM(NSInteger ,LuckypackageType) {
    LuckypackageTypeInner = 1,
    LuckypackageTypeOuter = 2
};

typedef NS_ENUM(NSInteger ,WalletTransferType) {
    WalletTransferTypeInnerConnect = 0,
    WalletTransferTypeOuterUrl,
};

typedef NS_ENUM(NSInteger ,ReceiptType) {
    ReceiptTypeCrowding = 0,
    ReceiptTypePeerRecipt,
};

typedef NS_ENUM(NSInteger ,CurrencyType) {
    CurrencyTypeBTC = 0,
    CurrencyTypeLTC,
    CurrencyTypeETH,
};

typedef void (^CompleteWithDataBlock)(id data,NSError *error);

@interface LMTransferManager : NSObject

+ (instancetype)sharedManager;

- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete;

- (void)sendLuckyPackageWithReciverIdentifier:(NSString *)identifier size:(int)size amount:(NSInteger)amount fee:(NSInteger)fee luckyPackageType:(LuckypackageType)luckyPackageType tips:(NSString *)tips indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete;


- (void)sendCrowdfuningToGroup:(NSString *)groupIdentifier Amount:(NSInteger)amount size:(int)size tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete;


- (void)sendReceiptToPayer:(NSString *)payer amount:(NSInteger)amount tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete;

- (void)payCrowdfuningReceiptWithHashId:(NSString *)hashId type:(ReceiptType)type indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete;

/**
 * transger from addresses to addresses
 * @param addresses
 * @param fee
 * @param toAddresses
 * @param perAddressAmount
 * @param tips
 * @param complete
 */
- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(OriginalTransaction *originalTransaction,NSError *error))complete;


- (void)transferWithFee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(OriginalTransaction *originalTransaction,NSError *error))complete;

/**
 * transfer from indexes
 * @param indexes
 * @param fee
 * @param toAddresses
 * @param perAddressAmount
 * @param complete
 */
- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete;

/**
 * transaction history
 * @param complete
 */
- (void)transactionFlowingComplete:(CompleteWithDataBlock)complete;

@end
