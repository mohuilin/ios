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
            DDLogInfo(@"asdasd");
            // save db
        }
    } fail:^(NSError *error) {
        
    }];
    
}

/**
 *  get currency addresss list
 *
 */
- (void)getCurrencyAddressList:(void (^)(NSMutableArray<CoinInfo *> *addressList,NSError *error))complete {
    Coin *coin = [Coin new];
    coin.currency = (int)CurrencyTypeBTC;
    [NetWorkOperationTool POSTWithUrlString:GetCurrencyAddressList postProtoData:coin.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:GET_ADDRESSLIST_FAILED_134 userInfo:nil]);
            }
        }else {
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                CoinsDetail *coinDetail = [CoinsDetail parseFromData:data error:nil];
                NSMutableArray *coinDetailArray = coinDetail.coinInfosArray;
                // save defaultAddress
                LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d ",(int)CurrencyTypeBTC]] lastObject];
                // save address db
                [[LMRealmManager sharedManager] executeRealmWithBlock:^{
                    for (CoinInfo *coinAddress in coinDetailArray) {
                        LMCurrencyAddress *currencyAddress = [[LMCurrencyAddress objectsWhere:[NSString stringWithFormat:@"currency = %d and address = '%@'",(int)CurrencyTypeBTC,coinAddress.address]] lastObject];
                        if (currencyAddress) {
                            currencyAddress.label = coinAddress.label;
                            currencyAddress.status = coinAddress.status;
                            currencyAddress.balance = coinAddress.balance;
                            currencyAddress.amount = coinAddress.amount;
                        } else {
                            LMCurrencyAddress *saveAddress = [LMCurrencyAddress new];
                            saveAddress.address = coinAddress.address;
                            saveAddress.label = coinAddress.label;
                            saveAddress.status = coinAddress.status;
                            saveAddress.balance = coinAddress.balance;
                            saveAddress.index = coinAddress.index;
                            saveAddress.currency = (int)CurrencyTypeBTC;
                            saveAddress.amount = coinAddress.amount;
                            [currencyModel.addressListArray addObject:saveAddress];
                        }
                    }
                }];
                if (complete) {
                    complete(coinDetailArray,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"" code:GET_ADDRESSLIST_FAILED_134 userInfo:nil]);
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
            DDLogInfo(@"asdasd");
            // save db
        }
    } fail:^(NSError *error) {
        
    }];
}


- (void)syncAddressListWithInputInputs:(NSArray *)inputs complete:(void (^)(NSError *error))complete{
    
    /// test
    NSMutableString *mStr = [NSMutableString stringWithFormat:@"currency = %d AND address IN {",(int)CurrencyTypeBTC];
    for (NSString *address in inputs) {
        if ([address isEqualToString:[inputs lastObject]]) {
            [mStr appendFormat:@"'%@'",address];
        } else {
            [mStr appendFormat:@"'%@',",address];
        }
    }
    [mStr appendString:@"}"];
    RLMResults *results = [LMCurrencyAddress objectsWhere:mStr];
    //sync
    /// test
    if (results.count != inputs.count) {
        [self getCurrencyAddressList:^(NSMutableArray<CoinInfo *> *addressList,NSError *error) {
            if (!error) {
                RLMResults *results = [LMCurrencyAddress objectsWhere:mStr];
                if (results.count == inputs.count) {
                    if (complete) {
                        complete(nil);
                    }
                } else {
                    if (complete) {
                        complete([NSError errorWithDomain:@"sync error" code:TransactionPackageErrorTypeSyncAddress_InputsAddress_NotMatch userInfo:nil]);
                    }
                }
            } else {
                if (complete) {
                    complete(error);
                }
            }
        }];
    } else {
        if (complete) {
            complete(nil);
        }
    }
}
/**
 *  ListWithInputInputs
 *
 */
- (void)getAddress:(void (^)(CoinInfo *address,NSError *error))complete {

  [self getCurrencyAddressList:^(NSMutableArray<CoinInfo *> *addressList, NSError *error) {
      if (!error) {
          if (addressList.count > 0) {
              CoinInfo *address = [addressList firstObject];
              if (complete) {
                  complete(address,nil);
              }
          }
      }else {
          if (complete) {
              complete(nil,[NSError errorWithDomain:@"" code:GET_ADDRESSLIST_FAILED_134 userInfo:nil]);
          }
       
      }
      
      
  }];
}

@end
