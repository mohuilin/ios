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
    TransactionTypeLuckypackage = 0,
    TransactionTypeURLLuckypackage,
    TransactionTypeSigleTransfer,
    TransactionTypeMutiAddressTransfer,
    TransactionTypeURLTransfer,
    TransactionTypePayReceipt,
    TransactionTypePayCrowding
};

typedef NS_ENUM(NSInteger ,CurrencyType) {
    CurrencyTypeBTC = 0,
    CurrencyTypeLTC,
    CurrencyTypeETH,
};

#endif /* EnumDefine_h */
