//
//  LMBTCTransferManager.m
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBTCTransferManager.h"
#import "InputPayPassView.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"
#import "LMWalletInfoManager.h"
#import "LMRealmManager.h"
#import "LMCurrencyAddress.h"
#import "LMBaseCurrencyManager.h"

@implementation LMBTCTransferManager

CREATE_SHARED_MANAGER(LMBTCTransferManager)

- (void)sendLuckyPackageWithTotal:(int)total amount:(NSInteger)amount fee:(NSInteger)fee amountType:(LuckypackageAmountType)amountType luckyPackageType:(LuckypackageType)luckyPackageType tips:(NSString *)tips indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    LuckyPackageRequest *request = [[LuckyPackageRequest alloc] init];
    request.total = total;
    request.amount = amount;
    request.fee = fee;
    request.tips = tips;
    request.allotType = amountType;
    request.packageType = luckyPackageType;
    request.addressesArray = fromAddresses.mutableCopy;
    // send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                OriginalTransaction *oriTransaction = [OriginalTransaction parseFromData:data error:&error];
                if (!error) {
                    /// password verfiy --- encrypt seed
                    [InputPayPassView inputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, NSString *baseSeed) {
                        if (baseSeed) {
                            /// sign and publish
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction seed:baseSeed indexes:indexes complete:^(id data,NSError *error) {
                                if (complete) {
                                    complete(data,error);
                                }
                            }];
                        }
                    }];
                } else {
                    if (complete) {
                        complete(nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}


- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    
    TransferRequest *request = [[TransferRequest alloc] init];
    request.fromAddressesArray = fromAddresses.mutableCopy;
    request.amount = amount;
    request.fee = fee;
    request.transferType = WalletTransferTypeOuterUrl;
    
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                OriginalTransaction *oriTransaction = [OriginalTransaction parseFromData:data error:&error];
                if (!error) {
                    [InputPayPassView inputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, NSString *baseSeed) {
                        if (baseSeed) {
                            /// sign and publish
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction seed:baseSeed indexes:indexes complete:^(id data,NSError *signError) {
                                if (complete) {
                                    complete(data,signError);
                                }
                            }];
                        }
                    }];
                } else {
                    if (complete) {
                        complete(nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}


- (void)sendCrowdfuningAmount:(NSInteger)amount total:(int)total tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete{
    /// send crowdfuning
    CrowdfuningRequest *request = [[CrowdfuningRequest alloc] init];
    request.amount = amount;
    request.total = total;
    request.tips = tips;
    
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                CrowdfuningResp *crodfunResp = [CrowdfuningResp parseFromData:data error:&error];
                if (!error) {
                    if (complete) {
                        complete(crodfunResp.txId,nil);
                    }
                } else {
                    if (complete) {
                        complete(nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)payCrowdfuningWithTxId:(NSString *)txId indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    
    /// pay crowdfuning
    PayCrowdRequest *request = [[PayCrowdRequest alloc] init];
    request.txId = txId;
    request.addressesArray = fromAddresses.mutableCopy;
    
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                OriginalTransaction *oriTransaction = [OriginalTransaction parseFromData:data error:&error];
                if (!error) {
                    [InputPayPassView inputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, NSString *baseSeed) {
                        if (baseSeed) {
                            /// sign and publish
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction seed:baseSeed indexes:indexes complete:^(id data,NSError *signError) {
                                if (complete) {
                                    complete(data,signError);
                                }
                            }];
                        }
                    }];
                } else {
                    if (complete) {
                        complete(nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];

}

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(OriginalTransaction *originalTransaction,NSError *error))complete{
    
    TransferRequest *request = [[TransferRequest alloc] init];
    request.toAddressesArray = toAddresses.mutableCopy;
    request.fromAddressesArray = addresses.mutableCopy;
    request.amount = perAddressAmount;
    request.fee = fee;
    request.tips = tips;
    request.transferType = WalletTransferTypeInnerConnect;
    
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                OriginalTransaction *oriTransaction = [OriginalTransaction parseFromData:data error:&error];
                if (!error) {
                    if (complete) {
                        complete(oriTransaction,nil);
                    }
                } else {
                    if (complete) {
                        complete(nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)transferWithFee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(OriginalTransaction *originalTransaction,NSError *error))complete{
    TransferRequest *request = [[TransferRequest alloc] init];
    request.toAddressesArray = toAddresses.mutableCopy;
    request.amount = perAddressAmount;
    request.fee = fee;
    request.tips = tips;
    request.transferType = WalletTransferTypeInnerConnect;
}


- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    
    [self transferFromAddress:fromAddresses fee:fee toAddresses:toAddresses perAddressAmount:perAddressAmount tips:tips complete:^(OriginalTransaction *originalTransaction,NSError *rawTransactionError) {
            if (!rawTransactionError) {
                /// password verfiy --- encrypt seed
                [InputPayPassView inputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, NSString *baseSeed) {
                    if (baseSeed) {
                        /// sign and publish
                        [self signRawTransactionAndPublishWihtOriginalTransaction:originalTransaction seed:baseSeed indexes:indexes complete:^ (id data,NSError *signError) {
                            if (signError) {
                                if (passView.requestCallBack) {
                                    passView.requestCallBack(signError);
                                }
                            } else {
                                if (complete) {
                                    complete(data,nil);
                                }
                            }
                        }];
                    }
                }];
            } else {
                if (complete) {
                    complete(nil,rawTransactionError);
                }
            }
    }];
}


- (void)signRawTransactionAndPublishWihtOriginalTransaction:(OriginalTransaction *)originalTransaction seed:(NSString *)seed indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
    /// query btc salt  -> seed - btcseed
    
    NSMutableArray *privkeyArray = [NSMutableArray array];
    for (NSNumber *index in indexes) {
        NSString *inputsPrivkey = [LMBaseCurrencyManager getPrivkeyBySeed:seed index:index.intValue];
        if (inputsPrivkey) {
            [privkeyArray addObject:inputsPrivkey];
        }
    }
    NSString *signTransaction = [LMBaseCurrencyManager signRawTranscationWithTvs:originalTransaction.vts privkeys:privkeyArray rawTranscation:originalTransaction.rawhex];
    
    PublishTransaction *publish = [[PublishTransaction alloc] init];
    publish.signedHex = signTransaction;
    publish.transactionId = originalTransaction.transactionId;
    
    /// publish
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:publish.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            if (complete) {
                complete(originalTransaction.transactionId,nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)transactionFlowingComplete:(CompleteWithDataBlock)complete{
    TransactionFlowingRequest *request = [TransactionFlowingRequest new];
    request.currency = CurrencyTypeBTC;
    /// publish
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                TransactionFlowings *transactionFlowing = [TransactionFlowings parseFromData:data error:&error];
                //save to db
                
                if (!error) {
                    if (complete) {
                        complete(transactionFlowing,nil);
                    }
                } else {
                    if (complete) {
                        complete(nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

#pragma mark - private 

- (NSArray *)addressesFromIndexes:(NSArray *)indexes{
    if (!indexes.count) {
        return nil;
    }
    NSMutableArray *addressArray = [NSMutableArray array];
    RLMResults *result = [LMCurrencyAddress objectsWhere:[NSString stringWithFormat:@"currency = 0 and index in (%@)",[indexes componentsJoinedByString:@","]]];
    for (LMCurrencyAddress *currencyAddress in result) {
        if (currencyAddress.address) {
            [addressArray addObject:currencyAddress.address];
        }
    }
    return addressArray;
}

@end
