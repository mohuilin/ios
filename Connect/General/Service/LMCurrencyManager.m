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
    
    [NetWorkOperationTool POSTWithUrlString:CreatCurrencyUrl postProtoData:nil complete:^(id response) {
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
            NSMutableArray *addressList = [NSMutableArray array];
            [addressList addObject:masterAddess];
            [currencyModel.addressListArray addObjects:addressList];
            
            if ([LMWalletInfoManager sharedManager].categorys == CategoryTypeOldUser) {
                currencyModel.payload = nil;
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
/**
 *  get currrency list
 *
 */
+ (void)getCurrencyListWithWalletId:(NSString *)walletId complete:(void (^)(BOOL result,NSArray *coinList))complete{


}

/**
 *  set currency messageInfo
 *
 */
+ (void)setCurrencyStatus:(int)status complete:(void (^)(BOOL result))complte{


}

/**
 *  add currency address
 *
 */
+ (void)addCurrencyAddressWithCurrency:(NSString *)currency lable:(NSString *)lable index:(int)index address:(NSString *)address complete:(void (^)(BOOL result))complete{


}

/**
 *  get currency addresss list
 *
 */
+ (void)getCurrencyAddressListWithCurrency:(NSString *)currency complete:(void (^)(BOOL result,NSArray *addressList))complte {


}

/**
 * set currency address message
 *
 */
+ (void)setCurrencyAddressMessageWithAddress:(NSString *)address lable:(NSString *)lable status:(int)status complete:(void (^)(BOOL result))complete {

}
@end
