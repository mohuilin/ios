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
@implementation LMCurrencyManager
/**
 *  creat currency
 *
 */
+ (void)createCurrency:(int)currency salt:(NSString *)salt category:(int)category masterAddess:(NSString *)masterAddess complete:(void (^)(BOOL result))complete {
   
    CreateCoinArgs *currencyCoin = [CreateCoinArgs new];
    currencyCoin.salt = salt;
    currencyCoin.category = category;
    currencyCoin.masterAddress = masterAddess;
    currencyCoin.currency = currency;
    currencyCoin.payload = nil;
    currencyCoin.wId = nil;
    
    [LMCurrencyModel setDefaultRealm];
    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d"],currency] lastObject];
    if (!currencyModel) {
        // sync currency
        [LMCurrencyManager getCurrencyListWithWalletId:nil complete:^(BOOL result, NSArray<Coin *> *coinList) {
            BOOL flag = NO;
            for (Coin *coin in coinList) {
                if (coin.currency == currency) {
                    flag = YES;
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
                        
                        if ([LMWalletInfoManager sharedManager].categorys == CategoryTypeOldUser) {
                            currencyModel.payload = [LMWalletInfoManager sharedManager].encryPtionSeed;
                        }else if ([LMWalletInfoManager sharedManager].categorys == CategoryTypeNewUser){
                            currencyModel.payload = nil;
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
                    complete(NO,coin.coinsArray);
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
    
    
    RequestCreateCoinInfo *coin = [RequestCreateCoinInfo new];
    coin.currency = currency;
    coin.label = label;
    coin.index = index;
    coin.address = address;
    coin.status = 0;
    [NetWorkOperationTool POSTWithUrlString:AddCurrencyAddress postProtoData:coin.data complete:^(id response) {
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
+ (void)getCurrencyAddressListWithCurrency:(int)currency complete:(void (^)(BOOL result,NSArray *addressList)) complte {
    Coin *coin = [Coin new];
    coin.currency = currency;
    [NetWorkOperationTool POSTWithUrlString:AddCurrencyAddress postProtoData:coin.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            
            
        }else {
            
            // save db
        }
    } fail:^(NSError *error) {
        
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
/**
 * update default address
 *
 */
+ (void)updateCurrencyDefaultAddress:(NSString *)address currency:(int)currency complete:(void (^)(BOOL result))complete {
 
    RequestCreateCoinInfo *info = [RequestCreateCoinInfo new];
    info.address = address;
    info.currency = currency;
    [NetWorkOperationTool POSTWithUrlString:UpdateCurrencyDefaultAddress postProtoData:info.data complete:^(id response) {
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
 * get default address
 *
 */
+ (void)getCurrencyDefaultAddressArrayWithcomplete:(void (^)(BOOL result,NSArray *defaultAddrssArray ))complete{
    
    [NetWorkOperationTool POSTWithUrlString:GetCurrencyDefaultAddress postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO,nil);
            }
        }else {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                ListDefaultAddress *listAddress = [ListDefaultAddress parseFromData:data error:nil];
                if (complete) {
                    complete(YES,listAddress.defaultAddressesArray);
                }
            }
            // save db
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO,nil);
        }
    }];

}
@end
