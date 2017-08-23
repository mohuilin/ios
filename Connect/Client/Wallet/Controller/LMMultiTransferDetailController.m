//
//  LMMultiTransferDetailController.m
//  Connect
//
//  Created by MoHuilin on 2017/8/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMultiTransferDetailController.h"
#import "UIImageView+LMSetImageUrl.h"
#import "LMMultiTransferCell.h"
#import "LMRamGroupInfo.h"

@interface LMMultiTransferDetailController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) UIView *topView;

@property (nonatomic ,strong) UIImageView *senderHeaderImageView;
@property (nonatomic ,strong) UILabel *senderNameLabel;
@property (nonatomic ,strong) UILabel *totalAmountLabel;

@property (nonatomic ,strong) UITableView *tableView;

@property (nonatomic ,strong) Bill *multiBill;
@property (nonatomic ,strong) LMRamGroupInfo *groupInfo;
@property (nonatomic ,strong) LMRamMemberInfo *sender;

@property (nonatomic ,strong) NSMutableArray *transferMembers;
@property (nonatomic ,copy) NSString *amountStr;

@end

@implementation LMMultiTransferDetailController

- (instancetype)initWithBill:(Bill *)bill groupInfo:(LMRamGroupInfo *)groupInfo {
    if (self = [super init]) {
        self.multiBill = bill;
        self.groupInfo = groupInfo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.transferMembers = [NSMutableArray array];
    NSArray *reciverUids = [self.multiBill.receiver componentsSeparatedByString:@","];
    for (NSString *uid in reciverUids) {
        for (LMRamMemberInfo *member in self.groupInfo.membersArray) {
            if ([member.pubKey isEqualToString:uid]) {
                [self.transferMembers addObject:member];
                break;
            }
        }
    }
    self.amountStr = [NSString stringWithFormat:@"%@ BTC",[PayTool getBtcStringWithAmount:self.multiBill.amount / reciverUids.count]];
    for (LMRamMemberInfo *member in self.groupInfo.membersArray) {
        if ([member.address isEqualToString:self.multiBill.sender]) {
            self.sender = member;
            break;
        }
    }
    [self createUI];
    
}

- (void)createUI {

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"转账详情";
    
    
    self.topView = [UIView new];
    self.topView.frame = CGRectMake(0, 0, DEVICE_SIZE.width, DEVICE_SIZE.height * 0.35);
    
    self.senderHeaderImageView = [UIImageView new];
    [self.senderHeaderImageView setPlaceholderImageWithAvatarUrl:self.sender.avatar];
    [self.topView addSubview:self.senderHeaderImageView];
    [self.senderHeaderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topView);
        make.top.equalTo(self.topView).offset(AUTO_HEIGHT(40));
        make.size.mas_equalTo(AUTO_SIZE(150, 150));
    }];
    
    
    self.senderNameLabel = [UILabel new];
    self.senderNameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    self.senderNameLabel.text = self.sender.groupNicksName.length ? self.sender.groupNicksName:self.sender.username;
    [self.topView addSubview:self.senderNameLabel];
    [self.senderNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topView);
        make.top.equalTo(self.senderHeaderImageView.mas_bottom).offset(AUTO_HEIGHT(30));
    }];
    
    self.totalAmountLabel = [UILabel new];
    self.totalAmountLabel.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
    self.totalAmountLabel.text = [NSString stringWithFormat:@"一共发出 %@ BTC",[PayTool getBtcStringWithAmount:self.multiBill.amount]];
    [self.topView addSubview:self.totalAmountLabel];
    [self.totalAmountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.topView);
        make.top.equalTo(self.senderNameLabel.mas_bottom).offset(AUTO_HEIGHT(30));
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerNib:[UINib nibWithNibName:@"LMMultiTransferCell" bundle:nil] forCellReuseIdentifier:@"cellId"];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = self.topView;
}

#pragma mark -UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.transferMembers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMMultiTransferCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId" forIndexPath:indexPath];
    LMRamMemberInfo *member = [self.transferMembers objectAtIndex:indexPath.row];
    [cell.headerImageView setPlaceholderImageWithAvatarUrl:member.avatar];
    cell.nameLabel.text = member.groupNicksName.length ? member.groupNicksName:member.username;
    cell.amountLabel.text = self.amountStr;
    return cell;
}

@end
