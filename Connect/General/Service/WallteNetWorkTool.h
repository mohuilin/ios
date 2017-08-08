//
//  WallteNetWorkTool.h
//  Connect
//
//  Created by MoHuilin on 16/8/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"
#import "Protofile.pbobjc.h"

@interface WallteNetWorkTool : BaseSetViewController

/**
   * Inquire about the details of a transaction
   *
   * @param hashid transaction ID
   * @param complete
 */
+ (void)queryBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,Bill *bill))complete;

/**
   * Obtain the results of all payment
   *
   * @param hashId all raise ID
   * @param complete
 */
+ (void)crowdfuningInfoWithHashID:(NSString *)hashId complete:(void (^)(NSError *erro ,Crowdfunding *crowdInfo))complete;


+ (void)cancelExternalWithHashid:(NSString *)hashid complete:(void (^)(NSError *error))complete;

+ (void)externalTransferHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,ExternalBillingInfos *externalBillInfos))complete;

+ (void)externalRedPacketHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,RedPackageInfos *redPackages))complete;

+ (void)queryOuterBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,ExternalBillingInfo *externalBillingInfo))complete;

@end
