//
//  LMTranHisViewController.m
//  Connect
//
//  Created by Edwin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMTranHisViewController.h"
#import "LMTableViewCell.h"
#import "NetWorkOperationTool.h"
#import "CommonClausePage.h"
#import "UIScrollView+EmptyDataSet.h"
#import "LMHistoryCacheManager.h"
#import "LMBtcCurrencyManager.h"


@interface LMTranHisViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

// array
@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) UITableView *tableView;
// page
@property(nonatomic, assign) int page;
// pagesize
@property(nonatomic, assign) int pagesize;
// downPages
@property(nonatomic, strong) NSMutableArray *downPages;

@end

@implementation LMTranHisViewController

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Transactions", nil);
    self.page = 1;
    self.pagesize = 10;
    [self.view addSubview:self.tableView];
    NSData *data = [[LMHistoryCacheManager sharedManager] getTransferContactsCache];
    Transactions *address = [Transactions parseFromData:data error:nil];
    [self successAction:address withFlag:YES];
    __weak __typeof(&*self) weakSelf = self;
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getData];
    }];

    // set title
    [header setTitle:LMLocalizedString(@"Common Pull down to refresh", nil) forState:MJRefreshStateIdle];
    [header setTitle:LMLocalizedString(@"Common Release to refresh", nil) forState:MJRefreshStatePulling];
    [header setTitle:LMLocalizedString(@"Common Loading", nil) forState:MJRefreshStateRefreshing];

    // set font
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];

    // set color
    header.stateLabel.textColor = [UIColor grayColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor grayColor];

    // refresh
    [header beginRefreshing];
    self.tableView.mj_header = header;
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
    [self.tableView.mj_header beginRefreshing];
    // pull up load more
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        // get address records
        weakSelf.page += 1;
        [weakSelf getData];
    }];
   
}
- (void)getData {

    if ([self.downPages containsObject:@(self.page)]) {
        [GCDQueue executeInMainQueue:^{
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];
            
            [self.tableView reloadData];
        }];
        return;
    }
    
    LMBaseCurrencyManager *baseCurrency = nil;
    switch ([LMWalletManager sharedManager].presentCurrency) {
        case CurrencyTypeBTC:
            baseCurrency = [[LMBtcCurrencyManager alloc] init];
            break;
        default:
            break;
    }
    
    [baseCurrency getWaterTransactions:CurrencyTypeBTC address:nil page:self.page size:self.pagesize complete:^(Transactions *transactions,NSError *error) {
        if (!error) {
            if (self.page == 1) {
                [self.dataArr removeAllObjects];
            }
            [self.downPages objectAddObject:@(self.page)];
            [self successAction:transactions withFlag:NO];
            
        }else {
            [GCDQueue executeInMainQueue:^{
                [self.tableView.mj_header endRefreshing];
                [self.tableView.mj_footer endRefreshing];
                [MBProgressHUD showToastwithText:nil withType:ToastTypeFail showInView:self.view complete:^{
                    [self.tableView reloadData];
                }];
            }];
        }
    }];
}
- (void)successAction:(Transactions *)address withFlag:(BOOL)flag{
    for (int i = 0; i < address.transactionsArray.count; i++) {
        LMUserInfo *info = [[LMUserInfo alloc] init];
        Transaction *trans = [address.transactionsArray objectAtIndexCheck:i];
        info.hashId = trans.hash_p;
        info.txType = trans.txType;
        UserInfoBalance *infoBalance = nil;
        NSMutableArray *headersUrls = [NSMutableArray array];
        if (trans.userInfosArray.count > 1) {
            for (UserInfoBalance *temInfoBalance in trans.userInfosArray) {
                if (!GJCFStringIsNull(temInfoBalance.avatar)) {
                    if (headersUrls.count < 9) {
                        [headersUrls objectAddObject:temInfoBalance.avatar];
                    }
                }
            }
            info.userName = LMLocalizedString(@"Wallet Multiple transfers", nil);
            info.imageUrls = headersUrls;
        } else if (trans.userInfosArray.count == 1) {
            infoBalance = [trans.userInfosArray firstObject];
            info.userName = infoBalance.username;
            info.imageUrl = infoBalance.avatar;
        } else {
            if (trans.balance < 0) {
                info.userName = [[[trans.outputsArray firstObject] addressesArray] firstObject];
            } else {
                info.userName = [[[trans.inputsArray firstObject] prevAddressesArray] firstObject];
            }
        }
        info.balance = trans.balance;
        info.createdAt = [NSString stringWithFormat:@"%llu", trans.createdAt];
        info.category = trans.category;
        info.confirmation = trans.confirmations > 0;
        [self.dataArr objectAddObject:info];
    }
    [GCDQueue executeInMainQueue:^{
        if (!flag) {
           [self.tableView.mj_header endRefreshing];
        }
        if (self.page > 1) {
            if (address.transactionsArray.count <= 0) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            } else {
                [self.tableView.mj_footer endRefreshing];
            }
        }
        [self.tableView reloadData];
    }];
}
#pragma mark --tableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LMTableViewCellID" forIndexPath:indexPath];
    LMUserInfo *userInfo = self.dataArr[indexPath.row];
    [cell setUserInfo:userInfo];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LMUserInfo *info = self.dataArr[indexPath.row];

    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, info.hashId];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    [self.navigationController pushViewController:page animated:YES];
}

#pragma -mark  DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Network No data", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Wallet You do not have any Transactions", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return nil;
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}


#pragma mark --lazy

- (NSMutableArray *)dataArr {
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (NSMutableArray *)downPages {
    if (!_downPages) {
        _downPages = [NSMutableArray array];
    }
    return _downPages;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [_tableView registerNib:[UINib nibWithNibName:@"LMTableViewCell" bundle:nil] forCellReuseIdentifier:@"LMTableViewCellID"];
        _tableView.rowHeight = AUTO_HEIGHT(132);
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;
    }

    return _tableView;
}

@end
