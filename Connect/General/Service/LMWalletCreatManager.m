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
    if (![LMWalletInfoManager sharedManager].isHaveWallet) {
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
                BOOL flag = YES;
                if (syncWallet.coinsArray_Count > 0) {
                    for (CoinsDetail *coinDetail in syncWallet.coinsArray) {
                        LMCurrencyModel *currenncyMoedl = [LMCurrencyModel new];
                        currenncyMoedl.currency = coinDetail.coin.currency;
                        currenncyMoedl.category = coinDetail.coin.category;
                        currenncyMoedl.salt = coinDetail.coin.salt;
                        currenncyMoedl.status = coinDetail.coin.status;
                        currenncyMoedl.blance = coinDetail.coin.balance;
                        currenncyMoedl.payload = coinDetail.coin.payload;
                        NSMutableArray *addressList = [NSMutableArray array];
                        for (CoinInfo *info in coinDetail.coinInfosArray) {
                            flag = NO;
                            if (info.index == 0) {
                                currenncyMoedl.masterAddress = info.address;
                                currenncyMoedl.defaultAddress = nil;
                            }
                            LMCurrencyAddress *addressModel = [LMCurrencyAddress new];
                            addressModel.label = info.label;
                            addressModel.address = info.address;
                            addressModel.currency = coinDetail.coin.currency;
                            addressModel.index = info.index;
                            addressModel.balance = info.balance;
                            addressModel.status = info.status;
                            [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                                [realm addOrUpdateObject:addressModel];
                            }];
                            [addressList addObject:addressModel];
                        }
                        [currenncyMoedl.addressListArray addObjects:addressList];
                        [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                            [realm addOrUpdateObject:currenncyMoedl];
                        }];
                    }
                }
                if (flag) {
                    [LMWalletInfoManager sharedManager].categorys = syncWallet.status;
                    if ([LMWalletInfoManager sharedManager].categorys == 0) {
                        [LMWalletInfoManager sharedManager].categorys = 2;
                    }
                    switch ([LMWalletInfoManager sharedManager].categorys) {
                        case CategoryTypeOldUser:
                        {
                            // creat old page
                            [LMWalletCreatManager creatOldWallet:controllerVc complete:complete];
                        }
                            break;
                        case CategoryTypeNewUser:
                        {
                            // creat new page
                            [LMWalletCreatManager creatNewWallet:controllerVc currency:currency complete:complete];
                        }
                            break;
                        case CategoryTypeImportUser:
                        {
                            [LMWalletCreatManager creatImportWallet:nil complete:complete];
                        }
                            break;
                            
                        default:
                        {
                            // creat new page
                            [LMWalletCreatManager creatNewWallet:controllerVc currency:currency complete:complete];
                        }
                            break;
                    }
                }
            }
        } fail:^(NSError *error) {
            if (complete) {
                complete(NO,@"同步数据失败");
            }
        }];
    }else {  // create bit (btc  ltc)
        [LMCurrencyModel setDefaultRealm];
        LMCurrencyModel *currencyModel = [[LMCurrencyModel allObjects] lastObject];
        if (!currencyModel) {
            NSData *saltData = [LMIMHelper createRandom512bits];
            NSString *salt = [[NSString alloc] initWithData:saltData encoding:NSUTF8StringEncoding];
            NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
            NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:[LMWalletInfoManager sharedManager].encryPtionSeed];
            NSString *bSeedPrikey = [LMBTCWalletHelper getPrivkeyBySeed:BitSeed index:0];
            NSString *masterAddress = [LMBTCWalletHelper getAddressByPrivKey:bSeedPrikey];
            int category = [LMWalletInfoManager sharedManager].categorys;
            [LMCurrencyManager createCurrency:CurrencyTypeBTC salt:salt category:category masterAddess:masterAddress complete:^(BOOL result) {
                if (result) {
                    if (complete) {
                        complete(YES,nil);
                    }
                }else{
                    if (complete) {
                        complete(NO,@"创建币种失败");
                    }
                }
            }];
        }
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
