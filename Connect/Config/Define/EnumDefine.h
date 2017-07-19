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
    LuckypackageTypeCategorySingle = 0,
    LuckypackageTypeCategoryGroup,
    LuckypackageTypeCategoryOuterUrl,
};


typedef NS_ENUM(NSInteger ,TransactionType) {
    TransactionTypeBill = 1,
    TransactionTypePayCrowding = 2,
    TransactionTypeLuckypackage = 3,
    TransactionTypeURLTransfer = 6,
};

typedef NS_ENUM(NSInteger ,CurrencyType) {
    CurrencyTypeBTC = 0,
    CurrencyTypeLTC,
    CurrencyTypeETH,
};

#endif /* EnumDefine_h */
