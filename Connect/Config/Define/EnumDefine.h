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
typedef NS_ENUM(NSUInteger,ToastErrorType)
{
    ToastErrorTypeLoginOrReg      = 1 << 1,
    ToastErrorTypeContact         = 1 << 2,
    ToastErrorTypeWallet          = 1 << 3,
    ToastErrorTypeSet             = 1 << 4,
};
typedef NS_ENUM(NSInteger,ErrorCodeType)
{
    TransactionPackageErrorSuccess = 0,
    CREAR_CURRENCY_FAILED_131      = 131,
    CREAR_WALLET_FAILED_132        = 132,
    SYNC_DATA_FAILED_133           = 133,
    GET_ADDRESSLIST_FAILED_134     = 134,
    CURRENCY_ISEXIST_135           = 135,
    PASSWPRD_ERROR_136             = 136,
    NETWORK_FAILED_400             = 400,
    SOURCE_FAILED_404              = 404,
    ErrorCodeType1001    =  -1001,
    ErrorCodeType2001    =  2001,
    ErrorCodeType2002    =  2002,
    ErrorCodeType2003    =  2003,
    ErrorCodeType2010    =  2010,
    ErrorCodeType2011    =  2011,
    ErrorCodeType2012    =  2012,
    ErrorCodeType2013    =  2013,
    ErrorCodeType2014    =  2014,
    ErrorCodeType2015    =  2015,
    ErrorCodeType2016    =  2016,
    ErrorCodeType2100    =  2100,
    ErrorCodeType2101    =  2101,
    ErrorCodeType2102    =  2102,
    ErrorCodeType2400    =  2400,
    ErrorCodeType2401    =  2401,
    ErrorCodeType2402    =  2402,
    ErrorCodeType2403    =  2403,
    ErrorCodeType2404    =  2404,
    ErrorCodeType2405    =  2405,
    ErrorCodeType2406    =  2406,
    ErrorCodeType2410    =  2410,
    ErrorCodeType2411    =  2411,
    ErrorCodeType2412    =  2412,
    ErrorCodeType2413    =  2413,
    ErrorCodeType2414    =  2414,
    ErrorCodeType2415    =  2415,
    ErrorCodeType2420    =  2420,
    ErrorCodeType2500    =  2500,
    ErrorCodeType2501    =  2501,
    ErrorCodeType2502    =  2502,
    ErrorCodeType2460    =  2460,
    ErrorCodeType2461    =  2461,
    ErrorCodeType2462    =  2462,
    ErrorCodeType2616    =  2616,
    ErrorCodeType2617    =  2617,
    ErrorCodeType2618    =  2618,
    ErrorCodeType2664    =  2664,
    ErrorCodeType2665    =  2665,
    ErrorCodeType2666    =  2666,
    TransactionPackageErrorTypeFeeSamll         = 3000,
    TransactionPackageErrorTypeFeeEmpty         = 3001,
    TransactionPackageErrorTypeUnspentTooLarge  = 3002,
    TransactionPackageErrorTypeUnspentError     = 3003,
    TransactionPackageErrorTypeUnspentNotEnough = 3004,
    TransactionPackageErrorTypeOutDust          = 3005,
    TransactionPackageErrorTypeChangeDust       = 3006,
    TransactionPackageErrorTypeFeeToolarge      = 3007,
    TransactionPackageErrorTypeCancel           = 9001,
    TransactionPackageErrorTypeSyncAddress_InputsAddress_NotMatch = 9003
};
typedef NS_ENUM(NSUInteger,CategoryType) {
    CategoryTypeOldUser = 1,
    CategoryTypeNewUser = 2,
    CategoryTypeImport  = 3
};
#endif /* EnumDefine_h */
