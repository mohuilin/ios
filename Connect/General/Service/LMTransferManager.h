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

@interface LMTransferManager : NSObject

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(void (^)(NSArray *vtsArray,NSString *rawTransaction ,NSError *error))complete;

- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(CompleteBlock)complete;

@end
