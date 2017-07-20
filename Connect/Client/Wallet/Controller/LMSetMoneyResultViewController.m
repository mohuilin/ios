//
//  LMSetMoneyResultViewController.m
//  Connect
//
//  Created by Edwin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMSetMoneyResultViewController.h"
#import "WallteNetWorkTool.h"
#import "NSString+Size.h"
#import "MessageDBManager.h"
#import "LMPayCheck.h"

@interface LMSetMoneyResultViewController ()
@property(nonatomic, strong) UIButton *rateChangeButton;
@property(nonatomic, strong) UIImageView *userImageView;
@property(nonatomic, strong) UILabel *usernameLabel;
@property(nonatomic, strong) UILabel *bitNumLabel;
// money blance
@property(nonatomic, strong) UILabel *BalanceLabel;
// transfer button
@property(nonatomic, strong) TransferButton *transferBtn;

@property(nonatomic, assign) BOOL btcAmount;

@end

@implementation LMSetMoneyResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    // data
    NSString *curency = [[MMAppSetting sharedSetting] getcurrency];
    NSArray *temA = [curency componentsSeparatedByString:@"/"];
    if (temA.count == 2) {
        self.code = [temA firstObject];
        self.symbol = [temA lastObject];
    }

    self.title = LMLocalizedString(@"Wallet Transfer", nil);
    [self initUserInfomation];
    [self initTabelViewCell];
}

- (void)initUserInfomation {
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(319), AUTO_HEIGHT(30) + 64, AUTO_WIDTH(112), AUTO_WIDTH(112))];
    [self.userImageView setPlaceholderImageWithAvatarUrl:self.info.avatar];
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(40), CGRectGetMaxY(self.userImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(80), AUTO_HEIGHT(40))];
    self.usernameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer To User", nil), _info.username];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.usernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.usernameLabel];

    self.bitNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(150), CGRectGetMaxY(self.usernameLabel.frame) + AUTO_HEIGHT(50), VSIZE.width - AUTO_WIDTH(300), AUTO_HEIGHT(80))];
    self.bitNumLabel.text = [NSString stringWithFormat:@"฿%@", self.trasferAmount.stringValue];
    self.bitNumLabel.font = [UIFont systemFontOfSize:FONT_SIZE(64)];
    self.bitNumLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.bitNumLabel];

    self.rateChangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rateChangeButton.backgroundColor = [UIColor colorWithHexString:@"B3B5BD"];
    self.rateChangeButton.titleLabel.textColor = [UIColor whiteColor];
    self.rateChangeButton.titleLabel.textAlignment = NSTextAlignmentRight;
    self.rateChangeButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.rateChangeButton.layer.cornerRadius = 3;
    self.rateChangeButton.layer.masksToBounds = YES;
    [self.rateChangeButton addTarget:self action:@selector(exChangeRate:) forControlEvents:UIControlEventTouchUpInside];
    [self.rateChangeButton setTitle:[NSString stringWithFormat:@"%@ %.8f", self.symbol, [[MMAppSetting sharedSetting] getRate] * self.trasferAmount.doubleValue] forState:UIControlStateNormal];
    CGSize size = [self.rateChangeButton.titleLabel.text sizeWithFont:self.rateChangeButton.titleLabel.font constrainedToWidth:DEVICE_SIZE.width];
    self.rateChangeButton.frame = CGRectMake(0, CGRectGetMaxY(self.bitNumLabel.frame) + AUTO_HEIGHT(20), size.width + 20, AUTO_HEIGHT(70));
    self.rateChangeButton.centerX = self.view.centerX;
    [self.view addSubview:self.rateChangeButton];
}


- (void)initTabelViewCell {

    self.BalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.rateChangeButton.frame) + AUTO_HEIGHT(30), VSIZE.width, AUTO_HEIGHT(100))];
    self.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getAvaliableAmount]]];
    self.BalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
    self.BalanceLabel.textColor = [UIColor blackColor];
    self.BalanceLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.BalanceLabel];
    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        weakSelf.blance = unspentAmount.avaliableAmount;
        weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
    }];

    // transfer button
    self.transferBtn = [[TransferButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Transfer", nil) disableTitle:LMLocalizedString(@"Wallet Transfer", nil)];
    self.transferBtn.frame = CGRectMake(AUTO_WIDTH(30), CGRectGetMaxY(self.BalanceLabel.frame) + AUTO_HEIGHT(157), VSIZE.width - AUTO_WIDTH(60), AUTO_HEIGHT(100));
    self.transferBtn.layer.cornerRadius = 3;
    self.transferBtn.layer.masksToBounds = YES;
    [self.transferBtn addTarget:self action:@selector(transferBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.transferBtn];

}

- (IBAction)exChangeRate:(id)sender {
    if (self.btcAmount) {
        self.bitNumLabel.text = [NSString stringWithFormat:@"%@ %.8f", self.symbol, [[MMAppSetting sharedSetting] getRate] * self.trasferAmount.doubleValue];
        [self.rateChangeButton setTitle:[NSString stringWithFormat:@"฿ %.8f", self.trasferAmount.doubleValue] forState:UIControlStateNormal];
        self.btcAmount = NO;
    } else {
        self.bitNumLabel.text = [NSString stringWithFormat:@"฿ %.8f", self.trasferAmount.doubleValue];
        [self.rateChangeButton setTitle:[NSString stringWithFormat:@"%@ %.8f", self.symbol, [[MMAppSetting sharedSetting] getRate] * self.trasferAmount.doubleValue] forState:UIControlStateNormal];
        self.btcAmount = YES;
    }

    [self.bitNumLabel sizeToFit];
    [self.rateChangeButton.titleLabel sizeToFit];
}


- (void)transferBtnClick:(UIButton *)btn {
    self.comfrimButton.enabled = NO;
    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    [[LMTransferManager sharedManager] transferFromAddresses:nil currency:CurrencyTypeBTC fee:0 toAddresses:@[self.info.address] perAddressAmount:[PayTool getPOW8Amount:self.trasferAmount] tips:nil complete:^(id data, NSError *error) {
        self.comfrimButton.enabled = YES;
        if (error) {
            if (error.code != TransactionPackageErrorTypeCancel) {
                [MBProgressHUD showToastwithText:[LMErrorCodeTool messageWithErrorCode:error.code] withType:ToastTypeFail showInView:self.view complete:nil];
            } else {
                [MBProgressHUD hideHUDForView:self.view];
            }
        } else {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Transfer Successful", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
            [self createChatWithHashId:data address:self.info.address Amount:self.trasferAmount.stringValue];
        }
    }];
}

@end
