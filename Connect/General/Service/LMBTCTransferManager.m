//
//  LMBTCTransferManager.m
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBTCTransferManager.h"
#import "LMBTCWalletHelper.h"
#import "InputPayPassView.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"
#import "LMWalletInfoManager.h"
#import "LMRealmManager.h"
#import "LMCurrencyAddress.h"
#import "LMCurrencyManager.h"

@implementation LMBTCTransferManager

CREATE_SHARED_MANAGER(LMBTCTransferManager)

- (void)sendLuckyPackageWithReciverIdentifier:(NSString *)identifier size:(int)size amount:(NSInteger)amount fee:(NSInteger)fee luckyPackageType:(LuckypackageType)luckyPackageType tips:(NSString *)tips indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
    LuckyPackageRequest *request = [[LuckyPackageRequest alloc] init];
    request.size = size;
    request.amount = amount;
    request.fee = fee;
    request.tips = tips;
    request.packageType = luckyPackageType;
    
    NSArray *txIn = [self addressesFromIndexes:indexes];
    SendCurrency *sendCurrency = [[SendCurrency alloc] init];
    sendCurrency.currency = CurrencyTypeBTC;
    sendCurrency.txin = txIn.mutableCopy;
    
    request.sendCurrency = sendCurrency;
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
                    /// password verfiy --- encrypt seed
                    [InputPayPassView inputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, NSString *baseSeed) {
                        if (baseSeed) {
                            /// sign and publish
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction seed:baseSeed complete:^(id data,NSError *error) {
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
    
    NSArray *txIn = [self addressesFromIndexes:indexes];
    URLTransferRequest *request = [[URLTransferRequest alloc] init];
    request.fee = fee;
    request.amount = amount;
    
    SendCurrency *sendCurrency = [[SendCurrency alloc] init];
    sendCurrency.currency = CurrencyTypeBTC;
    sendCurrency.txin = txIn.mutableCopy;
    
    request.sendCurrency = sendCurrency;
    
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
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction seed:baseSeed complete:^(id data,NSError *signError) {
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


- (void)sendCrowdfuningToGroup:(NSString *)groupIdentifier Amount:(NSInteger)amount size:(int)size tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete{
    
    /// send crowdfuning
    CrowdfuningRequest *request = [[CrowdfuningRequest alloc] init];
    request.groupIdentifier = groupIdentifier;
    request.amount = amount;
    request.size = size;
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
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)sendReceiptToPayer:(NSString *)payer amount:(NSInteger)amount tips:(NSString *)tips complete:(void (^)(NSString *txId,NSError *error))complete{
    
    /// send crowdfuning
    ReceiptRequest *request = [[ReceiptRequest alloc] init];
    request.payer = payer;
    request.amount = amount;
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

            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)payCrowdfuningReceiptWithHashId:(NSString *)hashId type:(ReceiptType)type indexes:(NSArray *)indexes complete:(CompleteWithDataBlock)complete{
    
    NSArray *txIn = [self addressesFromIndexes:indexes];
    
    /// pay crowdfuning
    PayCrowdReceipt *request = [[PayCrowdReceipt alloc] init];
    
    SendCurrency *sendCurrency = [[SendCurrency alloc] init];
    sendCurrency.currency = CurrencyTypeBTC;
    sendCurrency.txin = txIn.mutableCopy;
    
    request.sendCurrency = sendCurrency;
    request.receiptType = type;
    request.hashId = hashId;
    
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
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction seed:baseSeed  complete:^(id data,NSError *signError) {
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
    toAddresses = @[@"1FNY72y8cfmtrjXJoxbLchBNgWADAyhU7i"];
    NSMutableArray *txoutPuts = [NSMutableArray array];
    for (NSString *address in toAddresses) {
        Txout *txOut = [Txout new];
        txOut.address = address;
        txOut.amount = 500;
        [txoutPuts addObject:txOut];
    }
    
    request.outPutsArray = txoutPuts;
    
    Txin *txIn = [Txin new];
    txIn.addressesArray = @[@"1oZNecL2KaQkM6iRBqBRh63T7Fcbx3V6u",
                            @"1EsSmrKQvh2md4wRiNrkUGHnUpeT4nzZf3"].mutableCopy;// addresses.mutableCopy;
    
    SendCurrency *sendCurrency = [[SendCurrency alloc] init];
    sendCurrency.currency = CurrencyTypeBTC;
    sendCurrency.txin = txIn;
    request.sendCurrency = sendCurrency;
    
    request.fee = fee;
    request.tips = tips;
    request.transferType = WalletTransferTypeInnerConnect;
    
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:WalletServiceTransfer postProtoData:request.data complete:^(id response) {
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
    
    NSMutableArray *txoutPuts = [NSMutableArray array];
    for (NSString *address in toAddresses) {
        Txout *txOut = [Txout new];
        txOut.address = address;
        txOut.amount = 500;
        [txoutPuts addObject:txOut];
    }
    request.outPutsArray = txoutPuts;
    
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
                        [self signRawTransactionAndPublishWihtOriginalTransaction:originalTransaction seed:baseSeed complete:^ (id data,NSError *signError) {
                            if (passView.requestCallBack) {
                                passView.requestCallBack(signError);
                            }
                            if (!signError) {
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


- (void)signRawTransactionAndPublishWihtOriginalTransaction:(OriginalTransaction *)originalTransaction seed:(NSString *)seed complete:(CompleteWithDataBlock)complete{

    /*
     (lldb) po [[LKUserCenter shareCenter] currentLoginUser].address
     1EsSmrKQvh2md4wRiNrkUGHnUpeT4nzZf3
     
     (lldb) po [[LKUserCenter shareCenter] currentLoginUser].prikey
     KzMHVHBuuh5wvnPqopvbhMENujuF4pmdRtwDHKQDmoTUc1KJL74G
     Ukeiy7kfek9kEJeki0eEjYeJIlmKkyKLkel8UkefjkjTujcjlm76
     */
    
    NSDictionary *addressPrivkeyDict = @{@"1oZNecL2KaQkM6iRBqBRh63T7Fcbx3V6u":@"Kyw6dzL6Z4sstscFjRdyFEjZJAt84ZytqHxj4fTR4yoKoxa11RPJ",
                                         @"1EsSmrKQvh2md4wRiNrkUGHnUpeT4nzZf3":@"KzMHVHBuuh5wvnPqopvbhMENujuF4pmdRtwDHKQDmoTUc1KJL74G"};
    
    NSMutableArray *privkeyArray = [NSMutableArray array];
    for (NSString *address in originalTransaction.addressesArray) {
        NSString *pr = [addressPrivkeyDict objectForKey:address];
        if (pr) {
            [privkeyArray addObject:pr];
        }
    }
    
    NSString *signTransaction1 = [LMBTCWalletHelper signRawTranscationWithTvs:originalTransaction.vts privkeys:privkeyArray rawTranscation:originalTransaction.rawhex];
    
    if (complete) {
        complete(nil,nil);
    }
    /// query btc salt  -> seed - btcseed
    
    return;
    RLMResults *result = [LMCurrencyAddress objectsWhere:[NSString stringWithFormat:@"currency = %d and address in (%@)",(int)CurrencyTypeBTC, [originalTransaction.addressesArray componentsJoinedByString:@","]]];
    
    
    for (LMCurrencyAddress *currrencyAddress in result) {
        NSString *inputsPrivkey = [LMBTCWalletHelper getPrivkeyBySeed:seed index:currrencyAddress.index];
        if (inputsPrivkey) {
            [privkeyArray addObject:inputsPrivkey];
        }
    }
    NSString *signTransaction = [LMBTCWalletHelper signRawTranscationWithTvs:originalTransaction.vts privkeys:@[@"Kyw6dzL6Z4sstscFjRdyFEjZJAt84ZytqHxj4fTR4yoKoxa11RPJ"] rawTranscation:originalTransaction.rawhex];
    
    return;
    PublishTransaction *publish = [[PublishTransaction alloc] init];
    publish.txHex = signTransaction;
    publish.hashId = originalTransaction.hashId;
    
    /// publish
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:publish.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            if (complete) {
                complete(originalTransaction.hashId,nil);
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
    RLMResults *result = [LMCurrencyAddress objectsWhere:[NSString stringWithFormat:@"currency = %d and index in (%@)",(int)CurrencyTypeBTC,[indexes componentsJoinedByString:@","]]];
    for (LMCurrencyAddress *currencyAddress in result) {
        if (currencyAddress.address) {
            [addressArray addObject:currencyAddress.address];
        }
    }
    return addressArray;
}

@end
