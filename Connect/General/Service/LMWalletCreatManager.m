//
//  LMWalletCreatManager.m
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletCreatManager.h"
#import "UserDBManager.h"
#import "LMSeedModel.h"
#import "NetWorkOperationTool.h"
#import "LMRandomSeedController.h"
#import "LMCurrencyManager.h"
#import "LMRealmManager.h"
#import "StringTool.h"

typedef NS_ENUM(NSUInteger,CurrencyType) {
    CurrencyTypePrikey   = 1,
    CurrencyTypeBaseSeed = 2,
    CurrencyTypeImport   = 3
};
@implementation LMWalletCreatManager
/**
 * creat new wallet
 *
 * @param contacts
 * @param complete
 */
+ (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(NSString *)currency complete:(void (^)(BOOL isFinish))complete{
    
    // Synchronize wallet data and create wallet
    LMSeedModel *seedModel = [[LMSeedModel allObjects] lastObject];
    if(seedModel == nil) {
        [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
            HttpResponse *hResponse = (HttpResponse *)response;
            if (hResponse.code != successCode) {
                
            } else{
                // save data to db
                LMSeedModel *saveSeedModel = [LMSeedModel new];
                saveSeedModel.encryptSeed = @"";
                saveSeedModel.salt = @"";
                saveSeedModel.n = 17;
                saveSeedModel.status = 0;
                saveSeedModel.version = 0;
                [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                    [realm addOrUpdateObject:saveSeedModel];
                }];
                [LKUserCenter shareCenter].currentLoginUser.category = 1;
                switch ([LKUserCenter shareCenter].currentLoginUser.category) {
                    case CurrencyTypePrikey:
                    {
                        // creat old page
                        [LMWalletCreatManager creatOldWallet:controllerVc complete:complete];
                    }
                        break;
                    case CurrencyTypeBaseSeed:
                    {
                        // creat new page
                        [LMWalletCreatManager creatNewWallet:controllerVc currency:currency complete:complete];
                    }
                        break;
                    case CurrencyTypeImport:
                    {
                        [LMWalletCreatManager creatImportWallet:nil complete:complete];
                    }
                        break;
                        
                    default:
                        break;
                }
            }
        } fail:^(NSError *error) {
            
        }];
    }
}
/**
 * creat import wallet
 *
 */
+ (void)creatImportWallet:(NSString *)currency complete:(void (^)(BOOL isFinish))complete{
    
  [LMCurrencyManager createCurrency:nil salt:nil category:0 masterAddess:nil complete:^(BOOL result) {
      if (result) {
          if (complete) {
              complete(YES);
          }
      }else{
          if (complete) {
              complete(NO);
          }
          
      }
      
  }];

}
/**
 *
 * create old wallet
 */
+ (void)creatOldWallet:(UIViewController *)controllerVc complete:(void (^)(BOOL isFinish))complete{
    NSString __block *firstPass = nil;
    [GCDQueue executeInMainQueue:^{
        KQXPasswordInputController *passView = [[KQXPasswordInputController alloc] initWithPasswordInputStyle:KQXPasswordInputStyleWithoutMoney];
        __weak __typeof(&*passView) weakPassView = passView;
        passView.fillCompleteBlock = ^(NSString *password) {
            if (password.length != 4) {
                return;
            }
            if (GJCFStringIsNull(firstPass)) {
                firstPass = password;
                [weakPassView setTitleString:LMLocalizedString(@"Wallet Confirm PIN", nil) descriptionString:LMLocalizedString(@"Wallet Enter 4 Digits", nil) moneyString:nil];
            } else {
                [weakPassView dismissWithClosed:YES];
                if ([firstPass isEqualToString:password]) {
                    [SetGlobalHandler setpayPass:password compete:^(BOOL result) {
                        if (result) {
                            if (result) {
                                if (complete) {
                                    complete(YES);
                                }
                            }else{
                                // tips
                                if (complete) {
                                    complete(NO);
                                }
                            }
                            
                        }else {
                            if (complete) {
                                complete(NO);
                            }
                        }
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:controllerVc.view complete:^{
                            if (complete) {
                                complete(NO);
                            }
                        }];
                    }];
                }
            }
        };
        [controllerVc presentViewController:passView animated:NO completion:nil];
    }];
}
/**
 *
 *  create new wallet
 */
+ (void)creatNewWallet:(UIViewController *)controllerVc currency:(NSString *)currency complete:(void (^)(BOOL isFinish))complete{
    LMRandomSeedController *seedVc = [[LMRandomSeedController alloc] init];
    seedVc.seedSourceType = SeedSouceTypeWallet;
    seedVc.SeedBlock = ^(NSString *randomSeed) {
        if (!GJCFStringIsNull(randomSeed)) {
            [LKUserCenter shareCenter].currentLoginUser.baseSeed = randomSeed;
            NSString __block *firstPass = nil;
            [GCDQueue executeInMainQueue:^{
                KQXPasswordInputController *passView = [[KQXPasswordInputController alloc] initWithPasswordInputStyle:KQXPasswordInputStyleWithoutMoney];
                __weak __typeof(&*passView) weakPassView = passView;
                passView.fillCompleteBlock = ^(NSString *password) {
                    if (password.length != 4) {
                        return;
                    }
                    if (GJCFStringIsNull(firstPass)) {
                        firstPass = password;
                        [weakPassView setTitleString:LMLocalizedString(@"Wallet Confirm PIN", nil) descriptionString:LMLocalizedString(@"Wallet Enter 4 Digits", nil) moneyString:nil];
                    } else {
                        [weakPassView dismissWithClosed:YES];
                        if ([firstPass isEqualToString:password]) {
                            [SetGlobalHandler setpayPass:password compete:^(BOOL result) {
                                if (result) {
                                    
                                    NSString *salt = @"";
                                    int category = 0;
                                    NSString *masterAddress = nil;
                                    [LMCurrencyManager createCurrency:currency salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
                                        if (result) {
                                            // tips
                                            if (complete) {
                                                complete(YES);
                                            }
                                        }else{
                                            // tips
                                            if (complete) {
                                                complete(NO);
                                            }
                                        }
                                    }];
                                }else {
                                    if (complete) {
                                        complete(NO);
                                    }
                                }
                            }];
                        } else {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:controllerVc.view complete:^{
                                    if (complete) {
                                        complete(NO);
                                    }
                                }];
                            }];
                        }
                    }
                };
                [controllerVc presentViewController:passView animated:NO completion:nil];
            }];
            
        }else {
            if (complete) {
                complete(NO);
            }
        }
    };
    [controllerVc.navigationController pushViewController:seedVc animated:YES];
}

@end
