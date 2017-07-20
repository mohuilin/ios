//
//  LMChatSingleTransferViewController.m
//  Connect
//
//  Created by Edwin on 16/7/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMChatSingleTransferViewController.h"
#import "TransferInputView.h"


@interface LMChatSingleTransferViewController ()
@property(nonatomic, strong) UIImageView *userImageView;
@property(nonatomic, strong) UILabel *usernameLabel;
// money balance
@property(nonatomic, strong) UILabel *BalanceLabel;
@property(nonatomic, strong) BitcoinInfo *binfo;
@property(nonatomic, assign) float accoutMoney;
// money
@property(nonatomic, strong) TransferInputView *inputAmountView;


@end

@implementation LMChatSingleTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak __typeof(&*self) weakSelf = self;

    self.title = LMLocalizedString(@"Wallet Transfer", nil);

    [self addNewCloseBarItem];
    // message
    [self initUserInfomation];
    // transfer money
    [self initTopView];
    // packet money
    [self initTabelViewCell];

    self.ainfo = [[LKUserCenter shareCenter] currentLoginUser];

    self.trasferComplete = ^{
        [GCDQueue executeInMainQueue:^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    };

}

- (void)initUserInfomation {
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(319), AUTO_HEIGHT(30) + 64, AUTO_WIDTH(100), AUTO_WIDTH(100))];
    [self.userImageView setPlaceholderImageWithAvatarUrl:self.info.avatar];
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(100), CGRectGetMaxY(self.userImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(200), AUTO_HEIGHT(40))];
    self.usernameLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer To User", nil), self.info.username];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.usernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.usernameLabel];
}

- (void)initTopView {

    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(AUTO_HEIGHT(20));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    if (self.trasferAmount.doubleValue > 0) {
        view.defaultAmountString = self.trasferAmount.stringValue;
    }
    view.topTipString = LMLocalizedString(@"Wallet Amount", nil);
    view.resultBlock = ^(NSDecimalNumber *btcMoney, NSString *note) {
        [weakSelf createTranscationWithMoney:btcMoney note:note];
    };
    view.lagelBlock = ^(BOOL enabled) {
        weakSelf.comfrimButton.enabled = enabled;
    };
    [[PayTool sharedInstance] getRateComplete:^(NSDecimalNumber *rate, NSError *error) {
        if (!error) {
            weakSelf.rate = rate.floatValue;
            [[MMAppSetting sharedSetting] saveRate:[rate floatValue]];
            [weakSelf.inputAmountView reloadWithRate:rate.floatValue];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Fail to get rate.", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];

    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        int distence = weakSelf.inputAmountView.bottom - (DEVICE_SIZE.height - keyboardFrame.size.height - AUTO_HEIGHT(100));
        [GCDQueue executeInMainQueue:^{
            [UIView animateWithDuration:duration animations:^{
                if (keyboardFrame.origin.y != DEVICE_SIZE.height) {
                    if (distence > 0) {
                        weakSelf.view.top -= distence;
                    }
                } else {
                    weakSelf.view.top = 0;
                }
            }];
        }];
    }];
}

- (void)tapBalance {
    if (![[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        long long maxAmount = self.blance - [[MMAppSetting sharedSetting] getTranferFee];
        self.inputAmountView.defaultAmountString = [[[NSDecimalNumber alloc] initWithLongLong:maxAmount] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue;
    }
}

- (void)initTabelViewCell {
    self.BalanceLabel = [[UILabel alloc] init];
    self.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getAvaliableAmount]]];
    UITapGestureRecognizer *tapBalance = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBalance)];
    [self.BalanceLabel addGestureRecognizer:tapBalance];
    self.BalanceLabel.userInteractionEnabled = YES;

    self.BalanceLabel.textColor = [UIColor colorWithHexString:@"38425F"];
    self.BalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.BalanceLabel.textAlignment = NSTextAlignmentCenter;
    self.BalanceLabel.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.BalanceLabel];
    [self.view sendSubviewToBack:self.BalanceLabel];

    [self.BalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.view);
    }];

    __weak __typeof(&*self) weakSelf = self;
    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        weakSelf.blance = unspentAmount.avaliableAmount;
        weakSelf.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
    }];

    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Transfer", nil) disableTitle:LMLocalizedString(@"Wallet Transfer", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.BalanceLabel.mas_bottom).offset(AUTO_HEIGHT(30));
        make.width.mas_equalTo(self.comfrimButton.width);
        make.height.mas_equalTo(self.comfrimButton.height);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputAmountView hidenKeyBoard];
}

- (void)tapConfrim {
    self.comfrimButton.enabled = NO;
    [self.inputAmountView executeBlock];
}

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {

    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    [self.view endEditing:YES];
    self.comfrimButton.enabled = NO;
    [[LMTransferManager sharedManager] transferFromAddresses:nil currency:CurrencyTypeBTC fee:[[MMAppSetting sharedSetting] getTranferFee] toConnectUserIds:@[self.info.pub_key] perAddressAmount:[PayTool getPOW8Amount:money] tips:note complete:^(id data, NSError *error) {
        self.comfrimButton.enabled = YES;
        if (error) {
            if (error.code != TransactionPackageErrorTypeCancel) {
                [MBProgressHUD showToastwithText:[LMErrorCodeTool messageWithErrorCode:error.code] withType:ToastTypeFail showInView:self.view complete:nil];
            } else {
                [MBProgressHUD hideHUDForView:self.view];
            }
        } else {
            [MBProgressHUD hideHUDForView:self.view];
            if (self.didGetTransferMoney) {
                self.didGetTransferMoney(money.stringValue, data, note);
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }];
    
}

@end
