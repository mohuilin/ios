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
#import "LMBaseCurrencyManager.h"
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
                complete(NO,LMLocalizedString(@"Wallet synchronization data failed", nil));
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
                if (syncWallet.coinsArray.count > 0) {
                    [self creatWallet:controllerVc currency:currency complete:complete];
                    
                    // save data to db
                    [self syncDataToDB:syncWallet];
                }else {
//                   [self creatWallet:controllerVc currency:currency complete:complete];
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,LMLocalizedString(@"Wallet synchronization data failed", nil));
        }
        // get currency list
        [LMCurrencyManager getCurrencyListWithWalletId:nil complete:^(BOOL result, NSArray<Coin *> *coinList) {
            if (coinList.count > 0) {
                RLMResults<LMCurrencyModel *> *currencyArray = [LMCurrencyModel allObjects];
                for (Coin *coin in coinList) {
                    BOOL flag = YES;
                    if (currencyArray.count > 0) {
                        for (LMCurrencyModel *currencyModel in currencyArray) {
                            if (coin.currency == currencyModel.currency) {
                                flag = NO;
                            }
                        }
                        if (flag) {
                            LMCurrencyModel *currencyM = [LMCurrencyModel new];
                            currencyM.currency = coin.currency;
                            currencyM.category = coin.category;
                            currencyM.status = coin.status;
                            currencyM.blance = coin.balance;
                            currencyM.payload = coin.payload;
                            [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                                [realm addOrUpdateObject:currencyM];
                            }];
                        }
                    }else {
                        LMCurrencyModel *currencyM = [LMCurrencyModel new];
                        currencyM.currency = coin.currency;
                        currencyM.category = coin.category;
                        currencyM.status = coin.status;
                        currencyM.blance = coin.balance;
                        currencyM.payload = coin.payload;
                        [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                            [realm addOrUpdateObject:currencyM];
                        }];
                    }
                }
            }
        }];
        
    }];
}
/**
 *
 * creatWallet
 */
+ (void)creatWallet:(UIViewController *)controllerVc currency:(int)currency complete:(void (^)(BOOL isFinish,NSString *error))complete{
    
    RequestUserInfo *userInfo = [RequestUserInfo new];
    userInfo.uid = [LKUserCenter shareCenter].currentLoginUser.pub_key;
    userInfo.currency = currency;
    
    [NetWorkOperationTool POSTWithUrlString:GetUserStatus postProtoData:userInfo.data complete:^(id response) {
        HttpResponse *hRespon = (HttpResponse*)response;
        if (hRespon.code != successCode) {
            if (complete) {
                complete(NO,nil);
            }
        }else{
            NSData *data = [ConnectTool decodeHttpResponse:hRespon];
            if (data) {
                CoinsDetail *coinDetail = [CoinsDetail parseFromData:data error:nil];
                switch (coinDetail.coin.category) {
                    case CategoryTypeNewUser:
                    {
                        [LMWalletInfoManager sharedManager].categorys = CategoryTypeNewUser;
                        [LMWalletCreatManager creatNewWallet:controllerVc currency:currency complete:complete];
                        
                    }
                        break;
                    case CategoryTypeOldUser:
                    {
                        // creat old page
                        [LMWalletInfoManager sharedManager].categorys = CategoryTypeOldUser;
                        [LMWalletCreatManager creatOldWallet:controllerVc complete:complete];
                        
                    }
                        break;
                    case CategoryTypeImportUser:
                    {
                        // creat import wallet
                        [self creatImportWallet:0 complete:^(BOOL isFinish, NSString *error) {
                            
                        }];
                    }
                        break;
                        
                    default:
                    {
                        [LMWalletInfoManager sharedManager].categorys = CategoryTypeNewUser;
                        [LMWalletCreatManager creatNewWallet:controllerVc currency:currency complete:complete];
                        
                    }
                        break;
                }
                if (complete) {
                    complete(YES,nil);
                }
            }
        }
        
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,nil);
        }
    }];
}
/**
 *
 * sync datat to db
 */
+ (void)syncDataToDB:(RespSyncWallet *)syncWallet {
    // save data to db
    LMSeedModel *saveSeedModel = [LMSeedModel new];
    if (syncWallet.wallet.payLoad.length > 0) {
        saveSeedModel.encryptSeed = syncWallet.wallet.payLoad;
    }
    saveSeedModel.version = syncWallet.wallet.version;
    [LMCurrencyManager saveModelToDB:saveSeedModel];
    
    for (Coin *coinInfo in syncWallet.coinsArray) {
        LMCurrencyModel *getCurencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d"],coinInfo.currency] lastObject];
        LMCurrencyModel *currenncyMoedl = [LMCurrencyModel new];
        if (!getCurencyModel) {
            currenncyMoedl.currency = coinInfo.currency;
        }
        currenncyMoedl.category = coinInfo.category;
        currenncyMoedl.status = coinInfo.status;
        currenncyMoedl.blance = coinInfo.balance;
        currenncyMoedl.payload = coinInfo.payload;
        [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm addOrUpdateObject:currenncyMoedl];
        }];
    }
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
    [LMWalletInfoManager sharedManager].baseSeed = [LKUserCenter shareCenter].currentLoginUser.prikey;
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
                            NSString *bSeedPrikey = [LMBaseCurrencyManager getPrivkeyBySeed:BitSeed index:0];
                            NSString *masterAddress = [LMBaseCurrencyManager getAddressByPrivKey:bSeedPrikey];
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
                                        complete(NO,LMLocalizedString(@"Wallet create currency failed", nil));
                                    }
                                }
                            }];
                        }else {
                            if (complete) {
                                complete(NO,LMLocalizedString(@"Wallet create currency failed", nil));
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
                        if ([firstPass isEqualToString:password]) {
                            [weakPassView dismissWithClosed:YES];
                            [SetGlobalHandler setpayPass:password compete:^(BOOL result) {
                                if (result) {
                                    [LMWalletInfoManager sharedManager].baseSeed = randomSeed;
                                    NSData *saltData = [LMIMHelper createRandom512bits];
                                    NSString *salt = [[NSString alloc] initWithData:saltData encoding:NSUTF8StringEncoding];
                                    NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
                                    NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:[LMWalletInfoManager sharedManager].encryPtionSeed];
                                    NSString *bSeedPrikey = [LMBaseCurrencyManager getPrivkeyBySeed:BitSeed index:0];
                                    int category = [LMWalletInfoManager sharedManager].categorys;
                                    NSString *masterAddress = [LMBaseCurrencyManager getAddressByPrivKey:bSeedPrikey];
                                    [LMCurrencyManager createCurrency:0 salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
                                        if (result) {
                                            // tips
                                            if (complete) {
                                                complete(YES,nil);
                                            }
                                        }else{
                                            // tips
                                            if (complete) {
                                                complete(NO,LMLocalizedString(@"Wallet create currency failed", nil));
                                            }
                                        }
                                    }];
                                }else {
                                    if (complete) {
                                        complete(NO,LMLocalizedString(@"Wallet Create wallet failed", nil));
                                    }
                                }
                            }];
                        } else {
                            if (complete) {
                                complete(NO,LMLocalizedString(@"Login Password incorrect", nil));
                            }
                        }
                    }
                };
                [controllerVc presentViewController:passView animated:NO completion:nil];
            }];
            
        }else {
            if (complete) {
                complete(NO,LMLocalizedString(@"Login Generated Failure", nil));
            }
        }
    };
    [controllerVc.navigationController pushViewController:seedVc animated:YES];
}

@end
