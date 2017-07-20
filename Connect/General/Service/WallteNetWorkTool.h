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
   * Check before the payment and generate the original transaction method
   *
   * @param address The payment address is usually the address of the login account
   * @ Param fee is paid by [MMAppSetting getfee]
   * @param toAddresses Receipt Address, Format @ [@ {@ "address": @ "15GMqiYV33n514JFiucW4hv6GhmpPEYBB3", @ "amount": @ (0.00007)},
                                          @ @ "Address": @ "15GMqiYV33n514JFiucW4hv6GhmpPEYBB3", @ "amount": @ (0.0009)}]
   * @param complete the original transaction string and error message to generate the original transaction successfully, the error message is nil
 */
+ (void)unspentWithAddress:(NSString *)address fee:(double)fee toAddress:(NSArray *)toAddresses createRawTranscationComplete:(void (^)(NSArray *vtsArray, NSString *rawTransaction, NSString *errorMsg))complete;



/**
   * Check before the payment and generate the original transaction method
   *
   * @param address The payment address is usually the address of the login account
   * @ Param fee is paid by [MMAppSetting getfee]
   * @param toAddresses Receipt Address, Format @ [@ {@ "address": @ "15GMqiYV33n514JFiucW4hv6GhmpPEYBB3", @ "amount": @ (0.00007)},
   @ @ "Address": @ "15GMqiYV33n514JFiucW4hv6GhmpPEYBB3", @ "amount": @ (0.0009)}]
   * @param complete the original transaction string and error message to generate the original transaction successfully, the error message is nil
 */

+ (void)unspentV2WithAddress:(NSString *)address fee:(long long)fee toAddress:(NSArray *)toAddresses createRawTranscationModelComplete:(void (^)(UnspentOrderResponse *unspent,NSError *error))complete;



/**
   * Check before the payment and generate the original transaction method
   *
   * @param addresses the payment address
   * @param feeValue handling fee is obtained by [MMAppSetting getfee], no charge is returned with server
   * @param toAddresses payment address
   * @param completes 收款地址
 *  @param complete    
 */
+ (void)TrandPackageWithAddresses:(NSArray *)addresses fee:(double)feeValue toAddress:(NSArray *)toAddresses createRawTranscationComplete:(void (^)(NSArray *vtsArray, NSString *rawTransaction, NSString *errorMsg))complete;


/**
   * Inquire about the details of a transaction
   *
   * @param hashid transaction ID
   * @param complete
 */
+ (void)queryBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,Bill *bill))complete;


/**
   * Check the balance of an address
   *
   * @param address
   * @param complete amount required when the interface is displayed * pow (10,8)
 */
+ (void)queryAmountByAddress:(NSString *)address complete:(void (^)(NSError *erro ,long long int amount, NSString *errorMsg))complete;


+ (void)queryAmountByAddressV2:(NSString *)address complete:(void (^)(NSError *erro ,UnspentAmount *unspentAmount))complete;


/**
   * Obtain the results of all payment
   *
   * @param hashId all raise ID
   * @param complete
 */
+ (void)crowdfuningInfoWithHashID:(NSString *)hashId complete:(void (^)(NSError *erro ,Crowdfunding *crowdInfo))complete;

/**
   * Initiate all
   *
   * @param groupid group ID
   * @param totalAmount the amount of money received
   The number of payers
   * @param tips tips
 *  @param complete    
 */
+ (void)createCrowdfuningBillWithGroupId:(NSString *)groupid totalAmount:(long long int)totalAmount size:(int)size tips:(NSString *)tips complete:(void (^)(NSError *erro,NSString *hashId))complete;

+ (void)getPendingInfoComplete:(void (^)(PendingPackage *pendRedBag ,NSError *error))complete;

+ (void)cancelExternalWithHashid:(NSString *)hashid complete:(void (^)(NSError *error))complete;

+ (void)externalTransferHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,ExternalBillingInfos *externalBillInfos))complete;

+ (void)externalRedPacketHistoryWithPageIndex:(int)page size:(int)size complete:(void (^)(NSError *error,RedPackageInfos *redPackages))complete;

+ (void)queryOuterBillInfoWithTransactionhashId:(NSString *)hashid complete:(void (^)(NSError *erro ,ExternalBillingInfo *externalBillingInfo))complete;

@end
