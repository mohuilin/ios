//
//  LMPayCheck.h
//  Connect
//
//  Created by Connect on 2017/4/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Protofile.pbobjc.h"
#import "UnSpentInfo.h"
#import "LMBaseViewController.h"


typedef NS_ENUM(NSUInteger,MoneyType) {
    MoneyTypeCommon           = 1 << 0,
    MoneyTypeTransferSmall    = 1 << 1,
    MoneyTypeTransferBig      = 1 << 2,
    MoneyTypeRedSmall         = 1 << 3,
    MoneyTypeRedBig           = 1 << 4
    
};

@interface LMPayCheck : NSObject
/**
 *   Click the relevant button to verify the legitimacy
 *
 */
+ (NSInteger)checkMoneyNumber:(NSDecimalNumber*)number withTransfer:(BOOL)flag;

@end
