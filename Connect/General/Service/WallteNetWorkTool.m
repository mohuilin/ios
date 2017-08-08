//
//  WallteNetWorkTool.m
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "WallteNetWorkTool.h"
#import "LMIMHelper.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"
#import "LMMessageExtendManager.h"

@implementation WallteNetWorkTool



+ (void)queryBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,Bill *bill))complete{
    
    
    BillHashId *bill = [[BillHashId alloc] init];
    bill.hash_p = hashid;

    [NetWorkOperationTool POSTWithUrlString:WallteQueryBillInfoUrl postProtoData:bill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            
            Bill *detailBill = [Bill parseFromData:data error:&error];
            
            if (!error) {
                DDLogInfo(@"%@",detailBill);
                [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:detailBill.status withHashId:detailBill.hash_p];
                if (complete) {
                    complete(nil,detailBill);
                }
            } else{
                error = nil;
                    if (!error) {
                        if (complete) {
                            complete(nil,detailBill);
                        }
                    } else{
                        if (complete) {
                            complete(error,nil);
                        }
                    }
                }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}

+ (void)crowdfuningInfoWithHashID:(NSString *)hashId complete:(void (^)(NSError *erro ,Crowdfunding *crowdInfo))complete{
    
    CrowdfundingInfo *crowIdentifer = [[CrowdfundingInfo alloc] init];
    crowIdentifer.hashId = hashId;
    
    [NetWorkOperationTool POSTWithUrlString:WallteCrowdfuningInfoUrl postProtoData:crowIdentifer.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            Crowdfunding *detailBill = [Crowdfunding parseFromData:data error:&error];
            
            if (!error) {
                // update db
                
                [[LMMessageExtendManager sharedManager]updateMessageExtendPayCount:(int)(detailBill.size - detailBill.remainSize) status:(int)detailBill.status withHashId:detailBill.hashId];
                if (complete) {
                    complete(nil,detailBill);
                }
            } else{
                if (!error) {
                    if (complete) {
                        complete(nil,detailBill);
                    }
                } else{
                    if (complete) {
                        complete(error,nil);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}



+ (void)cancelExternalWithHashid:(NSString *)hashid complete:(void (^)(NSError *error))complete{
    BillHashId *bill = [[BillHashId alloc] init];
    bill.hash_p = hashid;
    [NetWorkOperationTool POSTWithUrlString:ExternalBillCancelUrl postProtoData:bill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else{
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


+ (void)externalTransferHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,ExternalBillingInfos *externalBillInfos))complete{
    History *his = [[History alloc] init];
    his.pageIndex = page;
    his.pageSize = size;
    
    [NetWorkOperationTool POSTWithUrlString:ExternalTransferHistoryUrl postProtoData:his.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
        } else{
            if (complete) {
                NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                if (data) {
                    NSError *error = nil;
                    ExternalBillingInfos *exterBill = [ExternalBillingInfos parseFromData:data error:&error];
                    complete(nil,exterBill);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}

+ (void)externalRedPacketHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,RedPackageInfos *redPackages))complete{
    History *his = [[History alloc] init];
    his.pageIndex = page;
    his.pageSize = size;
    [NetWorkOperationTool POSTWithUrlString:ExternalRedPackageHistoryUrl postProtoData:his.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
        } else{
            if (complete) {
                NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                if (data) {
                    NSError *error = nil;
                    RedPackageInfos *redPackages = [RedPackageInfos parseFromData:data error:&error];
                    complete(nil,redPackages);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}



+ (void)queryOuterBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,ExternalBillingInfo *externalBillingInfo))complete{
    BillHashId *bill = [[BillHashId alloc] init];
    bill.hash_p = hashid;
    
    [NetWorkOperationTool POSTWithUrlString:ExternalBillInfoUrl postProtoData:bill.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil],nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            ExternalBillingInfo *externalBillingInfo = [ExternalBillingInfo parseFromData:data error:&error];

            if (!error) {
                [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:externalBillingInfo.status withHashId:externalBillingInfo.hash_p];
                if (complete) {
                    complete(nil,externalBillingInfo);
                }
            } else{
                if (!error) {
                    if (complete) {
                        complete(nil,externalBillingInfo);
                    }
                } else{
                    if (complete) {
                        complete(error,nil);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error,nil);
        }
    }];
}

@end
