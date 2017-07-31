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
#import "LMBtcAddressManager.h"
#import "UIAlertController+Blocks.h"
#import "UIViewController+CurrencyVC.h"
#import "LMWalletManager.h"
#import "StringTool.h"
#import "LMCurrencyModel.h"


@implementation LMTransferManager

CREATE_SHARED_MANAGER(LMTransferManager)

- (void)sendLuckyPackageWithReciverIdentifier:(NSString *)identifier size:(int)size amount:(NSInteger)amount fee:(NSInteger)fee luckyPackageType:(int)type category:(LuckypackageTypeCategory)category tips:(NSString *)tips fromAddresses:(NSArray *)fromAddresses currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    
    [self checkWalletAndExcuteBlock:^{
        LuckyPackageRequest *request = [[LuckyPackageRequest alloc] init];
        request.size = size;
        request.amount = amount;
        request.fee = fee;
        request.tips = tips;
        request.typ = type;
        request.category =category;
        request.receiverIdentifier = identifier;
        
        request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
        
        //request and sign、 publish
        [self basePostDataWithData:request.data url:WalletServiceLuckpackage type:TransactionTypeLuckypackage currency:currency complete:complete];
    } complete:complete];
    
}


- (void)sendUrlTransferFromAddresses:(NSArray *)fromAddresses tips:(NSString *)tips amount:(NSInteger)amount fee:(NSInteger)fee currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    
    [self checkWalletAndExcuteBlock:^{
        OutTransfer *request = [[OutTransfer alloc] init];
        request.fee = fee;
        request.amount = amount;
        request.tips = tips;
        
        request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
        
        //request and sign、 publish
        [self basePostDataWithData:request.data url:WalletServiceExternal type:TransactionTypeURLTransfer currency:currency complete:complete];
    } complete:complete];
    
}


- (void)sendCrowdfuningToGroup:(NSString *)groupIdentifier amount:(NSInteger)amount size:(int)size tips:(NSString *)tips complete:(void (^)(Crowdfunding *crowdfunding,NSError *error))complete{
    
    [self checkWalletAndExcuteBlock:^{
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
    } complete:complete];
    
}

- (void)sendReceiptToPayer:(NSString *)payer amount:(NSInteger)amount tips:(NSString *)tips complete:(void (^)(Bill *bill,NSError *error))complete{

    [self checkWalletAndExcuteBlock:^{
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
                    NSError *error = nil;
                    Bill *bill = [Bill parseFromData:data error:&error];
                    if (error || !bill) {
                        if (complete) {
                            complete(nil,error);
                        }
                    } else {
                        if (complete) {
                            complete(bill,nil);
                        }
                    }
                }
            }
        } fail:^(NSError *error) {
            if (complete) {
                complete(nil,error);
            }
        }];
    } complete:complete];
    
}

- (void)payCrowdfuningReceiptWithHashId:(NSString *)hashId type:(TransactionType)type fromAddresses:(NSArray *)fromAddresses fee:(NSInteger)fee currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    
    [self checkWalletAndExcuteBlock:^{
        /// pay crowdfuning
        Payment *request = [[Payment alloc] init];
        
        request.spentCurrency = [self packageCurrencyTxinWithCurrency:currency fromAddresses:fromAddresses];
        request.payType = type;
        request.hashId = hashId;
        request.fee = fee;
        
        //request and sign、 publish
        [self basePostDataWithData:request.data url:WalletServicePay type:type currency:currency complete:complete];
    } complete:complete];
    
}

- (void)transferFromAddresses:(NSArray *)fromAddresses currency:(CurrencyType)currency fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete{
    
    [self checkWalletAndExcuteBlock:^{
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
        [self basePostDataWithData:request.data url:WalletServiceTransferToAddress type:TransactionTypeBill currency:currency complete:complete];
    } complete:complete];
    
}

- (void)transferFromAddresses:(NSArray *)fromAddresses currency:(CurrencyType)currency fee:(NSInteger)fee toConnectUserIds:(NSArray *)userIds perAddressAmount:(NSInteger)perAddressAmount tips:(NSString *)tips complete:(CompleteWithDataBlock)complete{
    
    [self checkWalletAndExcuteBlock:^{
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
        [self basePostDataWithData:request.data url:WalletServiceTransferInConnect type:TransactionTypeBill currency:currency complete:complete];
    } complete:complete];

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

- (void)signRawTransactionAndPublishWihtOriginalTransaction:(OriginalTransaction *)originalTransaction transactionType:(TransactionType)transactionType currency:(CurrencyType)currency category:(CategoryType)category seed:(NSString *)seed complete:(CompleteWithDataBlock)complete{

    LMBaseAddressManager *addressManager = [[LMBtcAddressManager alloc] init];
    [addressManager syncAddressListWithInputInputs:originalTransaction.addressesArray complete:^(NSError *error) {
        if (error) {
            if (complete) {
                complete(nil,error);
            }
        } else {
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
            NSString *signTransaction = [currencyManager signRawTranscationWithTvs:originalTransaction.vts category:category rawTranscation:originalTransaction.rawhex inputs:originalTransaction.addressesArray seed:seed];
            if (GJCFStringIsNull(originalTransaction.hashId)) {
                if (complete) {
                    complete(nil,[NSError errorWithDomain:@"argu error" code:TransactionPackageErrorArguError userInfo:nil]);
                }
                return ;
            }
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
                OriginalTransactionResponse *oriTransactionResp = [OriginalTransactionResponse parseFromData:data error:&error];
                if (!error) {
                    switch (oriTransactionResp.code) {
                        case TransactionPackageErrorSuccess:{
                            [self verfiyWithOriginTransactionResp:oriTransactionResp type:type currency:currency complete:complete];
                        }
                            break;
                        case TransactionPackageErrorTypeFeeEmpty:
                        case TransactionPackageErrorTypeUnspentTooLarge:
                        case TransactionPackageErrorTypeUnspentError:
                        case TransactionPackageErrorTypeUnspentNotEnough:
                        case TransactionPackageErrorTypeOutDust:{
                            if (complete) {
                                complete(nil,[NSError errorWithDomain:oriTransactionResp.message code:oriTransactionResp.code userInfo:nil]);
                            }
                        }
                            break;
                        case TransactionPackageErrorTypeFeeToolarge:{
                            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                            if (data) {
                                NSError *error = nil;
                                OriginalTransactionResponse *oriTransactionResp = [OriginalTransactionResponse parseFromData:data error:&error];
                                NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Wallet Auto fees is greater than the maximum set maximum and continue", nil),
                                                  [PayTool getBtcStringWithAmount:oriTransactionResp.data_p.estimateFee]];
                                [self askUserNeedContinueTransferWithTips:tips originTransactionResp:oriTransactionResp type:type currency:currency complete:complete];
                            }
                        }
                            break;
                        case TransactionPackageErrorTypeFeeSamll:{
                            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                            if (data) {
                                NSError *error = nil;
                                OriginalTransactionResponse *oriTransactionResp = [OriginalTransactionResponse parseFromData:data error:&error];
                                NSString *tips = LMLocalizedString(@"Wallet Transaction fee too low Continue", nil);
                                [self askUserNeedContinueTransferWithTips:tips originTransactionResp:oriTransactionResp type:type currency:currency complete:complete];
                            }
                        }
                            break;
                        case TransactionPackageErrorTypeChangeDust:{
                            NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                            if (data) {
                                NSError *error = nil;
                                OriginalTransactionResponse *oriTransactionResp = [OriginalTransactionResponse parseFromData:data error:&error];
                                NSString *tips = [NSString stringWithFormat:LMLocalizedString(@"Wallet Charge small calculate to the poundage", nil),
                                                  [PayTool getBtcStringWithAmount:oriTransactionResp.data_p.oddChange]];
                                [self askUserNeedContinueTransferWithTips:tips originTransactionResp:oriTransactionResp type:type currency:currency complete:complete];
                            }
                        }
                            break;
                        default:
                            break;
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

- (void)askUserNeedContinueTransferWithTips:(NSString *)tips originTransactionResp:(OriginalTransactionResponse *)oriTransactionResp type:(TransactionType)type currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    UIViewController *controller = [UIViewController currentViewController];
    
    [UIAlertController showAlertInViewController:controller withTitle:LMLocalizedString(@"Set tip title", nil) message:tips cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common Cancel", nil), LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
        switch (buttonIndex) {
            case 2:
            {
                if (complete) {
                    complete(nil,[NSError errorWithDomain:@"cancel" code:TransactionPackageErrorTypeCancel userInfo:nil]);
                }
            }
                break;
            case 3:
            {
                [self verfiyWithOriginTransactionResp:oriTransactionResp type:type currency:currency complete:complete];
            }
                break;
            default:
                break;
        }
    }];
}

- (void)verfiyWithOriginTransactionResp:(OriginalTransactionResponse *)oriTransactionResp type:(TransactionType)type currency:(CurrencyType)currency complete:(CompleteWithDataBlock)complete{
    /// password verfiy --- encrypt seed
    [InputPayPassView inputPayPassWithOrderDetail:oriTransactionResp.data_p currency:currency complete:^(CategoryType category,NSString *decodeValue, InputPayPassView *passView) {
        if (decodeValue) {
            /// sign and publish
            [self signRawTransactionAndPublishWihtOriginalTransaction:oriTransactionResp.data_p transactionType:type currency:currency category:category seed:decodeValue complete:^(id data, NSError *signError) {
                if (passView.requestCallBack) {
                    passView.requestCallBack(signError);
                }
                if (complete) {
                    complete(data,signError);
                }
            }];
        }
    } closeBlock:^{
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"cancel" code:TransactionPackageErrorTypeCancel userInfo:nil]);
        }
    }];
}

- (void)checkWalletAndExcuteBlock:(void(^)())excuteBlock complete:(CompleteWithDataBlock)complete{
    /// check or ceateWallet
    [[LMWalletManager sharedManager] checkWalletExistAndCreateWalletWithBlock:^(BOOL existWallet) {
        if (existWallet) {
            if (excuteBlock) {
                excuteBlock();
            }
        } else {
            if (complete) {
                complete(nil,[NSError errorWithDomain:@"cancel" code:TransactionPackageErrorTypeCancel userInfo:nil]);
            }
        }
    }];
}

@end
