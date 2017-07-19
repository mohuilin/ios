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
+ (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(int)currency complete:(void (^)(BOOL isFinish,NSString *error))complete;

/**
 *
 * sync datat to db
 */
+ (void)syncWalletData:(RespSyncWallet *)syncWallet;
/**
 *
 * get data from server
 */
+ (void)getWalletData:(void(^)(BOOL result))complete;

/**
 * set password method
 *
 */
+ (void)setPassWord:(NSString *)passWord complete:(void(^)(BOOL result))complete;
/**
 *  reset password methods
 *
 */
+ (void)reSetPassWord:(NSString *)passWord baseSeed:(NSString *)baseSeed complete:(void(^)(BOOL result))complete;
@end
