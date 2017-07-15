//
//  LMWalletCreatManager.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMTransferManager.h"
typedef NS_ENUM(NSUInteger,ServerStatus) {
    ServerStatusNoHaveWallet   = 0,
    ServerStatusIsExisetWallet = 1,
    ServerStatusOldUser        = 3
};
@interface LMWalletCreatManager : NSObject

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
+ (void)syncDataToDB:(RespSyncWallet *)syncWallet;
@end
