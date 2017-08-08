//
//  OuterTransferViewController.m
//  Connect
//
//  Created by MoHuilin on 2016/11/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "OuterTransferViewController.h"
#import "TransferInputView.h"
#import "OuterTransferDetailController.h"
#import "WallteNetWorkTool.h"
#import "OuterTransferHisPage.h"
#import "NetWorkOperationTool.h"
#import "NSString+Size.h"

@interface OuterTransferViewController ()

@property(nonatomic, strong) UILabel *userBalanceLabel;

@property(nonatomic, strong) TransferInputView *inputAmountView;
@property(nonatomic, strong) NSDecimalNumber *amount;
@property(nonatomic, strong) UIButton *outerTransferHisButton;
@property(nonatomic, strong) UILabel *titleLabel;

@end

@implementation OuterTransferViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Transfer", nil);
    [self setWhitefBackArrowItem];
    [self setRightBarButtonItem];
    [self creatView];
    [self.view addSubview:self.errorTipLabel];
    
}

- (void)setRightBarButtonItem {
    self.outerTransferHisButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_outerTransferHisButton addTarget:self action:@selector(outerTransferHis) forControlEvents:UIControlEventTouchUpInside];
    _outerTransferHisButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    [_outerTransferHisButton setTitleColor:LMBasicGreen forState:UIControlStateNormal];
    self.outerTransferHisButton.width = [LMLocalizedString(@"Chat History", nil) widthWithFont:_outerTransferHisButton.titleLabel.font constrainedToHeight:AUTO_HEIGHT(49)];
    [_outerTransferHisButton setTitle:LMLocalizedString(@"Chat History", nil) forState:UIControlStateNormal];
    self.outerTransferHisButton.height = AUTO_HEIGHT(49);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.outerTransferHisButton];
}

- (void)creatView {

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.titleLabel.textColor = LMBasicTextFieldeColor;
    _titleLabel.text = LMLocalizedString(@"Wallet Transfer via other APP messges", nil);
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(AUTO_HEIGHT(40) + 64);
        make.centerX.equalTo(self.view);
        make.left.mas_equalTo(self.view).offset(10);
        make.right.mas_equalTo(self.view).offset(-10);
    }];


    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(AUTO_HEIGHT(40));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Amount", nil);
    view.resultBlock = ^(NSDecimalNumber *btcMoney, NSString *note) {
        weakSelf.amount = btcMoney;
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
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Get rate failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];


    self.userBalanceLabel = [[UILabel alloc] init];
    self.amount = [[NSDecimalNumber alloc] initWithLong:[[LMWalletManager sharedManager] currencyModelWith:CurrencyTypeBTC].amount];
    self.userBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:[self.amount integerValue]]];
    self.userBalanceLabel.textColor = LMBasicBlanceBtnTitleColor;
    self.userBalanceLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.userBalanceLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.userBalanceLabel];
    // Get wallet information
    [[PayTool sharedInstance] getBlanceWithComplete:^(NSString *blance, UnspentAmount *unspentAmount, NSError *error) {
        [GCDQueue executeInMainQueue:^{
            weakSelf.userBalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:unspentAmount.avaliableAmount]];
            weakSelf.amount = [[NSDecimalNumber alloc] initWithLong:unspentAmount.avaliableAmount];
        }];
    }];
    [_userBalanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.view);
    }];
    UITapGestureRecognizer *tapBalance = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBalance)];
    [self.userBalanceLabel addGestureRecognizer:tapBalance];
    self.userBalanceLabel.userInteractionEnabled = YES;
    
    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Transfer", nil) disableTitle:LMLocalizedString(@"Wallet Transfer", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.userBalanceLabel.mas_bottom).offset(AUTO_HEIGHT(30));
        make.height.mas_equalTo(self.comfrimButton.height);
        make.width.mas_equalTo(self.comfrimButton.width);
    }];
}

- (void)tapBalance{
    if (![[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        long long maxAmount = self.blance - [[MMAppSetting sharedSetting] getTranferFee] * 2;
        self.inputAmountView.defaultAmountString = [[[NSDecimalNumber alloc] initWithLongLong:maxAmount] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue;
    }
}

- (void)outerTransferHis {
    OuterTransferHisPage *page = [[OuterTransferHisPage alloc] init];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)tapConfrim {
    [self.inputAmountView executeBlock];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self hidenKeyBoard];
}

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {

    [self.view endEditing:YES];
    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    self.comfrimButton.enabled = NO;
    [[LMTransferManager sharedManager] sendUrlTransferFromAddresses:nil tips:note amount:[PayTool getPOW8Amount:money] fee:[[MMAppSetting sharedSetting] getTranferFee] currency:CurrencyTypeBTC complete:^(id data, NSError *error) {
        self.comfrimButton.enabled = YES;
        if (error) {
            if (error.code != TransactionPackageErrorTypeCancel) {
                [MBProgressHUD showToastwithText:[LMErrorCodeTool messageWithErrorCode:error.code] withType:ToastTypeFail showInView:self.view complete:nil];
            } else {
                [MBProgressHUD hideHUDForView:self.view];
            }
        } else {
            [MBProgressHUD hideHUDForView:self.view];
            OuterTransferDetailController *page = [[OuterTransferDetailController alloc] initWithHashId:data];
            [self.navigationController pushViewController:page animated:YES];
        }
    }];
}

- (void)hidenKeyBoard {
    [self.inputAmountView hidenKeyBoard];
    [self.view endEditing:YES];
}

- (NSDecimalNumber *)amount {
    if (!_amount) {
        _amount = [[NSDecimalNumber alloc] initWithDouble:MIN_TRANSFER_AMOUNT];
    }
    return _amount;
}


@end
