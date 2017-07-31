//
//  LMTransferOrderView.m
//  Connect
//
//  Created by MoHuilin on 2017/7/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTransferOrderView.h"
#import "LMTransferOrderCell.h"
#import "PayTool.h"
#import "UserDBManager.h"
#import "UIImage+Color.h"

@interface LMTransferOrderView ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *transferToLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *feeLabel;
@property (weak, nonatomic) IBOutlet UIButton *comfirmBtn;

@property (nonatomic ,strong) OriginalTransaction *orderDetail;

@property (nonatomic ,strong) NSMutableArray *txOuts;
@property (nonatomic ,copy) NSString *currency;

@end

@implementation LMTransferOrderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.tableView registerNib:[UINib nibWithNibName:@"LMTransferOrderCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    self.tableView.tableFooterView = [UIView new];
    
    //btn
    self.comfirmBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.comfirmBtn.layer.cornerRadius = 4;
    self.comfirmBtn.layer.masksToBounds = YES;
    [self.comfirmBtn setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"D1D5DA")] forState:UIControlStateDisabled];
    [self.comfirmBtn setBackgroundImage:[UIImage imageWithColor:GJCFQuickHexColor(@"37C65C")] forState:UIControlStateNormal];
    [self.comfirmBtn setTitle:LMLocalizedString(@"Wallet Confirm transfer", nil) forState:UIControlStateNormal];
    
    self.txOuts = [NSMutableArray array];
}

- (IBAction)comfirm:(id)sender {
    if ([self.delegate respondsToSelector:@selector(comfirm)]) {
        [self.delegate comfirm];
    }
}

- (void)comfigOrderDetail:(OriginalTransaction *)orderDetail{
    _orderDetail = orderDetail;
    switch (orderDetail.currency) {
        case CurrencyTypeBTC:
            self.currency = @"BTC";
            break;
            
        default:
            break;
    }
    if (orderDetail.fixedFee) {
        int64_t fee = (orderDetail.fee?orderDetail.fee:orderDetail.estimateFee) + orderDetail.fixedFee;
        self.feeLabel.text = [NSString stringWithFormat:@"%@:%@ %@",LMLocalizedString(@"Set Miner fee", nil),[PayTool getBtcStringWithAmount:fee],self.currency];
        Txout *formartTxout = [Txout new];
        Txout *txout = [orderDetail.txOutsArray firstObject];
        formartTxout.amount = txout.amount - orderDetail.fixedFee;
        formartTxout.address = LMLocalizedString(@"Wallet The Connect system address", nil);
        [self.txOuts addObject:formartTxout];
    } else {
        self.feeLabel.text = [NSString stringWithFormat:@"%@:%@ %@",LMLocalizedString(@"Set Miner fee", nil),[PayTool getBtcStringWithAmount:orderDetail.fee?orderDetail.fee:orderDetail.estimateFee],self.currency];
        Txout *formartTxout = [Txout new];
        for (Txout *txout in orderDetail.txOutsArray) {
            if ([orderDetail.addressesArray containsObject:txout.address]) {
                continue;
            }
            AccountInfo *friend = [[UserDBManager sharedManager] getUserByAddress:txout.address];
            if (friend) {
                formartTxout.address = [NSString stringWithFormat:@"%@(%@)",friend.normalShowName,LMLocalizedString(@"Link Friend", nil)];
                formartTxout.amount = txout.amount;
                [self.txOuts addObject:formartTxout];
            } else {
                [self.txOuts addObject:txout];
            }
        }
    }
    
    self.tableView.scrollEnabled = self.txOuts.count > 3;
    //reload data
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LMTransferOrderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    Txout *txout = [self.txOuts objectAtIndex:indexPath.row];
    cell.outLabel.text = txout.address;
    cell.amountLabel.text = [NSString stringWithFormat:@"%@%@",[PayTool getBtcStringWithAmount:txout.amount],self.currency];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.txOuts.count;
}

@end
