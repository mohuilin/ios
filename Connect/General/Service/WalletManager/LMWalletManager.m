//
//  LMWalletManager.m
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletManager.h"
#import "UserDBManager.h"
#import "NetWorkOperationTool.h"
#import "LMRandomSeedController.h"
#import "LMBtcCurrencyManager.h"
#import "LMRealmManager.h"
#import "StringTool.h"
#import "LMIMHelper.h"
#import "Wallet.pbobjc.h"
#import "UIViewController+CurrencyVC.h"

@implementation LMWalletManager
CREATE_SHARED_MANAGER(LMWalletManager);


- (LMSeedModel *)baseModel{
    LMSeedModel *seedModel = [[LMSeedModel allObjects] firstObject];
    
    return seedModel;
}

- (LMCurrencyModel *)currencyModelWith:(CurrencyType)currency{
    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d",(int)CurrencyTypeBTC]] lastObject];
    return currencyModel;
}

#pragma mark - methods
/**
 * creat new wallet
 *
 * @param contacts
 * @param complete
 */
- (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(RespSyncWallet *wallet,NSError *error))complete{
    
    /// error type : wallet exist , create failed and other error
    [self getWalletData:^(RespSyncWallet *wallet, NSError *error) {
        switch (error.code) {
            case WALLET_NOT_ISEXIST:
            {
                [self creatWallet:controllerVc currency:currency complete:^(NSError *error) {
                    if (complete) {
                        complete(nil,error);
                    }
                }];
            }
                break;
            case WALLET_ISEXIST:{
                if (complete) {
                    complete(wallet,error);
                }
            }
            default:
                if (complete) {
                    complete(nil,error);
                }
                break;
        }
    }];
}
/**
 *
 * creatWallet
 */
- (void)creatWallet:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(NSError *error))complete{
    
    RequestUserInfo *userInfo = [RequestUserInfo new];
    userInfo.uid = [LKUserCenter shareCenter].currentLoginUser.pub_key;
    userInfo.currency = currency;
    
    [NetWorkOperationTool POSTWithUrlString:GetUserStatus postProtoData:userInfo.data complete:^(id response) {
        HttpResponse *hRespon = (HttpResponse*)response;
        if (hRespon.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hRespon.message code:hRespon.code userInfo:nil]);
            }
        }else{
            NSData *data = [ConnectTool decodeHttpResponse:hRespon];
            if (data) {
                CoinsDetail *coinDetail = [CoinsDetail parseFromData:data error:nil];
                switch (coinDetail.coin.category) {
                    case CategoryTypeOldUser:
                    {
                        [self creatOldWallet:controllerVc complete:complete];
                    }
                        break;
                    case CategoryTypeNewUser:
                    {
                        [self creatNewWallet:controllerVc currency:currency complete:complete];
                    }
                        break;
                    case CategoryTypeImport:
                    {
                        // creat import wallet
                        [self creatImportWallet:0 complete:complete];
                    }
                        break;
                    default:
                        break;
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}
/**
 *
 * sync datat to db
 */
- (void)saveWallet:(RespSyncWallet *)syncWallet {
    
    NSMutableArray *addedCurrencyArray = [NSMutableArray array];
    for (Coin *coinInfo in syncWallet.coinsArray) {
        LMCurrencyModel *getCurrencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d",coinInfo.currency]] lastObject];
        if (getCurrencyModel) {
            [[LMRealmManager sharedManager] executeRealmWithBlock:^() {
                getCurrencyModel.category = coinInfo.category;
                getCurrencyModel.status = coinInfo.status;
                getCurrencyModel.blance = coinInfo.balance;
                getCurrencyModel.amount = coinInfo.amount;
                getCurrencyModel.salt = coinInfo.salt;
                getCurrencyModel.masterAddress = nil;
                getCurrencyModel.defaultAddress = nil;
                getCurrencyModel.payload = coinInfo.payload;
            }];
        }else {
            LMCurrencyModel *currenncyMoedl = [LMCurrencyModel new];
            currenncyMoedl.currency = coinInfo.currency;
            currenncyMoedl.category = coinInfo.category;
            currenncyMoedl.status = coinInfo.status;
            currenncyMoedl.blance = coinInfo.balance;
            currenncyMoedl.amount = coinInfo.amount;
            currenncyMoedl.salt = coinInfo.salt;
            currenncyMoedl.masterAddress = nil;
            currenncyMoedl.defaultAddress = nil;
            currenncyMoedl.payload = coinInfo.payload;
            [addedCurrencyArray addObject:currenncyMoedl];
        }
    }
    
    // save data to db
    LMSeedModel *getSeedModel = [[LMSeedModel allObjects] firstObject];
    [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
        /// wallet have encrypt seed
        if (syncWallet.wallet.payLoad) {
            LMSeedModel *saveSeedModel = [LMSeedModel new];
            saveSeedModel.encryptSeed = syncWallet.wallet.payLoad;
            saveSeedModel.version = syncWallet.wallet.version;
            saveSeedModel.ver = syncWallet.wallet.ver;
            if (getSeedModel) {
                [realm deleteObject:getSeedModel];
            }
            [realm addOrUpdateObject:saveSeedModel];
        }
        if (addedCurrencyArray.count) {
            [realm addObjects:addedCurrencyArray];
        }
    }];
}
/**
 *
 * get data from server
 */
- (void)getWalletData:(void(^)(RespSyncWallet *wallet,NSError *error))complete {
    
    [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
                if (syncWallet.coinsArray.count) {
                    NSString *checkStr = [NSString stringWithFormat:@"%d%@",syncWallet.wallet.ver,syncWallet.wallet.payLoad];
                    NSString *checkSum = [checkStr sha256String];
                    if (![checkSum isEqualToString:syncWallet.wallet.checkSum]) {
                        if (complete) {
                            complete(nil,[NSError errorWithDomain:@"wallet verfiy failed" code:WALLET_CHECK_SUM_FAILED userInfo:nil]);
                        }
                    }
                    /// save db
                    [self saveWallet:syncWallet];
                    if (complete) {
                        complete(syncWallet,[NSError errorWithDomain:@"wallet exist" code:WALLET_ISEXIST userInfo:nil]);
                    }
                } else {
                    if (complete) {
                        complete(nil,[NSError errorWithDomain:@"wallet create failed" code:WALLET_NOT_ISEXIST userInfo:nil]);
                    }
                }

            } else {
                if (complete) {
                    complete(nil,[NSError errorWithDomain:hResponse.message code:Create_ProbufParse_FAILED userInfo:nil]);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}
/**
 * creat import wallet
 *
 */
- (void)creatImportWallet:(CurrencyType)currency complete:(void (^)(NSError *error))complete{
    
    LMBaseCurrencyManager *baseCurrency = nil;
    switch (currency) {
        case CurrencyTypeBTC:
            baseCurrency = [[LMBtcCurrencyManager alloc] init];
            break;
            
        default:
            break;
    }
    [baseCurrency createCurrency:0 salt:nil category:CurrencyTypeBTC masterAddess:nil payLoad:nil complete:^(LMCurrencyModel *currencyModel,NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}
/**
 *
 * create old wallet
 */
- (void)creatOldWallet:(UIViewController *)controllerVc complete:(void (^)(NSError * error))complete{
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
                    LMBaseCurrencyManager *baseCurency = nil;
                    baseCurency = [[LMBtcCurrencyManager alloc] init];
                    /// privkey hex
                    NSString *priHex = [[LKUserCenter shareCenter].currentLoginUser.prikey hexString];
                    NSString *payLoad = [baseCurency encodeValue:priHex password:password n:17];
                    [baseCurency createCurrency:CurrencyTypeBTC salt:nil category:CategoryTypeOldUser masterAddess:[[LKUserCenter shareCenter] currentLoginUser].address payLoad:payLoad  complete:^(LMCurrencyModel *currencyModel,NSError *error) {
                        if (complete) {
                            complete(error);
                        }
                    }];
                } else {
                    if (complete) {
                        complete([NSError errorWithDomain:@"" code:PASSWPRD_ERROR_136 userInfo:nil]);
                    }
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
- (void)creatNewWallet:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(NSError *error))complete{
    LMRandomSeedController *seedVc = [[LMRandomSeedController alloc] init];
    seedVc.seedSourceType = SeedSouceTypeWallet;
    seedVc.title = LMLocalizedString(@"", nil);
    seedVc.SeedBlock = ^(NSString *randomSeed) {
        if (!GJCFStringIsNull(randomSeed)) {
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
                            [self encryptValue:randomSeed password:password complete:^(NSError *error) {
                                if (!error) {
                                    NSData *saltData = [LMIMHelper createRandom512bits];
                                    NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
                                    NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:randomSeed];
                                    LMBaseCurrencyManager *baseCurrency = nil;
                                    switch (currency) {
                                        case CurrencyTypeBTC:
                                            baseCurrency = [[LMBtcCurrencyManager alloc] init];
                                            break;
                                            
                                        default:
                                            break;
                                    }
                                    NSString *bSeedPrikey = [baseCurrency getPrivkeyBySeed:BitSeed index:0];
                                    NSString *masterAddress = [baseCurrency getAddressByPrivKey:bSeedPrikey];
                                    [baseCurrency createCurrency:CurrencyTypeBTC salt:commonRandomStr category:CategoryTypeNewUser masterAddess:masterAddress payLoad:nil complete:^(LMCurrencyModel *currencyModel,NSError *error) {
                                        if (complete) {
                                            complete(error);
                                        }
                                    }];
                                }else {
                                    if (complete) {
                                        complete(error);
                                    }
                                }
                            }];
                        } else {
                            if (complete) {
                                complete([NSError errorWithDomain:@"" code:PASSWPRD_ERROR_136 userInfo:nil]);
                            }
                        }
                    }
                };
                [controllerVc presentViewController:passView animated:NO completion:nil];
            }];
        }
    };
    seedVc.hidesBottomBarWhenPushed = YES;
    [controllerVc.navigationController pushViewController:seedVc animated:YES];
}
/**
 * update password
 *
 */
- (void)updatePassWord:(NSString *)payload checkSum:(NSString *)checkSum version:(int)version ver:(int)ver url:(NSString *)url compete:(void(^)(NSError *error))complete{
    
    RequestWalletInfo *creatWallet = [RequestWalletInfo new];
    creatWallet.ver = ver;
    creatWallet.payload = payload;
    creatWallet.checkSum = checkSum;
    creatWallet.version = version;
    
    [NetWorkOperationTool POSTWithUrlString:url postProtoData:creatWallet.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                if ([url isEqualToString:EncryptionBaseSeedUrl]) {
                    complete([NSError errorWithDomain:hResponse.message code:CREAR_WALLET_FAILED_132 userInfo:nil]);
                }else {
                    complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
                }
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                // save data to db
                LMSeedModel *getSeedModel = [[LMSeedModel allObjects] firstObject];
                LMSeedModel *saveSeedModel = [LMSeedModel new];
                if (payload.length > 0) {
                    saveSeedModel.encryptSeed = payload;
                }
                saveSeedModel.version = version;
                saveSeedModel.ver = ver;
                [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                    if (getSeedModel) {
                        [realm deleteObject:getSeedModel];
                    }
                    [realm addOrUpdateObject:saveSeedModel];
                }];
            }
            if (complete) {
                complete(nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            if ([url isEqualToString:EncryptionBaseSeedUrl]) {
                complete([NSError errorWithDomain:@"" code:CREAR_WALLET_FAILED_132 userInfo:nil]);
            }else {
                complete(error);
            }
        }
    }];
}
/**
 * set password method
 *
 */
- (void)encryptValue:(NSString *)value password:(NSString *)passWord complete:(void(^)(NSError *error))complete {
    if (GJCFStringIsNull(value) ||
        GJCFStringIsNull(passWord)) {
        return;
    }
    RequestWalletInfo *creatWallet = [RequestWalletInfo new];
    LMBaseCurrencyManager *baseCurrency = nil;
    baseCurrency = [[LMBtcCurrencyManager alloc] init];
    NSString *payLoad = [baseCurrency encodeValue:value password:passWord n:17];
    LMSeedModel *SeedModel = [[LMSeedModel allObjects] firstObject];
    if (SeedModel.ver >= 1) {
        creatWallet.ver = SeedModel.ver;
    }else{
        creatWallet.ver = 1;
    }
    int version = SeedModel.version;
    if (version < 1 ) {
        version = 1;
    }
    NSString *checkStr = [NSString stringWithFormat:@"%d%@",creatWallet.ver,payLoad];
    NSString *checkSum = [checkStr sha256String];
    creatWallet.payload = payLoad;
    creatWallet.checkSum = checkSum;
    creatWallet.version = version;

    [self updatePassWord:payLoad checkSum:checkSum version:version ver:creatWallet.ver url:EncryptionBaseSeedUrl compete:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}
/**
 *  reset password methods
 *
 */
- (void)reSetPassWord:(NSString *)passWord baseSeed:(NSString *)baseSeed complete:(void(^)(NSError *error))complete {
    if (passWord == nil) {
        passWord = @"";
    }
    RequestWalletInfo *creatWallet = [RequestWalletInfo new];
    int ver = 1;
    creatWallet.ver = ver;
    LMBaseCurrencyManager *baseCurrency = [[LMBtcCurrencyManager alloc] init];
    NSString *payLoad = [baseCurrency encodeValue:baseSeed password:passWord n:17];
    NSString *checkStr = [NSString stringWithFormat:@"%d%@",creatWallet.ver,payLoad];
    NSString *checkSum = [checkStr sha256String];
    creatWallet.payload = payLoad;
    creatWallet.checkSum = checkSum;
    
    [self updatePassWord:payLoad checkSum:checkSum version:1 ver:ver url:UpdateBaseSeedUrl compete:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}


- (void)checkWalletExistAndCreateWallet{
    /// check wallet
    if (![[MMAppSetting sharedSetting] walletExist]) {
        [[LMWalletManager sharedManager] getWalletData:^(RespSyncWallet *wallet, NSError *error) {
            switch (error.code) {
                case WALLET_ISEXIST:
                    [[MMAppSetting sharedSetting] setWalletExist:YES];
                    break;
                case WALLET_NOT_ISEXIST:
                {
                    UIViewController *currentController = [UIViewController currentViewController];
                    [UIAlertController showAlertInViewController:currentController withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Wallet not create wallet", nil) cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Wallet Immediately create", nil)] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
                        if (buttonIndex == 2) {
                            [self creatWallet:currentController currency:CurrencyTypeBTC complete:^(NSError *error) {
                                /// back to root cv
                                [currentController.navigationController popViewControllerAnimated:YES];
                                if (error) {
                                    [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeWallet withErrorCode:error.code withUrl:SyncWalletDataUrl] withType:ToastTypeFail showInView:currentController.view complete:nil];
                                } else {
                                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Generated Successful", nil) withType:ToastTypeSuccess showInView:currentController .view complete:nil];
                                }
                            }];
                        }
                    }];
                }
                    break;
                default:
                    break;
            }
        }];
    }
}


@end
