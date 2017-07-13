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
#import "NetWorkOperationTool.h"

@implementation LMBTCTransferManager

CREATE_SHARED_MANAGER(LMBTCTransferManager)

- (void)sendLuckyPackageWithTotal:(int)total amount:(NSInteger)amount fee:(NSInteger)fee amountType:(LuckypackageAmountType)amountType luckyPackageType:(LuckypackageType)luckyPackageType indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    LuckyPackageRequest *request = [[LuckyPackageRequest alloc] init];
    request.total = total;
    request.amount = amount;
    request.fee = fee;
    request.allotType = amountType;
    request.packageType = luckyPackageType;
    request.addressesArray = fromAddresses;
    /// send luckypackage
    [NetWorkOperationTool POSTWithUrlString:nil postProtoData:request.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            OriginalTransaction *oriTransaction = [OriginalTransaction parseFromData:data error:&error];
        }
    } fail:^(NSError *error) {
        
    }];
    /// input password
    
    /// sign and publish
}


- (void)sendUrlTransferAmount:(NSInteger)amount fee:(NSInteger)fee indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    
    /// send url transfer
    
    
    /// input password
    
    /// sign and publish
}


- (void)sendCrowdfuningAmount:(NSInteger)amount total:(int)total complete:(void (^)(NSString *txId,NSError *error))complete{
    /// send crowdfuning
}

- (void)payCrowdfuningWithTxId:(NSString *)txId indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    /// pay crowdfuning
}

- (void)transferFromAddress:(NSArray *)addresses fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(void (^)(NSArray *,NSString * ,NSError *))complete{
    
}

- (void)transferFromIndexes:(NSArray *)indexes fee:(NSInteger)fee toAddresses:(NSArray *)toAddresses perAddressAmount:(NSInteger)perAddressAmount complete:(CompleteBlock)complete{
    NSArray *fromAddresses = [self addressesFromIndexes:indexes];
    [self transferFromAddress:fromAddresses fee:fee toAddresses:toAddresses perAddressAmount:perAddressAmount complete:^(NSArray *vtsArray,NSString *rawTransaction, NSError *rawTransactionError) {
        if (!rawTransactionError) {
            /// password verfiy --- encrypt seed
            [InputPayPassView showInputPayPassWithComplete:^(InputPayPassView *passView, NSError *error, BOOL result) {
                /// sign and publish
                [self signRawTransactionAndPublishTransactionWithRaw:rawTransaction vtsArray:vtsArray seed:@"" indexes:indexes complete:^(NSError *signError) {
                    if (complete) {
                        complete(signError);
                    }
                }];
            }];
        } else {
            if (complete) {
                complete(rawTransactionError);
            }
        }
    }];
}

- (void)signRawTransactionAndPublishTransactionWithRaw:(NSString *)rawTransaction vtsArray:(NSArray *)vtsArray seed:(NSString *)seed indexes:(NSArray *)indexes complete:(CompleteBlock)complete{
    
    /// query btc salt  -> seed - btcseed
    
    NSMutableArray *privkeyArray = [NSMutableArray array];
    for (NSNumber *index in indexes) {
        NSString *inputsPrivkey = [LMBTCWalletHelper getPrivkeyBySeed:seed index:index.intValue];
        if (inputsPrivkey) {
            [privkeyArray addObject:inputsPrivkey];
        }
    }
    NSString *signTransaction = [LMBTCWalletHelper signRawTranscationWithTvsArray:vtsArray privkeys:privkeyArray rawTranscation:rawTransaction];
    
    /// publish
    DDLogInfo(@"signTransaction %@",signTransaction);
}

#pragma mark - private 

- (NSArray *)addressesFromIndexes:(NSArray *)indexes{
    NSMutableArray *addressArray = [NSMutableArray array];
    NSString *seed = @"";
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
