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
