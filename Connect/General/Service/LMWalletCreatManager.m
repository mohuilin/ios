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

@implementation LMWalletCreatManager
/**
 * creat new wallet
 *
 * @param contacts
 * @param complete
 */
+ (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(int)currency complete:(void (^)(BOOL isFinish,NSString *error))complete{
    
    // Synchronize wallet data and create wallet
    [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO,@"同步数据失败");
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
            switch (syncWallet.status) {
                case 0:   // no wallet
                {
                    // creat new page
                    [LMWalletCreatManager creatNewWallet:controllerVc currency:currency complete:complete];
                    [LMWalletInfoManager sharedManager].categorys = 2;
                }
                    break;
                case 1:   // exist user
                {
                    // save data to db
                    LMSeedModel *getSeedModel = [[LMSeedModel allObjects] lastObject];
                    LMSeedModel *saveSeedModel = [LMSeedModel new];
                    if (getSeedModel.encryptSeed.length <= 0) {
                       saveSeedModel.encryptSeed = syncWallet.wallet.payLoad;
                    }
                    saveSeedModel.salt = syncWallet.wallet.salt;
                    saveSeedModel.n = syncWallet.wallet.pbkdf2Iterations;
                    saveSeedModel.status = syncWallet.status;
                    saveSeedModel.version = syncWallet.wallet.version;
                    [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                        [realm addOrUpdateObject:saveSeedModel];
                    }];
                    if (syncWallet.coinsArray_Count > 0) {
                        for (Coin *coinInfo in syncWallet.coinsArray) {
                            LMCurrencyModel *getCurencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d"],coinInfo.currency] lastObject];
                            LMCurrencyModel *currenncyMoedl = [LMCurrencyModel new];
                            if (!getCurencyModel) {
                               currenncyMoedl.currency = coinInfo.currency;
                            }
                            currenncyMoedl.category = coinInfo.category;
                            currenncyMoedl.salt = coinInfo.salt;
                            currenncyMoedl.status = coinInfo.status;
                            currenncyMoedl.blance = coinInfo.balance;
                            currenncyMoedl.payload = coinInfo.payload;
                            [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                                [realm addOrUpdateObject:currenncyMoedl];
                            }];
                        }
                    }
                }
                    break;
                case 3:   // old user
                {
                    // save data to db
                    LMSeedModel *getSeedModel = [[LMSeedModel allObjects] lastObject];
                    LMSeedModel *saveSeedModel = [LMSeedModel new];
                    if (getSeedModel.encryptSeed.length <= 0) {
                        saveSeedModel.encryptSeed = syncWallet.wallet.payLoad;
                    }
                    saveSeedModel.salt = syncWallet.wallet.salt;
                    saveSeedModel.n = syncWallet.wallet.pbkdf2Iterations;
                    saveSeedModel.status = syncWallet.status;
                    saveSeedModel.version = syncWallet.wallet.version;
                    [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                        [realm addOrUpdateObject:saveSeedModel];
                    }];
                    if (syncWallet.coinsArray_Count > 0) {
                        for (Coin *coinInfo in syncWallet.coinsArray) {
                            LMCurrencyModel *getCurencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d"],coinInfo.currency] lastObject];
                            LMCurrencyModel *currenncyMoedl = [LMCurrencyModel new];
                            if (!getCurencyModel) {
                                currenncyMoedl.currency = coinInfo.currency;
                            }
                            currenncyMoedl.category = coinInfo.category;
                            currenncyMoedl.salt = coinInfo.salt;
                            currenncyMoedl.status = coinInfo.status;
                            currenncyMoedl.blance = coinInfo.balance;
                            currenncyMoedl.payload = coinInfo.payload;
                            [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                                [realm addOrUpdateObject:currenncyMoedl];
                            }];
                        }
                    }
                    // creat old page
                    [LMWalletCreatManager creatOldWallet:controllerVc complete:complete];
                    [LMWalletInfoManager sharedManager].categorys = 1;
                }
                    break;
                    
                default:
                    break;
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,@"同步数据失败");
        }
    }];
}
/**
 * creat import wallet
 *
 */
+ (void)creatImportWallet:(NSString *)currency complete:(void (^)(BOOL isFinish,NSString *error))complete{
    
  [LMCurrencyManager createCurrency:0 salt:nil category:0 masterAddess:nil complete:^(BOOL result) {
      if (result) {
          if (complete) {
              complete(YES,nil);
          }
      }else{
          if (complete) {
              complete(NO,nil);
          }
          
      }
      
  }];

}
/**
 *
 * create old wallet
 */
+ (void)creatOldWallet:(UIViewController *)controllerVc complete:(void (^)(BOOL isFinish,NSString * error))complete{
    NSString __block *firstPass = nil;
    [GCDQueue executeInMainQueue:^{
        KQXPasswordInputController *passView = [[KQXPasswordInputController alloc] initWithPasswordInputStyle:KQXPasswordInputStyleWithoutMoney];
        __weak __typeof(&*passView) weakPassView = passView;
        passView.fillCompleteBlock = ^(NSString *password) {
            if (GJCFStringIsNull(firstPass)) {
                firstPass = password;
                [weakPassView setTitleString:LMLocalizedString(@"Wallet Confirm PIN", nil) descriptionString:LMLocalizedString(@"Wallet Enter 4 Digits", nil) moneyString:nil];
            } else {
                [weakPassView dismissWithClosed:YES];
                if ([firstPass isEqualToString:password]) {
                    [SetGlobalHandler setpayPass:password compete:^(BOOL result) {
                        if (result) {
                            NSData *saltData = [LMIMHelper createRandom512bits];
                            NSString *salt = [[NSString alloc] initWithData:saltData encoding:NSUTF8StringEncoding];
                            NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
                            NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:[LMWalletInfoManager sharedManager].encryPtionSeed];
                            NSString *bSeedPrikey = [LMBTCWalletHelper getPrivkeyBySeed:BitSeed index:0];
                            NSString *masterAddress = [LMBTCWalletHelper getAddressByPrivKey:bSeedPrikey];
                            int category = [LMWalletInfoManager sharedManager].categorys;
                            [LMCurrencyManager createCurrency:CurrencyTypeBTC salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
                                if (result) {
                                    // tips
                                    if (complete) {
                                        complete(YES,nil);
                                    }
                                }else{
                                    // tips
                                    if (complete) {
                                        complete(NO,@"创建币种失败");
                                    }
                                }
                            }];
                        }else {
                            if (complete) {
                                complete(NO,@"创建币种失败");
                            }
                        }
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:controllerVc.view complete:^{
                            if (complete) {
                                complete(NO,LMLocalizedString(@"Login Password incorrect", nil));
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
+ (void)creatNewWallet:(UIViewController *)controllerVc currency:(int)currency complete:(void (^)(BOOL isFinish,NSString *error))complete{
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
                                    int category = [LMWalletInfoManager sharedManager].categorys;
                                    NSString *masterAddress = [LMBTCWalletHelper getAddressByPrivKey:bSeedPrikey];
                                    [LMCurrencyManager createCurrency:0 salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
                                        if (result) {
                                            // tips
                                            if (complete) {
                                                complete(YES,nil);
                                            }
                                        }else{
                                            // tips
                                            if (complete) {
                                                complete(NO,@"创建币种失败");
                                            }
                                        }
                                    }];
                                }else {
                                    if (complete) {
                                        complete(NO,@"创建币种失败");
                                    }
                                }
                            }];
                        } else {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:controllerVc.view complete:^{
                                    if (complete) {
                                        complete(NO,LMLocalizedString(@"Login Password incorrect", nil));
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
                complete(NO,@"没有生成随机种子");
            }
        }
    };
    [controllerVc.navigationController pushViewController:seedVc animated:YES];
}

@end
