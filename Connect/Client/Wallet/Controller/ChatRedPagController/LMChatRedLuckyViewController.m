//
//  LMChatRedLuckyViewController.m
//  Connect
//
//  Created by Edwin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMChatRedLuckyViewController.h"
#import "RedBagNetWorkTool.h"
#import "NetWorkOperationTool.h"
#import "PaddingTextField.h"
#import "TransferInputView.h"
#import "OuterRedbagDetailViewController.h"
#import "OuterPacketHisPage.h"
#import "NSString+Size.h"
#import "LMPayCheck.h"

@interface LMChatRedLuckyViewController () <UITextFieldDelegate>
// User address or group ID
@property(nonatomic, copy) NSString *reciverIdentifier;
// Wallet balance
@property(nonatomic, strong) UILabel *BalanceLabel;
// title label
@property(nonatomic, strong) UILabel *titleLabel;
// Red envelope animation view
@property(nonatomic, strong) LMRedLuckyShowView *showView;
// Avatar
@property(nonatomic, strong) UIImageView *avatarIcon;
// name
@property(nonatomic, strong) UILabel *nameLabel;
// Number of red envelopes
@property(nonatomic, strong) PaddingTextField *numField;
// Number of input boxes
@property(nonatomic, strong) UIView *numberOfRedLuckyView;
// view
@property(nonatomic, strong) TransferInputView *inputAmountView;
// The value of uilable on numField
@property(strong, nonatomic) UILabel *disPlayLable;
// title
@property(copy, nonatomic) NSString *navTitleString;


@property(nonatomic, assign) LuckypackageTypeCategory category;            // Controller type

@end

@implementation LMChatRedLuckyViewController

#pragma mark - initial method

- (instancetype)initChatRedLuckyViewControllerWithCategory:(LuckypackageTypeCategory)category reciverIdentifier:(NSString *)reciverIdentifier {
    self = [super init];
    if (self) {
        _reciverIdentifier = reciverIdentifier;
        _category = category;
    }
    return self;
}

#pragma mark --

#pragma mark - life cycle

- (void)viewDidLoad {

    [super viewDidLoad];
    
    [self setUpUiWithStyle];
    [self setUpRightButtomItem];
    [self setUpElementsWithTransferView];
    [self navigationConfigureWithTitleString:self.navTitleString];
    [self initTabelViewCell];
    self.ainfo = [[LKUserCenter shareCenter] currentLoginUser];
    
}
- (void)setUpUiWithStyle {

    switch (self.category) {
        case LuckypackageTypeCategorySingle:
        {
            self.navTitleString = LMLocalizedString(@"Wallet Packet", nil);
            [self buildUpUserIcon];
            [self addNewCloseBarItem];
        }
            break;
            
        case LuckypackageTypeCategoryGroup:
        {
            self.navTitleString = LMLocalizedString(@"Wallet Packet", nil);
            [self buildUpNumberOfRedLuckyFillView];
            [self addNewCloseBarItem];
        }
            break;
        case LuckypackageTypeCategoryOuterUrl:
        {
            self.navTitleString = LMLocalizedString(@"Wallet Sent via link luck packet", nil);
            [self buildUpNumberOfRedLuckyFillView];
            [self setWhitefBackArrowItem];
        }
            break;
        default:
            break;
    }
}
- (void)setUpRightButtomItem {
    
    self.navigationItem.rightBarButtonItems = nil;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *nameString = LMLocalizedString(@"Chat History", nil);
    [button setTitle:nameString forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.width = [nameString widthWithFont:[UIFont systemFontOfSize:FONT_SIZE(32)] constrainedToHeight:MAXFLOAT] + 5;
    if (GJCFSystemiPhone5) {
        button.width = [nameString widthWithFont:[UIFont systemFontOfSize:FONT_SIZE(32)] constrainedToHeight:MAXFLOAT] + 15;
    } else if (GJCFSystemiPhone6) {
        button.width = [nameString widthWithFont:[UIFont systemFontOfSize:FONT_SIZE(32)] constrainedToHeight:MAXFLOAT] + 10;
    }
    button.height = 44;
    [button addTarget:self action:@selector(doRight:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
}

- (void)doRight:(id)sender {
    OuterPacketHisPage *page = [[OuterPacketHisPage alloc] init];
    [self.navigationController pushViewController:page animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"luckbag_backgroud"] forBarMetrics:UIBarMetricsDefault];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"top_background"] forBarMetrics:UIBarMetricsDefault];

    [super viewWillDisappear:animated];
}

#pragma mark - Methods

- (void)setUpElementsWithTransferView {


    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        if (self.category == LuckypackageTypeCategorySingle) {
            make.top.equalTo(self.nameLabel.mas_bottom).offset(AUTO_HEIGHT(15));
        } else {
            make.top.equalTo(self.numberOfRedLuckyView.mas_bottom).offset(AUTO_HEIGHT(15));
        }
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Amount", nil);
    view.noteDefaultString = LMLocalizedString(@"Wallet Best wishes", nil);
    view.resultBlock = ^(NSDecimalNumber *btcMoney, NSString *note) {
        if (weakSelf.category == LuckypackageTypeCategoryGroup || weakSelf.category == LuckypackageTypeCategoryOuterUrl) {
            // Red packets are limited
            if ([btcMoney decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:weakSelf.numField.text]].doubleValue < MIN_RED_PER) {
                [GCDQueue executeInMainQueue:^{
                    NSString *alertString = [NSString stringWithFormat:LMLocalizedString(@"Wallet error lucky packet amount too small", nil), MIN_RED_PER];
                    [MBProgressHUD showToastwithText:alertString withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
            } else {
                [weakSelf createTranscationWithMoney:btcMoney note:note];
            }
        } else {
            [weakSelf createTranscationWithMoney:btcMoney note:note];
        }
    };
    view.lagelBlock = ^(BOOL enabled) {
        int size = [weakSelf.numField.text intValue];
        if (weakSelf.category == LuckypackageTypeCategorySingle) {
            weakSelf.comfrimButton.enabled = enabled;
        } else {
            weakSelf.comfrimButton.enabled = enabled && size > 0;
        }
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
    [NSNotificationCenter.defaultCenter addObserverForName:UIKeyboardWillChangeFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        int distence = weakSelf.inputAmountView.bottom - (DEVICE_SIZE.height - keyboardFrame.size.height - AUTO_HEIGHT(100));

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


    self.inputAmountView.defaultAmountString = @"0.0001";
}

- (void)buildUpUserIcon {
    UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 50.f)];
    [icon setPlaceholderImageWithAvatarUrl:_userInfo.avatar];
    [icon setBackgroundColor:[UIColor redColor]];
    [icon.layer setCornerRadius:6.f];
    [icon.layer setMasksToBounds:YES];
    _avatarIcon = icon;
    [self.view addSubview:_avatarIcon];

    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 30.f)];
    [name setTextAlignment:NSTextAlignmentCenter];
    [name setFont:[UIFont systemFontOfSize:14.f]];
    name.textColor = LMBasicBlack;
    [name setText:[NSString stringWithFormat:LMLocalizedString(@"Wallet Send Lucky Packet to", nil), _userInfo.username]];
    _nameLabel = name;
    [self.view addSubview:_nameLabel];

    [_avatarIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).mas_offset(80.f);
        make.width.mas_equalTo(50.f);
        make.height.mas_equalTo(50.f);
    }];

    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(_avatarIcon).mas_offset(3.f + 50.f);
        make.centerX.mas_equalTo(_avatarIcon);
    }];
}

- (void)navigationConfigureWithTitleString:(NSString *)title {
    self.title = title;
}

- (void)tapBalance{
    if (![[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        long long maxAmount = self.blance - [[MMAppSetting sharedSetting] getTranferFee] * 2;
        self.inputAmountView.defaultAmountString = [[[NSDecimalNumber alloc] initWithLongLong:maxAmount] decimalNumberByDividingBy:[[NSDecimalNumber alloc] initWithLongLong:pow(10, 8)]].stringValue;
    }
}

- (void)initTabelViewCell {
    self.BalanceLabel = [[UILabel alloc] init];
    self.BalanceLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Wallet Balance Credit", nil), [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getAvaliableAmount]]];
    UITapGestureRecognizer *tapBalance = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBalance)];
    [self.BalanceLabel addGestureRecognizer:tapBalance];
    self.BalanceLabel.userInteractionEnabled = YES;
    
    self.BalanceLabel.textColor = LMBasicBlanceBtnTitleColor;
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
    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Prepare Lucky Packet", nil) disableTitle:LMLocalizedString(@"Wallet Prepare Lucky Packet", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.BalanceLabel.mas_bottom).offset(AUTO_HEIGHT(30));
        make.width.mas_equalTo(self.comfrimButton.width);
        make.height.mas_equalTo(self.comfrimButton.height);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

// Number of red envelopes fill in the view
- (void)buildUpNumberOfRedLuckyFillView {

    UIView *numberOfRedLuckyView = [[UIView alloc] init];
    self.numberOfRedLuckyView = numberOfRedLuckyView;
    [numberOfRedLuckyView setBackgroundColor:[UIColor whiteColor]];
    [numberOfRedLuckyView.layer setCornerRadius:4.f];
    [numberOfRedLuckyView.layer setMasksToBounds:YES];
    [self.view addSubview:numberOfRedLuckyView];

    PaddingTextField *numField = [[PaddingTextField alloc] init];
    self.numField = numField;
    numField.text = @"1";
    numField.font = [UIFont boldSystemFontOfSize:FONT_SIZE(42)];
    [numField setDelegate:self];
    [numField setKeyboardType:UIKeyboardTypeNumberPad];
    [numField setBorderStyle:UITextBorderStyleNone];

    NSMutableParagraphStyle *style = [self.numField.defaultTextAttributes[NSParagraphStyleAttributeName] mutableCopy];
    style.minimumLineHeight = self.numField.font.lineHeight - (self.numField.font.lineHeight - [UIFont systemFontOfSize:FONT_SIZE(28)].lineHeight) / 2.0;
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:LMLocalizedString(@"Wallet Enter number", nil) attributes:@{
            NSForegroundColorAttributeName: LMBasicLableColor,
            NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE(28)],
            NSParagraphStyleAttributeName: style}];
    [numField setAttributedPlaceholder:attributedString];
    [numberOfRedLuckyView addSubview:numField];
    [numField addTarget:self action:@selector(sizeChange) forControlEvents:UIControlEventEditingChanged];

    [numberOfRedLuckyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.mas_equalTo(self.view).mas_offset(95.5f);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
    }];

    [numField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(numberOfRedLuckyView);
        make.edges.mas_offset(UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f));
    }];
    // Show label
    self.disPlayLable = [[UILabel alloc] init];
    [self.numField addSubview:self.disPlayLable];
    self.disPlayLable.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    //"Enter number"
    self.disPlayLable.textColor = LMBasicLableColor;
    self.disPlayLable.text = LMLocalizedString(@"Wallet Quantity", nil);
    [self.disPlayLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.numField);
        make.height.mas_equalTo(AUTO_WIDTH(150));
        make.right.equalTo(self.numField).offset(AUTO_WIDTH(-10));
    }];
}

#pragma mark - Textfield proxy

- (void)sizeChange {
    if (self.numField.text.length >= 2) {
        self.numField.text = [self.numField.text substringToIndex:2];
    }
    int size = [self.numField.text intValue];
    NSString *numValue = self.inputAmountView.inputTextField.text;
    self.comfrimButton.enabled = (size > 0 && [numValue floatValue] > MIN_TRANSFER_AMOUNT);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.numField) {
        if ([string isEqualToString:@""] || string == nil) {
            return YES;
        }

        NSString *pattern = @"^[0-9]*\\d{1}$";
        NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *results = [regular matchesInString:string options:0 range:NSMakeRange(0, string.length)];
        if (results.count == 0) {
            return NO;
        }
    }
    return YES;
}

- (void)tapConfrim {
    self.comfrimButton.enabled = NO;
    [self.inputAmountView executeBlock];
}

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {
    switch (self.category) {
        case LuckypackageTypeCategorySingle:
        case LuckypackageTypeCategoryGroup: {
            [self sendRedbagWithMoney:money note:note type:0];
        }
            break;

        case LuckypackageTypeCategoryOuterUrl: {
            [self sendRedbagWithMoney:money note:note type:1];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Send an internal red envelope to send an external red envelope

- (void)sendRedbagWithMoney:(NSDecimalNumber *)money note:(NSString *)note type:(int)type {
    
    int size = 1;
    if (self.category == LuckypackageTypeCategoryOuterUrl ||
        self.category == LuckypackageTypeCategoryGroup) {
        if (GJCFStringIsNull(self.numField.text)) {
            self.comfrimButton.enabled = YES;
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Enter number", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        } else {
            size = [self.numField.text intValue];
            if (size <= 0) {
                self.comfrimButton.enabled = YES;
            }
        }
    }
    if (size > 0) {
        [MBProgressHUD showTransferLoadingViewtoView:self.view];
        [self.view endEditing:YES];
        self.comfrimButton.enabled = NO;
        [[LMTransferManager sharedManager] sendLuckyPackageWithReciverIdentifier:self.reciverIdentifier size:size amount:[PayTool getPOW8Amount:money]  fee:[[MMAppSetting sharedSetting] getTranferFee] luckyPackageType:type category:self.category tips:note fromAddresses:nil currency:CurrencyTypeBTC complete:^(id data, NSError *error) {
            self.comfrimButton.enabled = YES;
            if (error) {
                if (error.code != TransactionPackageErrorTypeCancel) {
                    [MBProgressHUD showToastwithText:[LMErrorCodeTool messageWithErrorCode:error.code] withType:ToastTypeFail showInView:self.view complete:nil];
                } else {
                    [MBProgressHUD hideHUDForView:self.view];
                }
            } else {
                switch (type) {
                    case 0: {
                        if (self.didGetRedLuckyMoney) {
                            self.didGetRedLuckyMoney(money.stringValue, data, note);
                        }
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                        break;
                    case 1: {
                        OuterRedbagDetailViewController *page = [[OuterRedbagDetailViewController alloc] initWithHashId:data];
                        [self.navigationController pushViewController:page animated:YES];
                    }
                        break;
                    default:
                        break;
                }
            }
        }];
    }
}

@end
