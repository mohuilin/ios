//
//  LMTransferManager.m
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTransferManager.h"

@implementation LMTransferManager

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(void (^)(NSString *vts,NSString *rawTransaction ,NSError *error))complete{
    
}

- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(CompleteBlock)complete{
    
}

- (void)transactionFlowingComplete:(CompleteWithDataBlock)complete{
    
}

@end
