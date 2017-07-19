//
//  LMTransferManager.m
//  Connect
//
//  Created by MoHuilin on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTransferManager.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"
#import "LMCurrencyAddress.h"
#import "InputPayPassView.h"
#import "LMBtcCurrencyManager.h"


@implementation LMTransferManager

CREATE_SHARED_MANAGER(LMTransferManager)

- (void)sendLuckyPackageWithReciverIdentifier:(NSString *)identifier size:(int)size amount:(NSInteger)amount fee:(NSInteger)fee luckyPackageType:(int)type category:(LuckypackageTypeCategory)category tips:(NSString *)tips fromAddresses:(NSArray *)fromAddresses currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{

    LuckyPackageRequest *request = [[LuckyPackageRequest alloc] init];
    request.size = size;
    request.amount = amount;
    request.fee = fee;
    request.tips = tips;
    request.typ = type;
    request.category =category;

    request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
    
    //request and sign、 publish
    [self basePostDataWithData:request.data url:WalletServiceLuckpackage type:TransactionTypeLuckypackage currency:currency complete:complete];
}


- (void)sendUrlTransferFromAddresses:(NSArray *)fromAddresses tips:(NSString *)tips amount:(NSInteger)amount fee:(NSInteger)fee currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    
    OutTransfer *request = [[OutTransfer alloc] init];
    request.fee = fee;
    request.amount = amount;
    request.tips = tips;
    
    request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];

    //request and sign、 publish
    [self basePostDataWithData:request.data url:WalletServiceExternal type:TransactionTypeURLTransfer currency:currency complete:complete];
    
}


- (void)sendCrowdfuningToGroup:(NSString *)groupIdentifier amount:(NSInteger)amount size:(int)size tips:(NSString *)tips complete:(void (^)(Crowdfunding *crowdfunding,NSError *error))complete{
    
    /// send crowdfuning
    CrowdfundingRequest *request = [[CrowdfundingRequest alloc] init];
    request.groupIdentifier = groupIdentifier;
    request.amount = amount;
    request.size = size;
    request.tips = tips;
    
    [NetWorkOperationTool POSTWithUrlString:WalletServiceCrowdfuning postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                Crowdfunding *crowdfunding = [Crowdfunding parseFromData:data error:nil];
                if (complete) {
                    complete(crowdfunding,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)sendReceiptToPayer:(NSString *)payer amount:(NSInteger)amount tips:(NSString *)tips complete:(void (^)(Bill *bill,NSError *error))complete{
    
    /// send crowdfuning
    ReceiveRequest *request = [[ReceiveRequest alloc] init];
    request.sender = payer;
    request.amount = amount;
    request.tips = tips;
    
    [NetWorkOperationTool POSTWithUrlString:WalletServiceReceive postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else {
            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                Bill *bill = [Bill parseFromData:data error:nil];
                if (complete) {
                    complete(bill,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

- (void)payCrowdfuningReceiptWithHashId:(NSString *)hashId type:(TransactionType)type fromAddresses:(NSArray *)fromAddresses fee:(NSInteger)fee currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    /// pay crowdfuning
    Payment *request = [[Payment alloc] init];
    
    request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
    request.payType = type;
    request.hashId = hashId;
    request.fee = fee;

    //request and sign、 publish
    [self basePostDataWithData:request.data url:WalletServicePay type:type currency:currency complete:complete];
}

- (void)transferFromAddresses:(NSArray *)fromAddresses currency:(CurrencyType)currency fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete{
    
    TransferRequest *request = [[TransferRequest alloc] init];
    NSMutableArray *txoutPuts = [NSMutableArray array];
    for (NSString *address in toAddresses) {
        Txout *txOut = [Txout new];
        txOut.address = address;
        txOut.amount = perAddressAmount;
        [txoutPuts addObject:txOut];
    }
    
    request.txOutArray = txoutPuts;
    request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
    
    request.fee = fee;
    request.tips = tips;
    

    //request and sign、 publish
    [self basePostDataWithData:request.data url:WalletServiceTransfer type:TransactionTypeBill currency:currency complete:complete];
}

- (void)transferFromAddresses:(NSArray *)fromAddresses currency:(CurrencyType)currency fee:(NSInteger)fee toConnectUserIds:(NSArray *)userIds perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete{
    
    ConnectTransferRequest *request = [[ConnectTransferRequest alloc] init];
    NSMutableArray *txoutPuts = [NSMutableArray array];
    for (NSString *uid in userIds) {
        ConnectTxout *txOut = [ConnectTxout new];
        txOut.uid = uid;
        txOut.amount = perAddressAmount;
        [txoutPuts addObject:txOut];
    }
    
    request.txOutArray = txoutPuts;
    request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
    
    request.fee = fee;
    request.tips = tips;
    
    //request and sign、 publish
    [self basePostDataWithData:request.data url:WalletServiceTransfer type:TransactionTypeBill currency:currency complete:complete];
}

#pragma mark - private

- (SpentCurrency *)packageCurrencyTxinWithCurrency:(CurrencyType)currency fromAddresses:(NSArray *)fromAddresses{
    Txin *txIn = [Txin new];
    txIn.addressesArray =fromAddresses.mutableCopy;
    
    SpentCurrency *spentCurrency = [[SpentCurrency alloc] init];
    spentCurrency.currency = currency;
    spentCurrency.txin = txIn;
    
    return spentCurrency;
}

- (void)signRawTransactionAndPublishWihtOriginalTransaction:(OriginalTransaction *)originalTransaction transactionType:(TransactionType)transactionType currency:(CurrencyType)currency seed:(NSString *)seed complete:(CompleteWithDataBlock)complete{

    NSMutableArray *privkeyArray = [NSMutableArray array];
    RLMResults *result = [LMCurrencyAddress objectsWhere:[NSString stringWithFormat:@"currency = %d and address in (%@)",(int)currency, [originalTransaction.addressesArray componentsJoinedByString:@","]]];

    for (LMCurrencyAddress *currrencyAddress in result) {
        NSString *inputsPrivkey = [LMBtcCurrencyManager getPrivkeyBySeed:seed index:currrencyAddress.index];
        if (inputsPrivkey) {
            [privkeyArray addObject:inputsPrivkey];
        }
    }
    
    //1、define interface
    LMBaseCurrencyManager *currencyManager = nil;
    
    //2、create speacil manager
    switch (currency) {
        case CurrencyTypeBTC:
            currencyManager = [[LMBtcCurrencyManager alloc] init];
            break;
        default:
            break;
    }
    
    //3、sign rawhex
    NSString *signTransaction = [currencyManager signRawTranscationWithTvs:originalTransaction.vts rawTranscation:originalTransaction.rawhex inputs:originalTransaction.addressesArray seed:seed];
    
    
    //publish
    PublishTransaction *publish = [[PublishTransaction alloc] init];
    publish.txHex = signTransaction;
    publish.hashId = originalTransaction.hashId;
    publish.transactionType = transactionType;
    publish.currency = currency;
    
    /// publish
    [NetWorkOperationTool POSTWithUrlString:WalletServicePublish postProtoData:publish.data complete:^(id response) {
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

- (void)basePostDataWithData:(NSData *)postData url:(NSString *)url type:(TransactionType)type currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:url postProtoData:postData complete:^(id response) {
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
                            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransaction transactionType:type currency:currency seed:baseSeed complete:^(id data, NSError *signError) {
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

@end
