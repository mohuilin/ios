//
//  LMWalletManager.m
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletManager.h"
#import "UserDBManager.h"
#import "LMSeedModel.h"
#import "NetWorkOperationTool.h"
#import "LMRandomSeedController.h"
#import "LMBtcCurrencyManager.h"
#import "LMRealmManager.h"
#import "StringTool.h"
#import "LMCurrencyModel.h"
#import "LMIMHelper.h"
#import "LMBtcCurrencyManager.h"
#import "Wallet.pbobjc.h"

@implementation LMWalletManager
CREATE_SHARED_MANAGER(LMWalletManager);
- (NSString *)encryPtionSeed{
    [LMSeedModel setDefaultRealm];
    LMSeedModel *seedModel = [[LMSeedModel allObjects] firstObject];
    return seedModel.encryptSeed;
}
- (BOOL)isHaveWallet{
    [LMSeedModel setDefaultRealm];
    LMSeedModel *seedModel = [[LMSeedModel allObjects] firstObject];
    if (seedModel.encryptSeed > 0) {
        return YES;
    }
    return NO;
}

#pragma mark - methods
/**
 * creat new wallet
 *
 * @param contacts
 * @param complete
 */
+ (void)creatNewWalletWithController:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(BOOL isFinish,NSError *error))complete{
    
    // Synchronize wallet data and create wallet
    [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
                if (syncWallet.coinsArray.count > 0) {                    
                    // save data to db
                    [self syncWalletData:syncWallet];
                }else {
                    [self creatWallet:controllerVc currency:currency complete:complete];
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,error);
        }
    }];
}
/**
 *
 * creatWallet
 */
+ (void)creatWallet:(UIViewController *)controllerVc currency:(CurrencyType)currency complete:(void (^)(BOOL isFinish,NSError *error))complete{
    
    RequestUserInfo *userInfo = [RequestUserInfo new];
    userInfo.uid = [LKUserCenter shareCenter].currentLoginUser.pub_key;
    userInfo.currency = currency;
    
    [NetWorkOperationTool POSTWithUrlString:GetUserStatus postProtoData:userInfo.data complete:^(id response) {
        HttpResponse *hRespon = (HttpResponse*)response;
        if (hRespon.code != successCode) {
            if (complete) {
                complete(NO,[NSError errorWithDomain:hRespon.message code:hRespon.code userInfo:nil]);
            }
        }else{
            NSData *data = [ConnectTool decodeHttpResponse:hRespon];
            if (data) {
                CoinsDetail *coinDetail = [CoinsDetail parseFromData:data error:nil];
                switch (coinDetail.coin.category) {
                    case CategoryTypeOldUser:
                    {
                        [LMWalletManager creatOldWallet:controllerVc complete:complete];
                    }
                        break;
                    case CategoryTypeNewUser:
                    {
                        [LMWalletManager creatNewWallet:controllerVc currency:currency complete:complete];
                    }
                        break;
                    case CategoryTypeImport:
                    {
                        // creat import wallet
                        [self creatImportWallet:0 complete:^(BOOL isFinish, NSError *error) {
                            
                        }];
                    }
                        break;
                    default:
                        break;
                }
                if (complete) {
                    complete(YES,nil);
                }
            }
        }
        
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,error);
        }
    }];
}
/**
 *
 * sync datat to db
 */
+ (void)syncWalletData:(RespSyncWallet *)syncWallet {
    //check
    NSString *checkStr = [NSString stringWithFormat:@"%d%@",syncWallet.wallet.ver,syncWallet.wallet.payLoad];
    NSString *checkSum = [checkStr sha256String];
    if (![checkSum isEqualToString:syncWallet.wallet.checkSum]) {
        return;
    }
    // save data to db
    LMSeedModel *getSeedModel = [[LMSeedModel allObjects] firstObject];
    LMSeedModel *saveSeedModel = [LMSeedModel new];
    saveSeedModel.encryptSeed = syncWallet.wallet.payLoad;
    saveSeedModel.version = syncWallet.wallet.version;
    saveSeedModel.ver = syncWallet.wallet.ver;
    saveSeedModel.checkSum = syncWallet.wallet.checkSum;
    
    NSMutableArray *temArray = [NSMutableArray array];
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
            [temArray addObject:currenncyMoedl];
        }
    }
    
    [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
        if (getSeedModel) {
            [realm deleteObject:getSeedModel];
        }
        [realm addOrUpdateObject:saveSeedModel];
        [realm addObjects:temArray];
    }];
}
/**
 *
 * get data from server
 */
+ (void)getWalletData:(void(^)(BOOL result))complete {
    
    // Synchronize wallet data and create wallet
    [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO);
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
                if (syncWallet.coinsArray.count > 0) {
                    // save data to db
                    [self syncWalletData:syncWallet];
                    if (complete) {
                        complete(YES);
                    }
                }else{
                    if (complete) {
                        complete(NO);
                    }
                }
            }else {
                if (complete) {
                    complete(NO);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO);
        }
    }];
}

/**
 * creat import wallet
 *
 */
+ (void)creatImportWallet:(NSString *)currency complete:(void (^)(BOOL isFinish,NSError *error))complete{
    
    [LMBtcCurrencyManager createCurrency:0 salt:nil category:0 masterAddess:nil payLoad:nil complete:^(BOOL result,NSError *error) {
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
+ (void)creatOldWallet:(UIViewController *)controllerVc complete:(void (^)(BOOL isFinish,NSError * error))complete{
    NSString __block *firstPass = nil;
    [LMWalletManager sharedManager].baseSeed = [LKUserCenter shareCenter].currentLoginUser.prikey;
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
                    NSData *saltData = [LMIMHelper createRandom512bits];
                    NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
                    NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:[LMWalletManager sharedManager].encryPtionSeed];
                    NSString *bSeedPrikey = [LMBtcCurrencyManager getPrivkeyBySeed:BitSeed index:0];
                    NSString *masterAddress = [LMBtcCurrencyManager getAddressByPrivKey:bSeedPrikey];
                    NSString *payLoad = [LMBtcCurrencyManager encodeValue:[LKUserCenter shareCenter].currentLoginUser.prikey password:password n:17];
                    [LMBtcCurrencyManager createCurrency:CurrencyTypeBTC salt:commonRandomStr category:CategoryTypeOldUser masterAddess:masterAddress payLoad:payLoad  complete:^(BOOL result,NSError *error) {
                        if (result) {
                            // tips
                                if (complete) {
                                    complete(YES,nil);
                                }
                            }else{
                            // tips
                                if (complete) {
                                    complete(NO,error);
                                }
                        }
                    }];
                } else {
                    if (complete) {
                        complete(NO,[NSError errorWithDomain:@"" code:255 userInfo:nil]);
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
+ (void)creatNewWallet:(UIViewController *)controllerVc currency:(int)currency complete:(void (^)(BOOL isFinish,NSError *error))complete{
    LMRandomSeedController *seedVc = [[LMRandomSeedController alloc] init];
    seedVc.seedSourceType = SeedSouceTypeWallet;
    seedVc.SeedBlock = ^(NSString *randomSeed) {
        if (!GJCFStringIsNull(randomSeed)) {
            [LMWalletManager sharedManager].baseSeed = randomSeed;
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
                            [LMWalletManager setPassWord:password complete:^(BOOL result,NSError *error) {
                                if (result) {
                                    [LMWalletManager sharedManager].baseSeed = randomSeed;
                                    NSData *saltData = [LMIMHelper createRandom512bits];
                                    NSString *commonRandomStr = [StringTool hexStringFromData:saltData];
                                    NSString *BitSeed = [StringTool pinxCreator:commonRandomStr withPinv:[LMWalletManager sharedManager].encryPtionSeed];
                                    NSString *bSeedPrikey = [LMBtcCurrencyManager getPrivkeyBySeed:BitSeed index:0];
                                    NSString *masterAddress = [LMBtcCurrencyManager getAddressByPrivKey:bSeedPrikey];
                                    [LMBtcCurrencyManager createCurrency:CurrencyTypeBTC salt:commonRandomStr category:CategoryTypeNewUser masterAddess:masterAddress payLoad:nil complete:^(BOOL result,NSError *error) {
                                        if (result) {
                                            // tips
                                            if (complete) {
                                                complete(YES,nil);
                                            }
                                        }else{
                                            // tips
                                            if (complete) {
                                                complete(NO,error);
                                            }
                                        }
                                    }];
                                }else {
                                    if (complete) {
                                        complete(NO,error);
                                    }
                                }
                            }];
                        } else {
                            if (complete) {
                                complete(NO,[NSError errorWithDomain:@"" code:257 userInfo:nil]);
                            }
                        }
                    }
                };
                [controllerVc presentViewController:passView animated:NO completion:nil];
            }];
        }
    };
    [controllerVc.navigationController pushViewController:seedVc animated:YES];
}
/**
 * update password
 *
 */
+ (void)updatePassWord:(NSString *)payload checkSum:(NSString *)checkSum version:(int)version ver:(int)ver url:(NSString *)url payPass:(NSString *)payPass compete:(void(^)(BOOL result,NSError *error))complete{
    if (payPass.length <= 0) {
        return;
    }
    RequestWalletInfo *creatWallet = [RequestWalletInfo new];
    creatWallet.ver = ver;
    creatWallet.payload = payload;
    creatWallet.checkSum = checkSum;
    creatWallet.version = version;
    
    [NetWorkOperationTool POSTWithUrlString:url postProtoData:creatWallet.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
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
                saveSeedModel.checkSum = checkSum;
                [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                    if (getSeedModel) {
                        [realm deleteObject:getSeedModel];
                    }
                    [realm addOrUpdateObject:saveSeedModel];
                }];
            }
            [LMWalletManager sharedManager].encryPtionSeed = payload;
            if (complete) {
                complete(YES,nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,error);
        }
    }];
}
/**
 * set password method
 *
 */
+ (void)setPassWord:(NSString *)passWord complete:(void(^)(BOOL result,NSError *error))complete {
    if (passWord == nil) {
        passWord = @"";
        return;
    }
    NSString *needStr = [LMWalletManager sharedManager].baseSeed;
    RequestWalletInfo *creatWallet = [RequestWalletInfo new];
    NSString *payLoad = [LMBtcCurrencyManager encodeValue:needStr password:passWord n:17];
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

    [self updatePassWord:payLoad checkSum:checkSum version:version ver:creatWallet.ver url:EncryptionBaseSeedUrl payPass:passWord compete:^(BOOL result,NSError *error) {
        if (result) {
            if (complete) {
                complete(YES,nil);
            }
        }else{
            if (complete) {
                complete(NO,error);
            }
        }
    }];
}
/**
 *  reset password methods
 *
 */
+ (void)reSetPassWord:(NSString *)passWord baseSeed:(NSString *)baseSeed complete:(void(^)(BOOL result,NSError *error))complete {
    if (passWord == nil) {
        passWord = @"";
    }
    RequestWalletInfo *creatWallet = [RequestWalletInfo new];
    LMSeedModel *seedModel = [[LMSeedModel allObjects] firstObject];
    int version = 1;
    int ver = 1;
    if (seedModel) {
        version = seedModel.version;
        ver = seedModel.ver;
    }
    creatWallet.ver = ver;
    creatWallet.version = version;
    NSString *payLoad = [LMBtcCurrencyManager encodeValue:baseSeed password:passWord n:17];
    NSString *checkStr = [NSString stringWithFormat:@"%d%@",creatWallet.ver,payLoad];
    NSString *checkSum = [checkStr sha256String];
    creatWallet.payload = payLoad;
    creatWallet.checkSum = checkSum;
    
    [self updatePassWord:payLoad checkSum:checkSum version:version ver:ver url:UpdateBaseSeedUrl payPass:passWord compete:^(BOOL result,NSError *error) {
        if (result) {
            if (complete) {
                complete(YES,nil);
            }
        }else{
            if (complete) {
                complete(NO,error);
            }
        }
    }];
}

@end
