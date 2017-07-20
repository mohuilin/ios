//
//  LMPayCheck.m
//  Connect
//
//  Created by Connect on 2017/4/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMPayCheck.h"

@implementation LMPayCheck

/**
 *   Click the relevant button to verify the legitimacy
 *
 */
+ (NSInteger)checkMoneyNumber:(NSDecimalNumber*)number withTransfer:(BOOL)flag
{
    // All the ratio of the conversion rate by bit currency
    if (flag) {  // transfer
        if (number.doubleValue > MAX_TRANSFER_AMOUNT) {
            return MoneyTypeTransferBig;
        }
        if (number.doubleValue < MIN_TRANSFER_AMOUNT) {
            return MoneyTypeTransferSmall;
        }
        
    }else         // red pack
    {
        if (number.doubleValue > MAX_REDBAG_AMOUNT) {
            return MoneyTypeRedBig;
        }
        if (number.doubleValue < MAX_REDMIN_AMOUNT) {
            return MoneyTypeRedSmall;
        }
    }
    return MoneyTypeCommon;;
}

@end
