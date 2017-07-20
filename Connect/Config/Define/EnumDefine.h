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


typedef NS_ENUM(NSInteger ,TransactionPackageErrorType) {
    TransactionPackageErrorTypeFeeSamll = 3000,
    TransactionPackageErrorTypeFeeEmpty = 3001,
    TransactionPackageErrorTypeUnspentTooLarge = 3002,
    TransactionPackageErrorTypeUnspentError = 3003,
    TransactionPackageErrorTypeUnspentNotEnough = 3004,
    TransactionPackageErrorTypeOutDust = 3005,
    TransactionPackageErrorTypeChangeDust = 3006,
    TransactionPackageErrorTypeFeeToolarge = 3007,
    TransactionPackageErrorTypeCancel = 9001,
    TransactionPackageErrorTypeAddressSyncFail = 9002,
    TransactionPackageErrorTypeSyncAddress_InputsAddress_NotMatch = 9003,
};

typedef NS_ENUM(NSUInteger,CategoryType) {
    CategoryTypeOldUser = 1,
    CategoryTypeNewUser = 2,
    CategoryTypeImport  = 3
};
#endif /* EnumDefine_h */
