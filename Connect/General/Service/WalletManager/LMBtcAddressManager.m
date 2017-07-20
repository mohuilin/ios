//
//  LMBtcAddressManager.m
//  Connect
//
//  Created by Connect on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBtcAddressManager.h"
#import "NetWorkOperationTool.h"
#import "LMCurrencyModel.h"
#import "LMRealmManager.h"
#import "Wallet.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "ConnectTool.h"

@implementation LMBtcAddressManager
/**
 *  add currency address
 *
 */
- (void)addCurrencyAddressWithLabel:(NSString *)label index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete{
    
    CreateCoinAccount *coinAddress = [CreateCoinAccount new];
    coinAddress.currency = (int)CurrencyTypeBTC;
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
- (void)getCurrencyAddressList:(void (^)(BOOL result,NSMutableArray<CoinInfo *> *addressList)) complte {
    Coin *coin = [Coin new];
    coin.currency = (int)CurrencyTypeBTC;
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
                if (coinDetailArray.count > 0) {
                    if (complte) {
                        complte(YES,coinDetailArray);
                    }
                    // save address db
                    NSMutableArray *saveArray = [NSMutableArray array];
                    for (CoinInfo *coinAddress in coinDetailArray) {
                       
                        LMCurrencyAddress *saveAddress = [LMCurrencyAddress new];
                        saveAddress.address = coinAddress.address;
                        saveAddress.label = coinAddress.label;
                        saveAddress.status = coinAddress.status;
                        saveAddress.balance = coinAddress.balance;
                        saveAddress.index = coinAddress.index;
                        saveAddress.currency = (int)CurrencyTypeBTC;
                        saveAddress.amount = coinAddress.amount;
                        [saveArray addObject:saveAddress];
                        
                    }
                    [[LMRealmManager sharedManager] executeRealmWithRealmBlock:^(RLMRealm *realm) {
                        for (LMCurrencyAddress *saveAddress in saveArray) {
                            [realm addOrUpdateObject:saveAddress];
                        }
                    }];
                }else {
                    if (complte) {
                        complte(YES,nil);
                    }
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
- (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete {
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
