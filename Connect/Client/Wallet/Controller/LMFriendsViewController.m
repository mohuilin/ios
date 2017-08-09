//
//  LMFriendsViewController.m
//  Connect
//
//  Created by Edwin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMFriendsViewController.h"
#import "LMTransFriendsViewController.h"
#import "UserDBManager.h"
#import "LMSelectTableViewCell.h"
#import "NSString+Pinyin.h"
#import "UIImage+Color.h"
#import "NSString+Size.h"


@interface LMFriendsViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSMutableArray *selectedList;

@property(nonatomic, strong) NSMutableArray *dataArr;

@property(nonatomic, strong) NSMutableArray *sectionArr;

@property(nonatomic, strong) NSMutableArray *alphaArr;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) TransferButton *transferBtn;

@end

static NSString *friends = @"friends";

@implementation LMFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Select friends", nil);
    [self.view addSubview:self.tableView];
    
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    // Get friends
    __weak typeof(self) weakSelf = self;
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showLoadingMessageToView:weakSelf.view];
    }];
    [GCDQueue executeInGlobalQueue:^{
        [[UserDBManager sharedManager] getAllUsersNoConnectWithComplete:^(NSArray *contacts) {
            
            [weakSelf.dataArr addObjectsFromArray:contacts];
            [weakSelf.alphaArr addObjectsFromArray:[MMGlobal accordingTheChineseAndEnglishNameToGenerateAlphabet:weakSelf.dataArr]];
            [weakSelf.sectionArr addObjectsFromArray:[MMGlobal nameIsAlphabeticalAscending:weakSelf.dataArr withAlphaArr:weakSelf.alphaArr]];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                [weakSelf.tableView reloadData];
            }];
        }];
    }];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - lazy
- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        self.dataArr = [NSMutableArray array];
    }
    return _dataArr;
}
- (NSMutableArray *)sectionArr {
    if (!_sectionArr) {
        self.sectionArr = [NSMutableArray array];
    }
    return _sectionArr;
}
- (NSMutableArray *)alphaArr {
    if (!_alphaArr) {
        self.alphaArr = [NSMutableArray array];
    }
    return _alphaArr;
}

- (NSMutableArray *)selectedList {
    if (!_selectedList) {
        self.selectedList = [NSMutableArray array];
    }
    return _selectedList;
}
- (UITableView *)tableView {
    if (!_tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VSIZE.width, VSIZE.height - 64) style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.rowHeight = AUTO_HEIGHT(115);
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.tableFooterView = [[UIView alloc] init];
        self.tableView.sectionIndexColor = [UIColor lightGrayColor];
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        [self.tableView registerNib:[UINib nibWithNibName:@"LMSelectTableViewCell" bundle:nil] forCellReuseIdentifier:friends];
    }
    return _tableView;

}
#pragma mark - method
- (void)setRightBarButtonItemWithEnable:(BOOL)enable withDispalyString:(NSString *)titleName withDisplayColor:(UIColor *)color {
    self.navigationItem.rightBarButtonItems = nil;

    self.transferBtn = [[TransferButton alloc] initWithNormalTitle:titleName disableTitle:titleName];
    self.transferBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.transferBtn.width = [titleName widthWithFont:[UIFont systemFontOfSize:FONT_SIZE(28)] constrainedToHeight:MAXFLOAT];
    if (self.transferBtn.width >= 80) {
        self.transferBtn.width = 80;
    }
    self.transferBtn.height = 44;
    [self.transferBtn addTarget:self action:@selector(transferBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.transferBtn];
    [self.transferBtn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateDisabled];
    [self.transferBtn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
    if (enable) {
        [self.transferBtn setTitleColor:color forState:UIControlStateNormal];
    } else {
        [self.transferBtn setTitleColor:color forState:UIControlStateDisabled];
    }

    self.transferBtn.enabled = enable;
}

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}

#pragma mark -- Get friends

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *array = self.sectionArr[section];
    return [array count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
    bgView.backgroundColor = LMBasicBackgroudGray;
    UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
    titleOneLabel.backgroundColor = LMBasicBackgroudGray;
    titleOneLabel.text = [NSString stringWithFormat:@"%@", self.alphaArr[section]];
    titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    titleOneLabel.textColor = [UIColor blackColor];
    titleOneLabel.textAlignment = NSTextAlignmentLeft;
    [bgView addSubview:titleOneLabel];
    return bgView;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.alphaArr;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [tableView scrollToRowAtIndexPath:selectIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    return index;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    LMSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friends];
    if (!cell) {
        cell = [[LMSelectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:friends];
    }
    AccountInfo *info = self.sectionArr[indexPath.section][indexPath.row];
    [cell setAccoutInfo:info];
    [cell.checkBox setOn:info.isSelected animated:YES];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LMSelectTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    AccountInfo *info = self.sectionArr[indexPath.section][indexPath.row];
    info.isSelected = !info.isSelected;
    [cell.checkBox setOn:info.isSelected animated:YES];
    if ([self.selectedList containsObject:info]) {
        [self.selectedList removeObject:info];
    } else {
        [self.selectedList objectAddObject:info];
    }
    if (self.selectedList.count) {
        [self setRightBarButtonItemWithEnable:YES withDispalyString:[NSString stringWithFormat:LMLocalizedString(@"Wallet transfer man", nil), (int) self.selectedList.count] withDisplayColor:LMBasicGreen];
        
    } else {
        [self setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    }

}
- (void)transferBtnClicked:(UIButton *)btn {
    __weak typeof(self) weakSelf = self;
    if (self.selectedList.count == 0) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Select friends", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    LMTransFriendsViewController *transfer = [[LMTransFriendsViewController alloc] initWithSelectedMembers:self.selectedList changeListBlock:^{
        if (weakSelf.selectedList.count > 0) {
            [weakSelf setRightBarButtonItemWithEnable:YES withDispalyString:[NSString stringWithFormat:LMLocalizedString(@"Wallet transfer man", nil), (int) self.selectedList.count] withDisplayColor:LMBasicGreen];
            [weakSelf.tableView reloadData];
        } else {
            [weakSelf setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
            
        }
    } complete:nil];
    [self.navigationController pushViewController:transfer animated:YES];
}
-(void)dealloc {
    
    [self.selectedList removeAllObjects];
    self.selectedList = nil;
    [self.sectionArr removeAllObjects];
    self.sectionArr = nil;
    [self.dataArr removeAllObjects];
    self.dataArr = nil;
    [self.alphaArr removeAllObjects];
    self.alphaArr = nil;

}
@end
