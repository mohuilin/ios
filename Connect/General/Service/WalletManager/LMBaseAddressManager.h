//
//  LMBaseAddressManager.h
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Wallet.pbobjc.h"
#import "LMSeedModel.h"

@interface LMBaseAddressManager : NSObject
/**
 *  add currency address
 *
 */
- (void)addCurrencyAddressWithLabel:(NSString *)label index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete;

/**
 *  get currency addresss list
 *
 */
- (void)getCurrencyAddressList:(void (^)(NSMutableArray<CoinInfo *> *addressList,NSError *error))complete;

/**
 * set currency address message
 *
 */
- (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete;
/**
 *  ListWithInputInputs
 *
 */
- (void)syncAddressListWithInputInputs:(NSArray *)inputs complete:(void (^)(NSError *error))complete;
/**
 *  ListWithInputInputs
 *
 */
- (void)getAddress:(void (^)(CoinInfo *address,NSError *error))complete;

@end
