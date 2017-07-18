//
//  EnumDefine.h
//  Connect
//
//  Created by MoHuilin on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#ifndef EnumDefine_h
#define EnumDefine_h

typedef NS_ENUM(NSInteger ,LuckypackageTypeCategory) {
    LuckypackageTypeCategoryGroup = 0,
    LuckypackageTypeCategoryOuterUrl,
};

typedef NS_ENUM(NSInteger ,TransactionType) {
    TransactionTypePayReceipt = 1,
    TransactionTypePayCrowding = 2,
    TransactionTypeLuckypackage = 3,
    TransactionTypeURLTransfer = 6,
    TransactionTypeSystemLuckypackage = 7,
};

typedef NS_ENUM(NSInteger ,CurrencyType) {
    CurrencyTypeBTC = 0,
    CurrencyTypeLTC,
    CurrencyTypeETH,
};

#endif /* EnumDefine_h */
