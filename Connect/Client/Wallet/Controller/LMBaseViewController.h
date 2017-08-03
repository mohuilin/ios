//
//  LMBaseViewController.h
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BitcoinInfo.h"
#import "BaseViewController.h"
#import "PayTool.h"
#import "TransferButton.h"
#import "InputPayPassView.h"
#import "PaySetPage.h"
#import "UIAlertController+Blocks.h"
#import "ConnectButton.h"
#import "LMTransferManager.h"

typedef void (^baseBitRequestInfoComplete)(BOOL complete, BitcoinInfo *info);

typedef void (^baseRMBRateRequestComplete)(BOOL complete, float rate, NSString *code, NSString *symbol);

typedef void (^baseRequestErrorBlock)(NSError *__autoreleasing error);

typedef void (^bitRatoComplete)(BOOL isSuccess, NSString *rate);

typedef void (^trasferComplete)();


@interface LMBaseViewController : BaseViewController

@property(nonatomic, strong) NSArray *vtsArray; // enter
@property(nonatomic, copy) NSString *rawTransaction; // Original transaction


@property(nonatomic, assign) float rate;

@property(nonatomic, copy) NSString *rateCode; // symbol

@property(nonatomic, strong) AccountInfo *ainfo;

@property(nonatomic, strong) BitcoinInfo *bitInfo;
@property(nonatomic, strong) KQXPasswordInputController *passwordInputVC;
@property(nonatomic, copy) NSString *moneyTypes;
@property(nonatomic, copy) bitRatoComplete complete;

@property(nonatomic, copy) trasferComplete trasferComplete;

@property(nonatomic, assign) long long blance; // Account Balance
@property(nonatomic, copy) NSString *blanceString; // Account balance string, interface display
@property(nonatomic, copy) NSString *code; //
@property(nonatomic, copy) NSString *symbol; //


@property(nonatomic, strong) UILabel *errorTipLabel; // Error message
/**
 *  Unified tool class approach
 */
// In order to change the new table, the button position changes
@property(nonatomic, strong) ConnectButton *comfrimButton;

/**
 *  Currency symbol changes the notification method, you need to call the parent class method
 */
- (void)currencyChange;

/**
 *   hide tabbar
 */
- (void)showTabBar;

/**
 *  display tabbar
 */
- (void)hideTabBar;


/**
 *  creat transfer
 */
- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note;

/**
 *  Get exchange rate
 */
- (void)showWithLoadingLabelText:(NSString *)text andSelTask:(SEL)sel;

- (void)createChatWithHashId:(NSString *)hashId address:(NSString *)address Amount:(NSString *)amount;

@end
