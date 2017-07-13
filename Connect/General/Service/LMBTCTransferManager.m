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
#import "Wallet.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"
#import "LMWalletInfoManager.h"
#import "LMRealmManager.h"
#import "LMCurrencyAddress.h"

@implementation LMBTCTransferManager

CREATE_SHARED_MANAGER(LMBTCTransferManager)

- (void)sendLuckyPackageWithTotal:(int)total amount:(NSInteger)amount fee:(NSInteger)fee amountType:(LuckypackageAmountType)amountType luckyPackageType:(LuckypackageType)luckyPackageType tips:(NSString *)tips indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    LuckyPackageRequest *request = [[LuckyPackageRequest alloc] init];
    request.total = total;
    request.amount = amount;
    request.fee = fee;
    request.tips = tips;
    request.allotType = amountType;
    request.packageType = luckyPackageType;
    request.addressesArray = fromAddresses.mutableCopy;
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
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
                            [self signRawTransactionAndPublishTransactionWithRaw:oriTransaction.rawhex vts:oriTransaction.vts seed:baseSeed indexes:indexes complete:^(NSError *error) {
                                if (complete) {
                                    complete(error);
                                }
                            }];
                        }
                    }];
                } else {
                    if (complete) {
                        complete(error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}


- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    
    TransferRequest *request = [[TransferRequest alloc] init];
    request.fromAddressesArray = fromAddresses.mutableCopy;
    request.amount = amount;
    request.fee = fee;
    request.transferType = 1;
    
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
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
                            [self signRawTransactionAndPublishTransactionWithRaw:oriTransaction.rawhex vts:oriTransaction.vts seed:baseSeed indexes:indexes complete:^(NSError *signError) {
                                if (complete) {
                                    complete(signError);
                                }
                            }];
                        }
                    }];
                } else {
                    if (complete) {
                        complete(error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
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

- (void)payCrowdfuningWithTxId:(NSString *)txId indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    
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
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
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
                            [self signRawTransactionAndPublishTransactionWithRaw:oriTransaction.rawhex vts:oriTransaction.vts seed:baseSeed indexes:indexes complete:^(NSError *signError) {
                                if (complete) {
                                    complete(signError);
                                }
                            }];
                        }
                    }];
                } else {
                    if (complete) {
                        complete(error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];

}

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(void (^)(NSString *,NSString * ,NSError *))complete{
    
    TransferRequest *request = [[TransferRequest alloc] init];
    request.toAddressesArray = toAddresses.mutableCopy;
    request.fromAddressesArray = addresses.mutableCopy;
    request.amount = perAddressAmount;
    request.fee = fee;
    request.tips = tips;
    
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                NSError *error = nil;
                OriginalTransaction *oriTransaction = [OriginalTransaction parseFromData:data error:&error];
                if (!error) {
                    if (complete) {
                        complete(oriTransaction.vts,oriTransaction.rawhex,nil);
                    }
                } else {
                    if (complete) {
                        complete(nil,nil,error);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,nil,error);
        }
    }];
}

- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(CompleteBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    [self transferFromAddress:fromAddresses fee:fee toAddresses:toAddresses perAddressAmount:perAddressAmount complete:^(NSString *vts,NSString *rawTransaction, NSError *rawTransactionError) {
        if (!rawTransactionError) {
            /// password verfiy --- encrypt seed
            
            [InputPayPassView inputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, NSString *baseSeed) {
                if (baseSeed) {
                    /// sign and publish
                    [self signRawTransactionAndPublishTransactionWithRaw:rawTransaction vts:vts seed:baseSeed indexes:indexes complete:^(NSError *signError) {
                        if (complete) {
                            complete(signError);
                        }
                    }];
                }
            }];
        } else {
            if (complete) {
                complete(rawTransactionError);
            }
        }
    }];
}

- (void)signRawTransactionAndPublishTransactionWithRaw:(NSString *)rawTransaction vts:(NSString *)vts seed:(NSString *)seed indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    
    /// query btc salt  -> seed - btcseed
    
    NSMutableArray *privkeyArray = [NSMutableArray array];
    for (NSNumber *index in indexes) {
        NSString *inputsPrivkey = [LMBTCWalletHelper getPrivkeyBySeed:seed index:index.intValue];
        if (inputsPrivkey) {
            [privkeyArray addObject:inputsPrivkey];
        }
    }
    NSString *signTransaction = [LMBTCWalletHelper signRawTranscationWithTvs:vts privkeys:privkeyArray rawTranscation:rawTransaction];
    
    PublishTransaction *publish = [[PublishTransaction alloc] init];
    publish.signedHex = signTransaction;
    
    /// publish
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:publish.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            if (complete) {
                complete(nil);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}

#pragma mark - private 

- (NSArray *)addressesFromIndexes:(NSArray *)indexes{

    NSMutableArray *addressArray = [NSMutableArray array];
    NSString *seed = [LMWalletInfoManager sharedManager].baseSeed;
    for (NSNumber *index in indexes) {
        NSString *inputsPrivkey = [LMBTCWalletHelper getPrivkeyBySeed:seed index:index.intValue];
        if (inputsPrivkey) {
            NSString *inputsAddress = [LMBTCWalletHelper getAddressByPrivKey:inputsPrivkey];
            [addressArray addObject:inputsAddress];
        }
    }
    
    return addressArray;
}

@end
