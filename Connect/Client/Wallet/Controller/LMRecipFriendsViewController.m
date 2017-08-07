//
//  LMRecipFriendsViewController.m
//  Connect
//
//  Created by Edwin on 16/7/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRecipFriendsViewController.h"
#import "GJGCChatFriendTalkModel.h"
#import "GJGCChatFriendViewController.h"
#import "NetWorkOperationTool.h"
#import "TransferInputView.h"
#import "LMMessageExtendManager.h"

@interface LMRecipFriendsViewController ()

@property(nonatomic, strong) UIImageView *userImageView;
@property(nonatomic, strong) UILabel *usernameLabel;
@property(nonatomic, strong) TransferInputView *inputAmountView;
@property(nonatomic, copy) void (^didGetMoneyAndWithAccountID)(NSDecimalNumber *money, NSString *hashId, NSString *note);
@property (nonatomic ,strong) AccountInfo *chatUser;

@end

@implementation LMRecipFriendsViewController

- (instancetype)initWithChatUser:(AccountInfo *)chatUser callBack:(void (^)(NSDecimalNumber *, NSString *, NSString *))callBack{
    if (self = [super init]) {
        self.chatUser = chatUser;
        self.didGetMoneyAndWithAccountID = callBack;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Wallet Receipt", nil);
    [self addNewCloseBarItem];
    [self initUserInfomation];

    __weak __typeof(&*self) weakSelf = self;
    TransferInputView *view = [[TransferInputView alloc] init];
    self.inputAmountView = view;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameLabel.mas_bottom).offset(AUTO_HEIGHT(10));
        make.width.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(334));
        make.left.equalTo(self.view);
    }];
    view.topTipString = LMLocalizedString(@"Wallet Amount", nil);
    view.isHidenFee = YES;
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
    self.comfrimButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Receipt", nil) disableTitle:LMLocalizedString(@"Wallet Receipt", nil)];
    [self.comfrimButton addTarget:self action:@selector(tapConfrim) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.comfrimButton];
    [self.comfrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.inputAmountView.mas_bottom).offset(AUTO_HEIGHT(30));
        make.width.mas_equalTo(self.comfrimButton.width);
        make.height.mas_equalTo(self.comfrimButton.height);
    }];

}

- (void)initUserInfomation {
    self.userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(AUTO_WIDTH(319), AUTO_HEIGHT(30) + 64, AUTO_WIDTH(112), AUTO_WIDTH(112))];
    [self.userImageView setPlaceholderImageWithAvatarUrl:self.chatUser.avatar];
    self.userImageView.layer.cornerRadius = 5;
    self.userImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.userImageView];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(AUTO_WIDTH(50), CGRectGetMaxY(self.userImageView.frame) + AUTO_HEIGHT(10), VSIZE.width - AUTO_WIDTH(100), AUTO_HEIGHT(40))];
    self.usernameLabel.text = self.chatUser.username;
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.usernameLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.usernameLabel];
}

- (void)tapConfrim {
    self.comfrimButton.enabled = NO;
    [self.inputAmountView executeBlock];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputAmountView hidenKeyBoard];
}

#pragma mark -- 收款

- (void)createTranscationWithMoney:(NSDecimalNumber *)money note:(NSString *)note {

    NSDecimalNumber *amount = [money decimalNumberByMultiplyingBy:[[NSDecimalNumber alloc] initWithLong:pow(10, 8)]];
    [self.view endEditing:YES];
    [MBProgressHUD showTransferLoadingViewtoView:self.view];
    [[LMTransferManager sharedManager] sendReceiptToPayer:self.chatUser.pub_key amount:[PayTool getPOW8Amount:money] tips:note currency:CurrencyTypeBTC complete:^(Bill *bill, NSError *error) {
        if (error) {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Transfer failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        } else {
            [MBProgressHUD hideHUDForView:self.view];
            [[LMMessageExtendManager sharedManager] updateMessageExtendStatus:0 withHashId:bill.hash_p];
            if (self.didGetMoneyAndWithAccountID) {
                self.didGetMoneyAndWithAccountID(amount, bill.hash_p, note);
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
}

@end
