//
//  LMCurrencyManager.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMCurrencyManager : NSObject
/**
 *  creat currency
 *
 */
+ (void)createCurrency:(NSString *)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess complete:(void (^)(BOOL result))complete;

/**
 *  get currrency list
 *
 */
+ (void)getCurrencyListWithWalletId:(NSString *)walletId complete:(void (^)(BOOL result,NSArray *coinList))complete;

/**
 *  set currency messageInfo
 *
 */
+ (void)setCurrencyStatus:(int)status complete:(void (^)(BOOL result))complte;

/**
 *  add currency address
 *
 */
+ (void)addCurrencyAddressWithCurrency:(NSString *)currency lable:(NSString *)lable index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete;

/**
 *  get currency addresss list
 *
 */
+ (void)getCurrencyAddressListWithCurrency:(NSString *)currency complete:(void (^)(BOOL result,NSArray *addressList)) complte;

/**
 * set currency address message
 *
 */
+ (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete;

@end
