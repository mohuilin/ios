//
//  LMTransferManager.m
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTransferManager.h"

@implementation LMTransferManager

CREATE_SHARED_MANAGER(LMTransferManager)



- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
}

- (void)sendLuckyPackageWithReciverIdentifier:(NSString *)identifier size:(int)size amount:(NSInteger)amount fee:(NSInteger)fee luckyPackageType:(LuckypackageType)luckyPackageType tips:(NSString *)tips indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
}


- (void)sendCrowdfuningToGroup:(NSString *)groupIdentifier Amount:(NSInteger)amount size:(int)size tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete{
    
}


- (void)sendReceiptToPayer:(NSString *)payer amount:(NSInteger)amount tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete{
    
}

- (void)payCrowdfuningReceiptWithHashId:(NSString *)hashId type:(ReceiptType)type indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
}

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(OriginalTransaction *originalTransaction,NSError *error))complete{
    
}

- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete{
    
}

- (void)transferWithFee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(OriginalTransaction *originalTransaction,NSError *error))complete{
    
}

- (void)transactionFlowingComplete:(CompleteWithDataBlock)complete{
    
}

@end
