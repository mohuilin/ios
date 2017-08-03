//
//  LMBaseViewController.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import <Accelerate/Accelerate.h>
#import "NetWorkOperationTool.h"
#import "LMMessageExtendManager.h"
#import "UserDBManager.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "LMHistoryCacheManager.h"


@interface LMBaseViewController () <MBProgressHUDDelegate>
@property(nonatomic, copy) NSString *baseRateURL;
// Transfer the completion of the specific operation of the subclass
@property(copy, nonatomic) void (^TransactionComplete)(NSString *hashId, NSError *error);
@end

@implementation LMBaseViewController

#define kTipViewHeight 64.f

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {

}

- (NSString *)baseRateURL {
    if (!_baseRateURL) {
        NSString *currenRate = [[MMAppSetting sharedSetting] getcurrency];
        if ([currenRate isEqualToString:@"usd"]) { // The dollar
            _baseRateURL = DollarExchangeBitRateUrl;
        } else if ([currenRate isEqualToString:@"cny"]) { // RMB
            _baseRateURL = RMBExchangeBitRateUrl;
        } else if ([currenRate isEqualToString:@"rub"]) { // ruble
            _baseRateURL = RubleExchangeBitRateUrl;
        }
    }
    return _baseRateURL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.moneyTypes = [[MMAppSetting sharedSetting] getcurrency];

    self.view.backgroundColor = LMBasicBackgroudGray;
    RegisterNotify(@"changeCurrencyNotification", @selector(currencyChange));
}

- (void)dealloc {
    RemoveNofify;
}

- (void)currencyChange {
    self.code = nil;
    self.symbol = nil;
}


#pragma mark -- Wool glass effect

- (UIImage *)boxblurImage:(UIImage *)image withBlurNumber:(CGFloat)blur {
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int) (blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    CGImageRef img = image.CGImage;
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    // Get data from CGImage
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    // Sets the properties of the object from CGImage
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    inBuffer.data = (void *) CFDataGetBytePtr(inBitmapData);
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    if (pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data, outBuffer.width, outBuffer.height, 8, outBuffer.rowBytes, colorSpace, kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    //clean up CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    free(pixelBuffer);
    CFRelease(inBitmapData);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    return returnImage;
}

#pragma mark -- Display the message

- (void)showWithLoadingLabelText:(NSString *)text andSelTask:(SEL)sel {
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];

    HUD.delegate = self;
    HUD.labelText = text;
    [HUD showWhileExecuting:sel onTarget:self withObject:nil animated:YES];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    for (MBProgressHUD *HUB in self.view.subviews) {
        [HUB removeFromSuperview];
    }
}

#pragma mark --tabbar

- (void)hideTabBar {
    if (self.tabBarController.tabBar.hidden == YES) {
        return;
    }
    UIView *contentView;
    if ([[self.tabBarController.view.subviews objectAtIndexCheck:0] isKindOfClass:[UITabBar class]])
        contentView = [self.tabBarController.view.subviews objectAtIndexCheck:1];
    else
        contentView = [self.tabBarController.view.subviews objectAtIndexCheck:0];
    contentView.frame = CGRectMake(contentView.bounds.origin.x, contentView.bounds.origin.y, contentView.bounds.size.width, contentView.bounds.size.height + self.tabBarController.tabBar.frame.size.height);
    self.tabBarController.tabBar.hidden = YES;

}

- (void)showTabBar {
    if (self.tabBarController.tabBar.hidden == NO) {
        return;
    }
    UIView *contentView;
    if ([[self.tabBarController.view.subviews objectAtIndexCheck:0] isKindOfClass:[UITabBar class]])

        contentView = [self.tabBarController.view.subviews objectAtIndexCheck:1];

    else

        contentView = [self.tabBarController.view.subviews objectAtIndexCheck:0];
    contentView.frame = CGRectMake(contentView.bounds.origin.x, contentView.bounds.origin.y, contentView.bounds.size.width, contentView.bounds.size.height - self.tabBarController.tabBar.frame.size.height);
    self.tabBarController.tabBar.hidden = NO;

}

#pragma mark - Create session

- (void)createChatWithHashId:(NSString *)hashId address:(NSString *)address Amount:(NSString *)amount {
    AccountInfo *user = [[UserDBManager sharedManager] getUserByAddress:address];
    if (user) {
        MMMessage *message = [[MessageDBManager sharedManager] createTransactionMessageWithUserInfo:user hashId:hashId monney:amount];
        // Create a session
        NSString *ecdh = [KeyHandle getECDHkeyUsePrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey PublicKey:user.pub_key];
        [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:user.pub_key groupChat:NO lastContentShowType:1 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:message.type textMessage:message.content] ecdhKey:ecdh talkName:user.normalShowName];
        [[RecentChatDBManager sharedManager] clearUnReadCountWithIdetifier:user.pub_key];
        // Clear unread

        [[IMService instance] asyncSendMessageMessage:message onQueue:nil completion:^(MMMessage *messageInfo, NSError *error) {
            if ([messageInfo.message_id isEqualToString:message.message_id]) {
                // Modify the message sending status
                [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusSuccess withMessageId:message.message_id messageOwer:user.pub_key];
            }
        }                                     onQueue:nil];
        // save transfer
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic safeSetObject:message.message_id forKey:@"message_id"];
        [dic safeSetObject:hashId forKey:@"hashid"];
        [dic safeSetObject:@(1) forKey:@"status"];
        [dic safeSetObject:@(0) forKey:@"pay_count"];
        [dic safeSetObject:@(0) forKey:@"crowd_count"];
        [[LMMessageExtendManager sharedManager] saveBitchMessageExtendDict:dic.copy];
    } else {
        SearchUser *usrAddInfo = [[SearchUser alloc] init];
        usrAddInfo.criteria = address;
        [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
            NSError *error;
            HttpResponse *respon = (HttpResponse *) response;
            if (respon.code == successCode) {
                NSData *data = [ConnectTool decodeHttpResponse:respon];
                if (data) {
                    // User Info
                    UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                    if (error) {
                        return;
                    }
                    AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                    accoutInfo.username = info.username;
                    accoutInfo.avatar = info.avatar;
                    accoutInfo.pub_key = info.pubKey;
                    accoutInfo.address = info.address;
                    accoutInfo.stranger = YES;
                    // creat session
                    [[RecentChatDBManager sharedManager] createNewChatNoRelationShipWihtRegisterUser:accoutInfo];
                    MMMessage *message = [[MessageDBManager sharedManager] createTransactionMessageWithUserInfo:accoutInfo hashId:hashId monney:amount];
                    // save transfer
                    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                    [dic safeSetObject:message.message_id forKey:@"message_id"];
                    [dic safeSetObject:hashId forKey:@"hashid"];
                    [dic safeSetObject:@(1) forKey:@"status"];
                    [dic safeSetObject:@(0) forKey:@"pay_count"];
                    [dic safeSetObject:@(0) forKey:@"crowd_count"];
                    [[LMMessageExtendManager sharedManager] saveBitchMessageExtendDict:dic.copy];
                }
            } else {
                [MBProgressHUD showToastwithText:respon.message withType:ToastTypeFail showInView:self.view complete:nil];
            }
        }                                  fail:^(NSError *error) {
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeWallet withErrorCode:error.code withUrl:ContactUserSearchUrl] withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }
}

- (NSString *)symbol {
    if (!_symbol) {
        NSString *curency = [[MMAppSetting sharedSetting] getcurrency];
        NSArray *temA = [curency componentsSeparatedByString:@"/"];
        if (temA.count == 2) {
            _code = [temA firstObject];
            _symbol = [temA lastObject];
        }
    }
    return _symbol;
}


- (NSString *)code {
    if (!_code) {
        NSString *curency = [[MMAppSetting sharedSetting] getcurrency];
        NSArray *temA = [curency componentsSeparatedByString:@"/"];
        if (temA.count == 2) {
            _code = [temA firstObject];
            _symbol = [temA lastObject];
        }
    }
    return _code;
}

- (long long)blance {
    if (_blance <= 0) {
        _blance = [[LMWalletManager sharedManager] currencyModelWith:CurrencyTypeBTC].blance;
    }
    return _blance;
}

- (NSString *)blanceString {
    return [NSString stringWithFormat:@"%f", self.blance * pow(10, -8)];
}

- (UILabel *)errorTipLabel {
    if (!_errorTipLabel) {
        _errorTipLabel = [[UILabel alloc] init];
        _errorTipLabel.backgroundColor = [UIColor redColor];
        _errorTipLabel.textColor = [UIColor whiteColor];
        _errorTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(29)];
        _errorTipLabel.alpha = 0;
        _errorTipLabel.textAlignment = NSTextAlignmentCenter;
        _errorTipLabel.text = LMLocalizedString(@"Wallet No more than group members", nil);
        _errorTipLabel.frame = CGRectMake(0, 0, DEVICE_SIZE.width, AUTO_HEIGHT(100));
        _errorTipLabel.bottom = 64;
    }
    return _errorTipLabel;
}

@end
