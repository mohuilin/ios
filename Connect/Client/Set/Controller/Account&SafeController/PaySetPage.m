//
//  PaySetPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PaySetPage.h"
#import "SetTransferFeePage.h"
#import "LMIMHelper.h"
#import "LMSeedModel.h"
#import "LMWalletManager.h"
#import "LMBtcCurrencyManager.h"

@interface PaySetPage ()

@property(nonatomic, weak) UITextField *passTextField;
@property(nonatomic, assign) BOOL poptoRoot;
@property(copy, nonatomic) NSString *fee;


@end

@implementation PaySetPage

- (instancetype)initIsNeedPoptoRoot:(BOOL)poptoRoot {
    if (self = [super init]) {
        self.poptoRoot = poptoRoot;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setupCellData];
    [self.tableView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Payment", nil);
    self.view.backgroundColor = LMBasicBackgroudGray;

    __weak __typeof(&*self) weakSelf = self;
    if (![[MMAppSetting sharedSetting] isHaveSyncPaySet]) {
        // download pay data
        [SetGlobalHandler getPaySetComplete:^(NSError *erro) {
            if (!erro) {
                [GCDQueue executeInMainQueue:^{
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }];
    }

    if (self.poptoRoot) {
        [GCDQueue executeInMainQueue:^{
            [self resetPayPass];
        }             afterDelaySecs:1.f];
    }
}

- (void)configTableView {

    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[NCellSwitch class] forCellReuseIdentifier:@"NCellSwitcwID"];

    [self.tableView registerNib:[UINib nibWithNibName:@"NCellValue1" bundle:nil] forCellReuseIdentifier:@"NCellValue1ID"];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"setting_finger_pay"]];
    [self.view addSubview:imageView];
    imageView.frame = AUTO_RECT(0, 0, 750, 508);
    imageView.contentMode = UIViewContentModeCenter;

    self.tableView.tableHeaderView = imageView;

}

- (void)reload {
    [GCDQueue executeInMainQueue:^{
        [self setupCellData];
        [self.tableView reloadData];
    }];
}


- (void)setupCellData {

    [self.groups removeAllObjects];
    __weak __typeof(&*self) weakSelf = self;
    
    CellGroup *group0 = [[CellGroup alloc] init];
    NSString *tip = LMLocalizedString(@"Wallet Reset password", nil);
    CellItem *payPass = [CellItem itemWithTitle:LMLocalizedString(@"Set Payment Password", nil) subTitle:tip type:CellItemTypeValue1 operation:^{
        [weakSelf resetPayPass];
    }];
    group0.items = @[payPass];
    [self.groups objectAddObject:group0];
    
    // second group
    CellGroup *group1 = [[CellGroup alloc] init];
    if ([[MMAppSetting sharedSetting] canAutoCalculateTransactionFee]) {
        weakSelf.fee = LMLocalizedString(@"Set Auto", nil);
    } else {
        weakSelf.fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getTranferFee]]];
    }
    CellItem *transferFee = [CellItem itemWithTitle:LMLocalizedString(@"Set Miner fee", nil) subTitle:weakSelf.fee type:CellItemTypeValue1 operation:^{
        SetTransferFeePage *page = [[SetTransferFeePage alloc] init];
        page.changeCallBack = ^(BOOL flag, long long value) {
            if (flag) {
                weakSelf.fee = LMLocalizedString(@"Set Auto", nil);
            } else {
                weakSelf.fee = [NSString stringWithFormat:@"฿ %@", [PayTool getBtcStringWithAmount:[[MMAppSetting sharedSetting] getTranferFee]]];
            }
            [weakSelf.tableView reloadData];
        };
        [weakSelf hidenTabbarWhenPushController:page];
    }];
    group1.items = @[transferFee];

    [self.groups objectAddObject:group1];
}


- (void)openNoPassPay:(BOOL)nopassPay {

    __weak __typeof(&*self) weakSelf = self;
    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Enter Login Password", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        weakSelf.passTextField = textField;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf setupCellData];
        [weakSelf.tableView reloadData];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {

        [GCDQueue executeInGlobalQueue:^{

            weakSelf.navigationController.view.userInteractionEnabled = NO;
            NSDictionary *decodeDict = [LMIMHelper decodeEncryptPrikey:loginUser.encryption_pri withPassword:weakSelf.passTextField.text];
            weakSelf.navigationController.view.userInteractionEnabled = YES;

            if (decodeDict) {
                [SetGlobalHandler setPaySetNoPass:nopassPay payPass:[[MMAppSetting sharedSetting] getPayPass] fee:[[MMAppSetting sharedSetting] getTranferFee] compete:^(BOOL result) {
                    if (result) {
                        [weakSelf reload];
                    }
                }];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Password incorrect", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    [weakSelf setupCellData];
                    [weakSelf.tableView reloadData];
                }];
            }
        }];

    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];


    [self presentViewController:alertController animated:YES completion:nil];


}

- (void)resetPayPass {
    
    [MBProgressHUD showLoadingMessageToView:self.view];
    
    //sync
    [[LMWalletManager sharedManager] getWalletData:^(RespSyncWallet *wallet,NSError *error) {
        if (wallet) {
            [MBProgressHUD hideHUDForView:self.view];
            NSString *encodeBaseSeed = [LMWalletManager sharedManager].baseModel.encryptSeed;
            NSString *currencyPayload = nil;
            CategoryType category = CategoryTypeNewUser;
            for (Coin *coin in wallet.coinsArray) {
                if (coin.currency == CurrencyTypeBTC) { /// only btc have old account
                    category = coin.category;
                    if (category == CategoryTypeOldUser) {
                        currencyPayload = coin.payload;
                    }
                    break;
                }
            }
            KQXPasswordInputController *passView = [[KQXPasswordInputController alloc] initWithPasswordCategory:KQXPasswordCategoryVerify complete:^(KQXPasswordInputController *inputPassVc, NSString *psw) {
                LMBaseCurrencyManager *baseCurrency = nil;
                baseCurrency = [[LMBtcCurrencyManager alloc] init];
                
                switch (category) {
                    case CategoryTypeNewUser:
                    {
                        [baseCurrency decodeEncryptValue:encodeBaseSeed password:psw complete:^(NSString *decodeValue, BOOL success) {
                            [inputPassVc verfilySuccess:success];
                            if (success) {
                                [self updateEncryptValueWithDecodeBaseSeed:decodeValue decodePriHex:nil withCategory:category];
                            }
                        }];
                    }
                        break;
                        
                    case CategoryTypeOldUser:
                    {
                        /// decode baseseed and decode hexpri
                        [baseCurrency decodeEncryptValue:encodeBaseSeed password:psw complete:^(NSString *decodeBaseSeed, BOOL success) {
                            if (success) {
                                [baseCurrency decodeEncryptValue:currencyPayload password:psw complete:^(NSString *decodePrihex, BOOL success) {
                                    [inputPassVc verfilySuccess:success];
                                    if (success) {
                                        [self updateEncryptValueWithDecodeBaseSeed:decodeBaseSeed decodePriHex:decodePrihex withCategory:category];
                                    }
                                }];
                            } else {
                                [inputPassVc verfilySuccess:success];
                            }
                        }];
                    }
                        break;
                        
                    default:
                        break;
                }
            }];
            [self presentViewController:passView animated:NO completion:nil];
        } else {
            [MBProgressHUD showToastwithText:[LMErrorCodeTool messageWithErrorCode:error.code] withType:ToastTypeFail showInView:self.view complete:nil];
        }
    }];
    
}

- (void)updateEncryptValueWithDecodeBaseSeed:(NSString *)decodeBaseseed decodePriHex:(NSString *)decodePriHex withCategory:(CategoryType)category{
    
    KQXPasswordInputController *passView = [[KQXPasswordInputController alloc] initWithPasswordCategory:KQXPasswordCategorySet complete:^(KQXPasswordInputController *inputPassVc,NSString *password) {
        [[LMWalletManager sharedManager] reEncryptBaseSeed:decodeBaseseed priHex:decodePriHex passWord:password category:category complete:^(NSError *error) {
            if (!error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:self.view complete:^{
                        if (self.poptoRoot) {
                            [GCDQueue executeInMainQueue:^{
                                [self.navigationController popToRootViewControllerAnimated:YES];
                            }             afterDelaySecs:1.f];
                        }
                    }];
                }];
                [self reload];
            } else {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Save Failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                }];
            }
        }];
        
    }];
    [self presentViewController:passView animated:NO completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeSwitch) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellSwitcwID"];
        NCellSwitch *switchCell = (NCellSwitch *) cell;
        switchCell.switchIsOn = item.switchIsOn;
        switchCell.SwitchValueChangeCallBackBlock = ^(BOOL on) {
            item.operationWithInfo ? item.operationWithInfo(@(on)) : nil;
        };

        switchCell.customLable.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeValue1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellValue1ID"];
        NCellValue1 *value1Cell = (NCellValue1 *) cell;
        value1Cell.data = item;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(111);
}

@end
