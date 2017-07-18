//
//  LMCurrencyManager.m
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCurrencyManager.h"
#import "NetWorkOperationTool.h"
#import "LMCurrencyModel.h"
#import "LMRealmManager.h"
#import "Wallet.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "ConnectTool.h"
#import "LMWalletCreatManager.h"


@implementation LMCurrencyManager

#pragma mark - save data to db
/**
 *  sync model to db
 *
 */
+ (void)saveModelToDB:(LMSeedModel *)seedModel{
  
  NSString *homePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
  NSString *filePath = [homePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.data",[LKUserCenter shareCenter].currentLoginUser.address]];
  [NSKeyedArchiver archiveRootObject:seedModel toFile:filePath];

}
/**
 * get data from db
 *
 */
+ (LMSeedModel *)getModelFromDB{
   NSString *homePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
   NSString *filePath = [homePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.data",[LKUserCenter shareCenter].currentLoginUser.address]];
   LMSeedModel *seedModel = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
   return seedModel;
}
#pragma mark - Interface data

/**
 *  sync wallet data
 *
 */
+ (void)syncWalletData:(void (^)(BOOL result))complete {
    // Synchronize wallet data and create wallet
    [NetWorkOperationTool POSTWithUrlString:SyncWalletDataUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO);
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            RespSyncWallet *syncWallet = [RespSyncWallet parseFromData:data error:nil];
            [LMWalletCreatManager syncDataToDB:syncWallet];
            if (complete) {
                complete(YES);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO);
        }
    }];

}
/**
 *  creat currency
 *
 */
+ (void)createCurrency:(int)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess complete:(void (^)(BOOL result))complete {
   
    CreateCoinRequest *currencyCoin = [CreateCoinRequest new];
    currencyCoin.category = category;
    currencyCoin.masterAddress = masterAddess;
    currencyCoin.currency = currency;
    currencyCoin.salt = salt;
    currencyCoin.payload = nil;
    
    [LMCurrencyModel setDefaultRealm];
    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d"],currency] lastObject];
    if (!currencyModel) {
        // sync currency
        [LMCurrencyManager getCurrencyListWithWalletId:nil complete:^(BOOL result, NSArray<Coin *> *coinList) {
            BOOL flag = YES;
            for (Coin *coin in coinList) {
                if (coin.currency == currency) {
                    flag = NO;
                    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d "],currency] lastObject];
                    [[LMRealmManager sharedManager] executeRealmWithBlock:^{
                        currencyModel.category = category;
                        currencyModel.salt = salt;
                        currencyModel.masterAddress = masterAddess;
                        currencyModel.status = 1;
                        currencyModel.blance = coin.balance;
                        currencyModel.payload = coin.payload;
                        currencyModel.defaultAddress = masterAddess;
                    }];
                    break;
                }
            }
            if (flag) {
                [NetWorkOperationTool POSTWithUrlString:CreatCurrencyUrl postProtoData:currencyCoin.data complete:^(id response) {
                    HttpResponse *hResponse = (HttpResponse *)response;
                    if (hResponse.code != successCode) {
                        if (complete) {
                            complete(NO);
                        }
                    }else {
                        // save db
                        LMCurrencyModel *currencyModel = [LMCurrencyModel new];
                        currencyModel.currency = currency;
                        currencyModel.category = category;
                        currencyModel.salt = salt;
                        currencyModel.masterAddress = masterAddess;
                        currencyModel.status = 0;
                        currencyModel.blance = 0;
                        currencyModel.defaultAddress = masterAddess;
                        // save address
                        LMCurrencyAddress *addressModel = [LMCurrencyAddress new];
                        addressModel.address = masterAddess;
                        addressModel.index = 0;
                        addressModel.status = 1;
                        addressModel.label = nil;
                        addressModel.currency = currency;
                        addressModel.balance = 0;
                        [[LMRealmManager sharedManager]executeRealmWithRealmBlock:^(RLMRealm *realm) {
                            [realm addOrUpdateObject:addressModel];
                        }];
                        [currencyModel.addressListArray addObject:addressModel];
                        // save db to currency Address
                        switch ([LMWalletInfoManager sharedManager].categorys) {
                            case CategoryTypeOldUser:
                            {
                                currencyModel.payload = [LMWalletInfoManager sharedManager].encryPtionSeed;
                            }
                                break;
                            case CategoryTypeNewUser:
                            {
                                currencyModel.payload = nil;
                            }
                                break;
                                
                            default:
                                break;
                        }
                        [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                            [realm addOrUpdateObject:currencyModel];
                        }];
                        
                        if (complete) {
                            complete(YES);
                        }
                    }
                } fail:^(NSError *error) {
                    if (complete) {
                        complete(NO);
                    }
                }];
            }
        }];
    }
}
/**
 *  get currrency list
 *
 */
+ (void)getCurrencyListWithWalletId:(NSString *)walletId complete:(void (^)(BOOL result,NSArray<Coin *> *coinList))complete{
    
    [NetWorkOperationTool POSTWithUrlString:GetCurrencyList postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO,nil);
            }
            
        }else {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                Coins *coin = [Coins parseFromData:data error:nil];
                if (complete) {
                    complete(YES,coin.coinsArray);
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
 *  set currency messageInfo
 *
 */
+ (void)setCurrencyStatus:(int)status currency:(int)currency complete:(void (^)(BOOL result))complte{
    
    Coin *coin = [Coin new];
    coin.currency = currency;
    coin.status = status;
    [NetWorkOperationTool POSTWithUrlString:SetCurrencyInfo postProtoData:coin.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            
            
        }else {
            NSLog(@"asdasd");
            // save db
        }
    } fail:^(NSError *error) {
        
    }];

}

/**
 *  add currency address
 *
 */
+ (void)addCurrencyAddressWithCurrency:(int)currency label:(NSString *)label index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete{
    
    CreateCoinAccount *coinAddress = [CreateCoinAccount new];
    coinAddress.currency = currency;
    coinAddress.label = label;
    coinAddress.index = index;
    coinAddress.address = address;
    coinAddress.status = 1;
    [NetWorkOperationTool POSTWithUrlString:AddCurrencyAddress postProtoData:coinAddress.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            
            
        }else {
            NSLog(@"asdasd");
            // save db
        }
    } fail:^(NSError *error) {
        
    }];

}

/**
 *  get currency addresss list
 *
 */
+ (void)getCurrencyAddressListWithCurrency:(int)currency complete:(void (^)(BOOL result,NSMutableArray<CoinInfo *> *addressList)) complte {
    Coin *coin = [Coin new];
    coin.currency = currency;
    [NetWorkOperationTool POSTWithUrlString:GetCurrencyAddressList postProtoData:coin.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complte) {
                complte(NO,nil);
            }
        }else {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                CoinsDetail *coinDetail = [CoinsDetail parseFromData:data error:nil];
                NSMutableArray *coinDetailArray = coinDetail.coinInfosArray;
                if (complte) {
                    complte(YES,coinDetailArray);
                }
            }else {
                if (complte) {
                    complte(NO,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complte) {
            complte(NO,nil);
        }
    }];
}

/**
 * set currency address message
 *
 */
+ (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete {
    CoinInfo *coinInfo = [CoinInfo new];
    coinInfo.address = address;
    coinInfo.label = lable;
    coinInfo.status = status;
    [NetWorkOperationTool POSTWithUrlString:SetCurrencyAddressInfo postProtoData:coinInfo.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            
            
        }else {
            NSLog(@"asdasd");
            // save db
        }
    } fail:^(NSError *error) {
        
    }];
}

@end
