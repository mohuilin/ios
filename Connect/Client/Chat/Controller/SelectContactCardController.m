//
//  SelectContactCardController.m
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SelectContactCardController.h"
#include "NSString+Pinyin.h"
#import "ConnectTableHeaderView.h"
#import "LinkmanFriendCell.h"
#import "UserDBManager.h"
#import "LMLinkManDataManager.h"


@interface SelectContactCardController ()

@property(nonatomic, strong) NSMutableArray *groupsFriend;
@property(nonatomic, strong) NSMutableArray *indexs;
@property(nonatomic, copy) void (^SelectContactComplete)(AccountInfo *user);
@property(nonatomic, copy) void (^Cancel)();
@property(nonatomic, strong) AccountInfo *talkUser;

@end

@implementation SelectContactCardController


- (instancetype)initWihtTalkUser:(AccountInfo *)talkUser complete:(void (^)(AccountInfo *user))complete cancel:(void (^)())cancel {
    if (self = [super init]) {
        self.SelectContactComplete = complete;
        self.Cancel = cancel;
        self.talkUser = talkUser;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItems = nil;
    [self setNavigationLeftWithTitle:LMLocalizedString(@"Common Cancel", nil)];
    [self configTableView];
    self.title = LMLocalizedString(@"Chat Send a namecard", nil);
    [[LMLinkManDataManager sharedManager] getRecommandUserGroupArrayChatUser:self.talkUser complete:^(NSMutableArray *groupArray, NSMutableArray *indexs) {
        self.groupsFriend = groupArray;
        self.indexs = indexs;
        [GCDQueue executeInMainQueue:^{
          [self.tableView reloadData];
        }];
    }];
}

- (void)doLeft:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
    [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    self.tableView.rowHeight = 50;
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Table view data source

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CellGroup *group = [self.groupsFriend objectAtIndex:section];
    return group.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupsFriend.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    CellGroup *group = [self.groupsFriend objectAtIndex:section];
    hearderView.customTitle.text = group.headTitle;
    hearderView.customIcon = group.headTitleImage;
    return hearderView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LinkmanFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
    CellGroup *group = [self.groupsFriend objectAtIndex:indexPath.section];
    AccountInfo *user = [group.items objectAtIndex:indexPath.row];
    cell.data = user;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CellGroup *group = [self.groupsFriend objectAtIndex:indexPath.section];
    AccountInfo *user = [group.items objectAtIndex:indexPath.row];
    __weak __typeof(&*self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.SelectContactComplete) {
            weakSelf.SelectContactComplete(user);
        }
    }];
}

#pragma mark - getter setter

-(void)dealloc {
    [self.groupsFriend removeAllObjects];
    self.groupsFriend = nil;
    [self.indexs removeAllObjects];
    self.indexs = nil;
}
@end
