//
//  LMWalletInfoManager.h
//  Connect
//
//  Created by Connect on 2017/7/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger,CategoryType) {
    CategoryTypeOldUser    = 1,
    CategoryTypeNewUser    = 2,
    CategoryTypeImportUser = 3
};
@interface LMWalletInfoManager : NSObject
+ (instancetype)sharedManager;

/**
 *  Attributes
 *
 */
@property (nonatomic, assign) CategoryType categorys;
@property (nonatomic, copy) NSString *baseSeed;
@property (nonatomic, copy) NSString *encryPtionSeed;
@property (nonatomic, assign) BOOL isHaveWallet;




@end
