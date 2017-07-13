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
#import "LMCurrencyModel.h"
#import "LMIMHelper.h"
#import "LMBTCWalletHelper.h"
#import "Wallet.pbobjc.h"

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
    LMSeedModel *saveSeedModel = [[LMSeedModel allObjects] lastObject];
    if (!saveSeedModel) {
        // Synchronize wallet data and create wallet
        [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
            HttpResponse *hResponse = (HttpResponse *)response;
            if (hResponse.code != successCode) {
                
            } else{
                NSData *data = [ConnectTool decodeHttpResponse:hResponse];
                RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
                // save data to db
                LMSeedModel *saveSeedModel = [LMSeedModel new];
                saveSeedModel.encryptSeed = syncWallet.wallet.payLoad;
                saveSeedModel.salt = syncWallet.wallet.salt;
                saveSeedModel.n = syncWallet.wallet.pbkdf2Iterations;
                saveSeedModel.status = syncWallet.status;
                saveSeedModel.version = syncWallet.wallet.version;
                [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                    [realm addOrUpdateObject:saveSeedModel];
                }];
                if (syncWallet.coins.coinsArray_Count > 0) {
                    for (Coin *coin in syncWallet.coins.coinsArray) {
                        LMCurrencyModel *currenncyMoedl = [LMCurrencyModel new];
                        currenncyMoedl.currency = coin.currency;
                        currenncyMoedl.category = coin.category;
                        currenncyMoedl.salt = coin.salt;
                        currenncyMoedl.masterAddress = nil;
                        currenncyMoedl.status = coin.status;
                        currenncyMoedl.blance = coin.balance;
                        currenncyMoedl.payload = coin.payload;
                        currenncyMoedl.addressListArray = nil;
                        [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                            [realm addOrUpdateObject:currenncyMoedl];
                        }];
                    }
                }
                [LMWalletInfoManager sharedManager].categorys = syncWallet.status;
                switch ([LMWalletInfoManager sharedManager].categorys) {
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
            if (complete) {
                complete(NO);
            }
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
+ (void)creatOldWallet:(UIViewController *)controllerVc  complete:(void (^)(BOOL isFinish))complete{
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
                            NSString *salt = [[NSString alloc] initWithData:[LMIMHelper createRandom512bits] encoding:NSUTF8StringEncoding];
                            int category = 1;
                            NSString *masterAddress = [LMBTCWalletHelper getAddressByPrivKey:[LKUserCenter shareCenter].currentLoginUser.prikey];
                            [LMCurrencyManager createCurrency:@"bitcoin" salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
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
            [LMWalletInfoManager sharedManager].baseSeed = randomSeed;
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
                                    [LMWalletInfoManager sharedManager].baseSeed = randomSeed;
                                    NSData *saltData = [LMIMHelper createRandom512bits];
                                    NSString *salt = [[NSString alloc] initWithData:saltData encoding:NSUTF8StringEncoding];
                                    NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
                                    NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:[LMWalletInfoManager sharedManager].encryPtionSeed];
                                    NSString *bSeedPrikey = [LMBTCWalletHelper getPrivkeyBySeed:BitSeed index:0];
                                    int category = 1;
                                    NSString *masterAddress = [LMBTCWalletHelper getAddressByPrivKey:bSeedPrikey];
                                    [LMCurrencyManager createCurrency:0 salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
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
