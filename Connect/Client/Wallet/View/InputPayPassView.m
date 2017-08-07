//
//  InputPayPassView.m
//  Connect
//
//  Created by MoHuilin on 2016/11/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "InputPayPassView.h"
#import "PassInputFieldView.h"
#import "JxbLoadingView.h"
#import "LocalAuthentication/LAContext.h"
#import "WJTouchID.h"
#import "LMBtcCurrencyManager.h"
#import "LMWalletManager.h"
#import "LMTransferOrderView.h"

@interface InputPayPassView () <PassInputFieldViewDelegate,LMTransferOrderViewDelegate>

@property(strong, nonatomic) UIView *contentView;
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UIView *lineView;
@property(nonatomic, copy) NSString *fristPass;
@property(nonatomic, strong) CAShapeLayer *walletLayer;
@property(nonatomic, strong) PassInputFieldView *secondPassView;
@property(nonatomic, strong) PassInputFieldView *fristPassView;
@property(nonatomic, strong) PassInputFieldView *payPassView;


@property(nonatomic, copy) void (^PayCompleteBlock)(CategoryType category,NSString *decodeValue,InputPayPassView *passView);
@property(nonatomic, copy) void (^ForgetPassBlock)();
@property(nonatomic, copy) void (^CloseBlock)();

@property(strong, nonatomic) UIView *bottomView;
@property(nonatomic, strong) LMTransferOrderView *orderContentView;
@property(strong, nonatomic) UIView *passInputView;
@property(strong, nonatomic) UILabel *passStatusLabel;

@property(nonatomic, strong) UIView *animationContentView;
@property(strong, nonatomic) JxbLoadingView *animationView;
@property(strong, nonatomic) UILabel *statusLabel;
@property(strong, nonatomic) UILabel *displayLbale;

@property(strong, nonatomic) UIView *passErrorContentView;
@property(strong, nonatomic) UILabel *passErrorTipLabel;
@property(strong, nonatomic) UIButton *forgetPassBtn;
@property(strong, nonatomic) UIButton *retryBtn;
@property(strong, nonatomic) UIButton *retryNewBtn;

@property (nonatomic ,strong) UIButton *actionBtn;

@property(assign, nonatomic) BOOL isPassTag;

@property (nonatomic ,strong) OriginalTransaction *orderDetail;
@property (nonatomic ,assign) CurrencyType currency;

@end

@implementation InputPayPassView

- (IBAction)viewAction:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:
        {
            self.backgroundColor = [UIColor clearColor];
            if (self.CloseBlock) {
                self.CloseBlock();
            }
            [UIView animateWithDuration:0.25 animations:^{
                self.backgroundColor = [UIColor clearColor];
                self.contentView.top = DEVICE_SIZE.height;
            }                completion:^(BOOL finished) {
                [self removeFromSuperview];
            }];
        }
            break;
        case 1:
        {
            self.titleLabel.text = LMLocalizedString(@"Wallet Transfer details", nil);
            [self.orderContentView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView);
            }];
            [UIView animateWithDuration:0.3 animations:^{
                [self.contentView layoutIfNeeded];
            }];
            
            //update ui
            [self.actionBtn setImage:[UIImage imageNamed:@"cancel_grey"] forState:UIControlStateNormal];
            self.actionBtn.tag = 0;
            
            [self.payPassView clearAll];
            [self endEditing:YES];
        }
            break;
        default:
            break;
    }
}

- (IBAction)retry:(id)sender {
    
    [self.actionBtn setImage:[UIImage imageNamed:@"grey_back"] forState:UIControlStateNormal];
    self.actionBtn.tag = 1;
    
    self.titleLabel.text = LMLocalizedString(@"Wallet Enter your PIN", nil);
    [self.orderContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        [self.contentView layoutIfNeeded];
    }];
    [self.payPassView clearAll];
    [self.payPassView becomeFirstResponder];
}

- (IBAction)forgetPass:(id)sender {
    [UIView animateWithDuration:0.3 animations:^{
        self.top = DEVICE_SIZE.height;
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow];

    }                completion:^(BOOL finished) {
        if (self.ForgetPassBlock) {
            
            self.ForgetPassBlock();
        }
        [self removeFromSuperview];
    }];
}

+ (InputPayPassView *)inputPayPassWithOrderDetail:(OriginalTransaction *)orderDetail currency:(CurrencyType)currency complete:(void (^)(CategoryType category,NSString *decodeValue,InputPayPassView *passView))complete closeBlock:(void (^)())closeBlock{
    InputPayPassView *passView = [[InputPayPassView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    passView.style = InputPayPassViewVerfyPass;
    __weak __typeof(&*passView) weakSelf = passView;
    passView.requestCallBack = ^(NSError *error) {
        [weakSelf showResultStatusWithError:error];
    };
    passView.PayCompleteBlock = complete;
    passView.currency = currency;
    passView.CloseBlock = closeBlock;
    passView.orderDetail = orderDetail;
    passView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:passView];
    return passView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupSubviews];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.bottom = DEVICE_SIZE.height;
    }];
}

- (void)setupSubviews {
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.contentView];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.mas_bottom);
        make.height.mas_equalTo(AUTO_HEIGHT(880));
    }];

    self.actionBtn = [[UIButton alloc] init];
    [self.actionBtn addTarget:self action:@selector(viewAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionBtn setImage:[UIImage imageNamed:@"cancel_grey"] forState:UIControlStateNormal];
    [self.contentView addSubview:self.actionBtn];
    [self.actionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(AUTO_WIDTH(20));
        make.top.equalTo(self.contentView).offset(AUTO_HEIGHT(10));
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(88), AUTO_HEIGHT(88)));
    }];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.actionBtn);
        make.centerX.equalTo(self.contentView);
    }];

    self.lineView = [[UIView alloc] init];
    self.lineView.backgroundColor = LMBasicLineViewColor;
    [self.contentView addSubview:self.lineView];
    [_lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.actionBtn.mas_bottom).offset(AUTO_HEIGHT(10));
        make.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(0.5);
    }];
    self.orderContentView = [[[NSBundle mainBundle] loadNibNamed:@"LMTransferOrderView" owner:self options:nil] lastObject];
    self.orderContentView.delegate = self;
    
    [self.contentView addSubview:self.orderContentView];
    [_orderContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.lineView.mas_bottom);
        make.left.bottom.equalTo(self.contentView);
        make.width.mas_equalTo(DEVICE_SIZE.width);
    }];
    
    // enter password
    self.bottomView = [[UIView alloc] init];
    [self.contentView addSubview:self.bottomView];
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.lineView.mas_bottom);
        make.left.equalTo(self.orderContentView.mas_right);
        make.width.mas_equalTo(DEVICE_SIZE.width);
        make.bottom.equalTo(self.contentView);
    }];
    
    self.passInputView = [[UIView alloc] init];
    [self.bottomView addSubview:self.passInputView];
    [_passInputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView.mas_top).offset(AUTO_HEIGHT(147));
        make.left.equalTo(self.orderContentView.mas_right);
        make.height.mas_equalTo(AUTO_HEIGHT(80));
        make.width.mas_equalTo(DEVICE_SIZE.width);
    }];

    self.passStatusLabel = [[UILabel alloc] init];
    self.passStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.passStatusLabel.numberOfLines = 0;
    [self.bottomView addSubview:self.passStatusLabel];
    [_passStatusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passInputView.mas_bottom).offset(AUTO_HEIGHT(80));
        make.centerX.equalTo(self.bottomView);
    }];

    // status
    self.animationContentView = [[UIView alloc] init];
    [self.contentView addSubview:self.animationContentView];
    [_animationContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView);
        make.left.equalTo(self.bottomView.mas_right);
        make.width.equalTo(self.bottomView);
        make.height.equalTo(self.bottomView);
    }];

    self.animationView = [[JxbLoadingView alloc] init];
    [self.animationContentView addSubview:self.animationView];
    self.animationView.lineWidth = 4;
    self.animationView.strokeColor = LMBasicBlue;

    [_animationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationContentView.mas_top).offset(AUTO_HEIGHT(150));
        make.centerX.equalTo(self.animationContentView);
        make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(100), AUTO_HEIGHT(100)));
    }];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.animationContentView addSubview:self.statusLabel];
    [_statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationView.mas_bottom).offset(AUTO_HEIGHT(50));
        make.centerX.equalTo(self.animationContentView);
        make.left.right.equalTo(self.animationContentView);
    }];

    // error
    self.passErrorContentView = [[UIView alloc] init];
    [self.contentView addSubview:self.passErrorContentView];
    [_passErrorContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView);
        make.left.equalTo(self.bottomView.mas_right);
        make.width.equalTo(self.bottomView);
        make.height.equalTo(self.bottomView);
    }];

    self.passErrorTipLabel = [[UILabel alloc] init];
    self.passErrorTipLabel.text = LMLocalizedString(@"Wallet Payment Password is incorrect", nil);
    self.passErrorTipLabel.textAlignment = NSTextAlignmentCenter;
    [self.passErrorContentView addSubview:self.passErrorTipLabel];
    [_passErrorTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passErrorContentView.mas_top).offset(AUTO_HEIGHT(140));
        make.centerX.equalTo(self.animationContentView);
        make.left.right.equalTo(self.animationContentView);
    }];

    self.forgetPassBtn = [[UIButton alloc] init];
    [self.forgetPassBtn setTitle:LMLocalizedString(@"Wallet Forget Password", nil) forState:UIControlStateNormal];
    self.forgetPassBtn.titleLabel.numberOfLines = 0;
    self.forgetPassBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.forgetPassBtn addTarget:self action:@selector(forgetPass:) forControlEvents:UIControlEventTouchUpInside];
    [self.passErrorContentView addSubview:self.forgetPassBtn];
    
    self.forgetPassBtn.hidden = YES;
    
    [_forgetPassBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.passErrorTipLabel.mas_bottom).offset(AUTO_HEIGHT(20));
        make.centerX.equalTo(self.passErrorContentView);
    }];

    self.retryBtn = [[UIButton alloc] init];
    [self.retryBtn setTitle:LMLocalizedString(@"Wallet Retry", nil) forState:UIControlStateNormal];
    [self.retryBtn addTarget:self action:@selector(retry:) forControlEvents:UIControlEventTouchUpInside];
    [self.passErrorContentView addSubview:self.retryBtn];
    [_retryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.forgetPassBtn.mas_bottom).offset(AUTO_HEIGHT(60));
        make.centerX.equalTo(self.passErrorContentView);
    }];

    self.style = InputPayPassViewVerfyPass;
    self.contentView.alpha = 0.98;
    self.titleLabel.text = LMLocalizedString(@"Wallet Transfer details", nil);
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.titleLabel.textColor = GJCFQuickHexColor(@"161A21");
    self.statusLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.statusLabel.textColor = GJCFQuickHexColor(@"B3B5BC");
    self.passStatusLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.passStatusLabel.textColor = GJCFQuickHexColor(@"B3B5BC");
    self.passErrorTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.passErrorTipLabel.textColor = GJCFQuickHexColor(@"B3B5BC");
    [self.retryBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:FONT_SIZE(36)]];
    [self.retryBtn setTitleColor:GJCFQuickHexColor(@"007AFF") forState:UIControlStateNormal];
    [self.forgetPassBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:FONT_SIZE(28)]];
    [self.forgetPassBtn setTitleColor:GJCFQuickHexColor(@"007AFF") forState:UIControlStateNormal];

}

- (void)showResultStatusWithError:(NSError *)error {
    [GCDQueue executeInMainQueue:^{
        if (error) {
            self.titleLabel.text = LMLocalizedString(@"Wallet Pay Faied", nil);
            _walletLayer.speed = 0;
            [_walletLayer removeFromSuperlayer];
            self.statusLabel.hidden = NO;
            self.statusLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Error code Domain Pelese try later", nil), (int) error.code, [LMErrorCodeTool messageWithErrorCode:error.code]];
            [self.animationView finishFailure:nil];
        } else {
            self.statusLabel.text = LMLocalizedString(@"Wallet Payment Successful", nil);
            self.titleLabel.text = LMLocalizedString(@"Wallet Payment Successful", nil);
            [self.animationView finishSuccess:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [GCDQueue executeInMainQueue:^{
                    [self viewAction:nil];
                }             afterDelaySecs:1.f];

            });
        }
    }];
}

- (void)verfyPass {
    PassInputFieldView *payPassView = [[PassInputFieldView alloc] init];
    self.payPassView = payPassView;
    payPassView.delegate = self;
    CGFloat passWH = AUTO_HEIGHT(80);
    [self.passInputView addSubview:payPassView];
    [payPassView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.passInputView);
        make.height.mas_equalTo(passWH);
        make.width.mas_equalTo(4 * passWH);
        make.top.equalTo(self.passInputView);
    }];
    [self.payPassView resignFirstResponder];
    [GCDQueue executeInMainQueue:^{
        [payPassView becomeFirstResponder];
    }             afterDelaySecs:0.3];
}

- (void)setStyle:(InputPayPassViewStyle)style {
    _style = style;
}

- (void)setOrderDetail:(OriginalTransaction *)orderDetail{
    _orderDetail = orderDetail;
    //config data
    [self.orderContentView comfigOrderDetail:self.orderDetail];
}

#pragma mark - passWordCompleteInput


- (void)comfirm{
    [self.orderContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        [self.contentView layoutIfNeeded];
    }];
    [self.actionBtn setImage:[UIImage imageNamed:@"grey_back"] forState:UIControlStateNormal];
    self.actionBtn.tag = 1;
    //enter verfy pass
    self.titleLabel.text = LMLocalizedString(@"Wallet Enter your PIN", nil);
    [self verfyPass];
    [self.payPassView clearAll];
    [self.payPassView becomeFirstResponder];
}


- (void)passWordCompleteInput:(PassInputFieldView *)passWord {
    self.titleLabel.text = LMLocalizedString(@"Set Payment Password", nil);

    self.payPassView.hidden = NO;
    [self endEditing:YES];
    LMBaseCurrencyManager *baseCurrency = nil;
    switch (self.currency) {
        case CurrencyTypeBTC:
            baseCurrency = [[LMBtcCurrencyManager alloc] init];
            break;
        default:
            break;
    }
    
    // close btn
    [self.actionBtn setImage:[UIImage imageNamed:@"cancel_grey"] forState:UIControlStateNormal];
    self.actionBtn.tag = 0;
    
    [self.orderContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width * 2);
    }];
    self.passErrorContentView.hidden = YES;
    self.animationContentView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        [self.contentView layoutIfNeeded];
    }];
    
    self.statusLabel.text = LMLocalizedString(@"Wallet Verifying", nil);
    [self.animationView startLoading];
    
    
    CategoryType category = CategoryTypeNewUser;
    NSString *decodeValue = [LMWalletManager sharedManager].baseModel.encryptSeed;
    LMCurrencyModel *currencyModel = [[LMCurrencyModel objectsWhere:[NSString stringWithFormat:@"currency = %d ",(int)CurrencyTypeBTC]] lastObject];
    if (currencyModel &&
        currencyModel.category == CategoryTypeOldUser) {
        category = currencyModel.category;
        decodeValue = currencyModel.payload;
    }

    //verfiy pass
    [baseCurrency decodeEncryptValue:decodeValue password:passWord.textStore complete:^(NSString *decodeValue, BOOL success) {
        if (success) {
            if (self.PayCompleteBlock) {
                self.PayCompleteBlock(category,decodeValue,self);
            }
        } else {
            [self.orderContentView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView.mas_left).offset(-DEVICE_SIZE.width * 2);
            }];
            self.passErrorContentView.hidden = NO;
            self.animationContentView.hidden = YES;
            self.titleLabel.text = LMLocalizedString(@"Set Verification Faied", nil);
            [UIView animateWithDuration:0.3 animations:^{
                [self.contentView layoutIfNeeded];
            }];
            [self.animationView finishFailure:nil];
        }
    }];

    
    //sync
//    [[LMWalletManager sharedManager] getWalletData:^(RespSyncWallet *wallet,NSError *error) {
//        if (wallet) {
//                    } else {
//            [self showResultStatusWithError:error];
//        }
//    }];
}
@end
