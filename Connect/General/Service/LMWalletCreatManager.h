//
//  LMWalletCreatManager.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMWalletCreatManager : NSObject
/**
 * creat new wallet
 *
 * @param contacts
 * @param complete
 */
+ (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(NSString *)currency complete:(void (^)(BOOL isFinish))complete;
@end
