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
+ (void)addCurrencyAddressWithCurrency:(int)currency label:(NSString *)label index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete;

/**
 *  get currency addresss list
 *
 */
+ (void)getCurrencyAddressListWithCurrency:(int)currency complete:(void (^)(BOOL result,NSMutableArray<CoinInfo *> *addressList)) complte;

/**
 * set currency address message
 *
 */
+ (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete;
@end
