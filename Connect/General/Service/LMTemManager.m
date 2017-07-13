//
//  LMTemManager.m
//  Connect
//
//  Created by Connect on 2017/7/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTemManager.h"
#import "LMCurrencyManager.h"
#import "LMCurrencyModel.h"
#import "StringTool.h"
@implementation LMTemManager
// 获取币种列表
+ (void)getCurrencyAddressList{
   [LMCurrencyManager getCurrencyListWithWalletId:nil complete:^(BOOL result, NSArray *coinList) {
       
   }];
}
//  设置币种信息
+ (void)setCurrencyInfo {
  [LMCurrencyManager setCurrencyStatus:0 currency:0 complete:^(BOOL result) {
      
  }];
  
}
// 添加币种地址
+ (void)addCurrenyAddress {

    LMCurrencyModel *currency = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = 0 "]] lastObject];
    NSString *salt = currency.salt;
    NSString *hexSalt = [StringTool hexStringFromData:[salt dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *bitSeed = [StringTool pinxCreator:hexSalt withPinv:[LMWalletInfoManager sharedManager].baseSeed];
    NSString *bitKey = [LMBTCWalletHelper getPrivkeyBySeed:bitSeed index:2];
    NSString *address = [LMBTCWalletHelper getAddressByPrivKey:bitKey];
  [LMCurrencyManager addCurrencyAddressWithCurrency:0 label:@"asdasdasd" index:2 address:address complete:^(BOOL result) {
      
  }];
}
// 获取币种地址列表
+ (void)getAddressList {

  [LMCurrencyManager getCurrencyAddressListWithCurrency:0 complete:^(BOOL result, NSArray *addressList) {
      
  }];
}
// 设置币种地址信息
+ (void)setCurrencyAddressInfo{
   LMCurrencyModel *curency = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = 0 "]] lastObject];
   [LMCurrencyManager setCurrencyAddressMessageWithAddress:curency.masterAddress lable:@"asdahsdhas" status:0 complete:^(BOOL result) {
     
   }];
}

@end
