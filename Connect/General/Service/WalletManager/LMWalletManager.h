//
//  LMWalletManager.h
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTransferManager.h"

@interface LMWalletManager : NSObject
+ (instancetype)sharedManager;

@property (nonatomic, copy) NSString *baseSeed;
@property (nonatomic, copy) NSString *encryPtionSeed;
@property (nonatomic, assign) BOOL isHaveWallet;



/**
 * creat new wallet
 *
 * @param contacts
 * @param complete
 */
- (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(NSError *error))complete;

/**
 *
 * get data from server
 */
- (void)getWalletData:(void(^)(NSError *error))complete;

/**
 * set password method
 *
 */
- (void)setPassWord:(NSString *)passWord complete:(void(^)(BOOL result,NSError *error))complete;
/**
 *  reset password methods
 *
 */
- (void)reSetPassWord:(NSString *)passWord baseSeed:(NSString *)baseSeed complete:(void(^)(BOOL result,NSError *error))complete;
@end
