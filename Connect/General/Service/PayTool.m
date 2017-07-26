//
//  PayTool.m
//  Connect
//
//  Created by MoHuilin on 16/9/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PayTool.h"
#import "WallteNetWorkTool.h"
#import "WJTouchID.h"
#import "NetWorkOperationTool.h"
#import "NSString+DictionaryValue.h"
#import "LMWalletManager.h"
#import "LMBaseCurrencyManager.h"
#import "LMBtcCurrencyManager.h"

@interface PayTool()<WJTouchIDDelegate,KQXPasswordInputControllerDelegate>

@property (nonatomic ,copy) void (^VerfifyComplete)(BOOL result,NSString *errorMsg);

@property (nonatomic ,copy) NSString *baseRateURL;

@end

@implementation PayTool

+ (instancetype)sharedInstance
{
    static PayTool* instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [PayTool new];
    });

    return instance;
}

- (instancetype)init{
    if (self = [super init]) {
        RegisterNotify(@"changeCurrencyNotification", @selector(currencyChange));
    }
    return self;
}

- (void)dealloc{
    RemoveNofify;
}

- (void)currencyChange{
    self.baseRateURL = nil;
}

- (NSString *)symbol{
    NSString *currency = [[MMAppSetting sharedSetting] getcurrency];
    return [[currency componentsSeparatedByString:@"/"] lastObject];
}

- (NSString *)code{
    NSString *currenRate = [[MMAppSetting sharedSetting] getcurrency];
    return [currenRate uppercaseString];
}

- (NSString *)baseRateURL {
    if (!_baseRateURL) {
        NSString *currenRate = [[MMAppSetting sharedSetting] getcurrency];
        if ([currenRate containsString:@"usd"]) { // The dollar
            _baseRateURL = DollarExchangeBitRateUrl;
        } else if ([currenRate containsString:@"cny"]) { // RMB
            _baseRateURL = RMBExchangeBitRateUrl;
        } else if ([currenRate containsString:@"rub"]) { // ruble
            _baseRateURL = RubleExchangeBitRateUrl;
        }
    }
    return _baseRateURL;
}

- (void)getRateComplete:(void (^)(NSDecimalNumber *rate,NSError *error))complete {
	[NetWorkOperationTool GETWithUrlString:self.baseRateURL complete:^(id response) {
        if ([response isKindOfClass:[NSString class]]) {
            NSDictionary *dict = [response dictionaryValue];
            if (complete) {
                NSDecimalNumber *r = [[NSDecimalNumber alloc] initWithFloat:[[dict valueForKey:@"rate"] floatValue]];
                [[MMAppSetting sharedSetting] saveRate:r.doubleValue];
                complete(r,nil);
            } else{
                complete(nil,[NSError errorWithDomain:@"Conversion failed" code:-1 userInfo:nil]);
            }
        }
    } fail:^(NSError *error) {
        double rate = [[MMAppSetting sharedSetting] getRate];
        NSDecimalNumber *r = [[NSDecimalNumber alloc] initWithFloat:rate];
        if (r.doubleValue > 0) {
            complete(r,nil);
        } else{
            complete(nil,error);
        }
    }];
}




- (void)getBlanceWithComplete:(void (^)(NSString *blance,UnspentAmount *unspentAmount,NSError *error))complete {
    
    
    LMBaseCurrencyManager *currencyManager = nil;
    switch ([LMWalletManager sharedManager].presentCurrency) {
        case CurrencyTypeBTC:
        {
            currencyManager = [[LMBtcCurrencyManager alloc] init];
        }
            break;
            
        default:
            break;
    }
    [currencyManager syncCurrencyDetailWithComplete:^(LMCurrencyModel *currencyModel, NSError *error) {
        if (!error) {
            [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
                if (!error) {
                    UnspentAmount *unspentAmount = [UnspentAmount new];
                    unspentAmount.amount = currencyModel.amount;
                    unspentAmount.avaliableAmount = currencyModel.blance;
                    
                    NSDecimalNumber *deciNum = [[NSDecimalNumber alloc] initWithLong:unspentAmount.amount];
                    NSDecimalNumber *change = [[NSDecimalNumber alloc] initWithLong:pow(10, 8)];
                    NSDecimalNumber *blanceNum = [deciNum decimalNumberByDividingBy:change];
                    complete(blanceNum.stringValue,unspentAmount,error);
                } else {
                    NSDecimalNumber *deciNum = [[NSDecimalNumber alloc] initWithLong:[[LMWalletManager sharedManager] currencyModelWith:[LMWalletManager sharedManager].presentCurrency].amount];
                    NSDecimalNumber *change = [[NSDecimalNumber alloc] initWithLong:pow(10, 8)];
                    NSDecimalNumber *blanceNum = [deciNum decimalNumberByDividingBy:change];
                    UnspentAmount *unspentAmount = [UnspentAmount new];
                    unspentAmount.amount = [[LMWalletManager sharedManager] currencyModelWith:[LMWalletManager sharedManager].presentCurrency].amount;
                    unspentAmount.avaliableAmount = [[LMWalletManager sharedManager] currencyModelWith:[LMWalletManager sharedManager].presentCurrency].blance;
                    complete(blanceNum.stringValue,unspentAmount,error);
                }
            }];
        } else {
            NSDecimalNumber *deciNum = [[NSDecimalNumber alloc] initWithLong:[[LMWalletManager sharedManager] currencyModelWith:[LMWalletManager sharedManager].presentCurrency].amount];
            NSDecimalNumber *change = [[NSDecimalNumber alloc] initWithLong:pow(10, 8)];
            NSDecimalNumber *blanceNum = [deciNum decimalNumberByDividingBy:change];
            UnspentAmount *unspentAmount = [UnspentAmount new];
            unspentAmount.amount = [[LMWalletManager sharedManager] currencyModelWith:[LMWalletManager sharedManager].presentCurrency].amount;
            unspentAmount.avaliableAmount = [[LMWalletManager sharedManager] currencyModelWith:[LMWalletManager sharedManager].presentCurrency].blance;
            complete(blanceNum.stringValue,unspentAmount,error);
        }
    }];
}


- (void)payVerfifyFingerWithComplete:(void (^)(BOOL result,NSString *errorMsg))complete{
    
    // Free payment
    if ([[MMAppSetting sharedSetting] isCanNoPassPay]) {
        if(complete){
            complete(YES,nil);
        }
    }else {
        // Fingerprint payment
        if ([[MMAppSetting sharedSetting] needFingerPay]) {
            self.VerfifyComplete = complete;
            [[WJTouchID touchID] startWJTouchIDWithMessage:LMLocalizedString(@"Wallet Finger pay", nil) fallbackTitle:LMLocalizedString(@"Login Password", nil) delegate:self];
        }else {
            if (complete) {
                complete(NO,nil);
            }
        }
    }
}
- (void)openFingerPayComplete:(void (^)(BOOL result))complete{
    [[WJTouchID touchID] startWJTouchIDWithMessage:LMLocalizedString(@"Wallet Allow fingerprint to pay", nil) fallbackTitle:LMLocalizedString(@"Common OK", nil) delegate:self];
}

+ (NSString *)getBtcStringWithAmount:(long long)amount{
    if (amount == 0) {
        return @"0.00000000";
    }
    //http://www.cnblogs.com/denz/p/5330771.html
    NSDecimalNumberHandler *roundUp = [NSDecimalNumberHandler
                                       decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                       scale:8
                                       raiseOnExactness:NO
                                       raiseOnOverflow:NO
                                       raiseOnUnderflow:NO
                                       raiseOnDivideByZero:YES];
    NSDecimalNumber *smallAmount = [[[NSDecimalNumber alloc] initWithLongLong:amount] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)] withBehavior:roundUp];
    NSString *smallAmountString = smallAmount.stringValue;
    if ([smallAmountString containsString:@"."]) {
        int len = 8 -(int)[[smallAmountString componentsSeparatedByString:@"."] lastObject].length;
        if (len > 0) {
            while (len) {
                smallAmountString = [smallAmountString stringByAppendingString:@"0"];
                len --;
            }
        }
    } else{
        smallAmountString = [NSString stringWithFormat:@"%@.00000000",smallAmountString];
    }
    return smallAmountString;
}

+ (NSString *)getBtcStringWithDecimalAmount:(NSDecimalNumber *)amount{
    //http://www.cnblogs.com/denz/p/5330771.html
    NSDecimalNumberHandler *roundUp = [NSDecimalNumberHandler
                                       decimalNumberHandlerWithRoundingMode:NSRoundDown
                                       scale:8
                                       raiseOnExactness:NO
                                       raiseOnOverflow:NO
                                       raiseOnUnderflow:NO
                                       raiseOnDivideByZero:YES];
    NSDecimalNumber *smallAmount = [amount decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)] withBehavior:roundUp];
    NSString *smallAmountString = smallAmount.stringValue;
    return smallAmountString;
}


+ (long long)getPOW8AmountWithText:(NSString *)amountText{
    if (GJCFStringIsNull(amountText)) {
        return 0;
    }
    NSDecimalNumber *numA = [NSDecimalNumber decimalNumberWithString:amountText];
    return  [[numA decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]] longLongValue];
}

+ (long long)getPOW8Amount:(NSDecimalNumber *)amount{
    return  [[amount decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]] longLongValue];
}

+ (float)getSmallAmount:(NSDecimalNumber *)amount{
    return  [amount floatValue];
}

+ (float)getDiviPow8SmallAmount:(NSDecimalNumber *)amount{
    return  [[amount decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]] floatValue];
}




#pragma mark - KQXPasswordInputControllerDelegate
- (void)passwordInputControllerDidClosed{
    self.VerfifyComplete(NO,@"NO");
}

- (void)passwordInputControllerDidDismissed{
}

#pragma mark - WJTouchIDDelegate
/**
   * TouchID validation is successful
   *
   * Authentication Successul Authorize Success
 */
- (void) WJTouchIDAuthorizeSuccess {
    DDLogInfo(@"%@",WJNotice(@"TouchID validation is successful", @"Authorize Success"));
    
    if (self.VerfifyComplete) {
        self.VerfifyComplete(YES,nil);
    }
}

/**
   * TouchID validation failed
   *
   * Authentication Failure
 */
- (void) WJTouchIDAuthorizeFailure {
    DDLogInfo(@"%@",WJNotice(@"TouchID validation failed", @"Authorize Failure"));
    
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
    
}
/**
   * Cancel TouchID verification (user clicked to cancel)
   *
   * Authentication was canceled by user (e.g. tapped Cancel button).
 */
- (void) WJTouchIDAuthorizeErrorUserCancel {
    
    DDLogInfo(@"%@",WJNotice(@"Cancel TouchID verification (user clicked to cancel)", @"Authorize Error User Cancel"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,@"NO");
    }
    
}

/**
   * Click the Enter Password button in the TouchID dialog box
   *
   * User tapped the fallback button
 */
- (void) WJTouchIDAuthorizeErrorUserFallback {
    DDLogInfo(@"%@",WJNotice(@"In the TouchID dialog box, click the Enter Password button", @"Authorize Error User Fallback "));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,@"pass");
    }
}

/**
   * In the process of verification of the TouchID was canceled by the system, for example, suddenly call, press the Home button, lock screen ...
   *
   * Authentication was canceled by system (e.g. another application went to foreground).
 */
- (void) WJTouchIDAuthorizeErrorSystemCancel {
    DDLogInfo(@"%@",WJNotice(@"In the process of verifying the TouchID was canceled by the system ", @"Authorize Error System Cancel"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,@"NO");
    }
    
}

/**
   * TouchID can not be enabled and the device does not have a password set
   *
   * Authentication could not start, because passcode is not set on the device.
 */
- (void) WJTouchIDAuthorizeErrorPasscodeNotSet {
    DDLogInfo(@"%@",WJNotice(@"Can not enable TouchID, the device does not have a password set", @"Authorize Error Passcode Not Set"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
    
}

/**
   * The device does not have a TouchID entered, and TouchID can not be enabled
   *
   * Authentication could not start, because Touch ID has no enrolled fingers
 */
- (void) WJTouchIDAuthorizeErrorTouchIDNotEnrolled {
    DDLogInfo(@"%@",WJNotice(@"The device does not have a TouchID entered, and TouchID can not be enabled", @"Authorize Error TouchID Not Enrolled"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
    
}

/**
   * The device's TouchID is invalid
   *
   * Authentication could not start, because Touch ID is not available on thedevice.
 */
- (void) WJTouchIDAuthorizeErrorTouchIDNotAvailable {
    DDLogInfo(@"%@",WJNotice(@"The device's TouchID is invalid", @"Authorize Error TouchID Not Available"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
}

/**
   * Touch ID failed multiple times, Touch ID is locked, you need to enter the user password unlock
   *
   * Authentication was not successful, because there were too many failed Touch ID attempts and Touch ID is now locked. Passcode is required to unlock Touch ID, e.g. visit LAPolicyDeviceOwnerAuthenticationWithBiometrics will ask for passcode as a prerequisite.
 *
 */
- (void) WJTouchIDAuthorizeLAErrorTouchIDLockout {
    DDLogInfo(@"%@",WJNotice(@"Repeatedly used Touch ID failed, Touch ID is locked, requires the user to enter the password to unlock", @"Authorize LAError TouchID Lockout"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
    
}

/**
   * The current software is suspended to cancel the authorization (such as a sudden call, the application into the front desk)
   *
   * Authentication was canceled by application (e.g. invalidate was called while while was inprogress).
 *
 */
- (void) WJTouchIDAuthorizeLAErrorAppCancel {
    DDLogInfo(@"%@",WJNotice(@"The current software was suspended to cancel the authorization", @"Authorize LAError AppCancel"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
    
}

/**
   * The current software was suspended to cancel the authorization (the LAContext object was released during authorization)
   *
   * LAContext passed to this call has been previously invalidated.
 */
- (void) WJTouchIDAuthorizeLAErrorInvalidContext {
    DDLogInfo(@"%@",WJNotice(@"The current software was suspended to cancel the authorization", @"Authorize LAError Invalid Context"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
    
}
/**
   * The current device does not support fingerprint identification
   *
   * The current device does not support fingerprint identification
 */
-(void)WJTouchIDIsNotSupport {
    DDLogInfo(@"%@",WJNotice(@"The current device does not support fingerprint recognition", @"The Current Device Does Not Support"));
    if (self.VerfifyComplete) {
        self.VerfifyComplete(NO,nil);
    }
}


@end
