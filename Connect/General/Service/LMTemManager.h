//
//  LMTemManager.h
//  Connect
//
//  Created by Connect on 2017/7/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMTemManager : NSObject
// 获取币种列表
+ (void)getCurrencyAddressList;
//  设置币种信息
+ (void)setCurrencyInfo;
// 添加币种地址
+ (void)addCurrenyAddress;
// 获取币种地址列表
+ (void)getAddressList;
// 设置币种地址信息
+ (void)setCurrencyAddressInfo;

@end
