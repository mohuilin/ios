//
//  LMShareContactViewController.m
//  Connect
//
//  Created by bitmain on 2017/1/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

//
//  ReconmandChatListPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMShareContactViewController.h"
#import "RecentChatDBManager.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "UserDBManager.h"
#import "LinkmanFriendCell.h"
#import "NSString+Pinyin.h"
#import "GroupDBManager.h"
#import "ConnectTableHeaderView.h"
#import "LMRetweetMessageManager.h"
#import "LMLinkManDataManager.h"
#import "RegexKit.h"
#import "LMRamGroupInfo.h"
#import "LMContactAccountInfo.h"
#import "LMRamGroupInfo.h"
#import "LMMessageTool.h"

@interface LMShareContactViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) AccountInfo *contact;
@property(nonatomic, strong) LMRerweetModel *retweetModel;
@property(nonatomic, strong) NSMutableArray *groupsFriendArray;
@property(nonatomic, strong) NSMutableArray *indexsArray;



@end

@implementation LMShareContactViewController

- (instancetype)initWithRetweetModel:(LMRerweetModel *)retweetModel {
    if (self = [super init]) {
        self.retweetModel = retweetModel;
    }
    return self;
}
- (instancetype)initWithAccount:(AccountInfo *)contact {
    if (self = [super init]) {
        self.contact = contact;
    }
    return self;
}
#pragma mark - 懒加载


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [self.tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
        [self.tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
        self.tableView.rowHeight = AUTO_HEIGHT(100);
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        self.tableView.sectionIndexTrackingBackgroundColor = [UIColor clearColor];
        self.tableView.sectionIndexColor = LMBasicDarkGray;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return _tableView;
}
- (NSMutableArray *)groupsFriendArray {
    if (!_groupsFriendArray) {
        self.groupsFriendArray = [NSMutableArray array];
    }
    return _groupsFriendArray;
}
- (NSMutableArray *)indexsArray {
    if (!_indexsArray) {
        self.indexsArray = [NSMutableArray array];
    }
    return _indexsArray;
}
#pragma mark - 方法的响应

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Link Share", nil);
    [self.view addSubview:self.tableView];
    //dudge is retweet
    if (self.retweetModel) {
      self.contact = [[UserDBManager sharedManager] getUserByPublickey:self.retweetModel.retweetMessage.messageOwer];
    }
    [[LMLinkManDataManager sharedManager] getRecommandGroupArrayWithRecommonUser:self.contact complete:^(NSMutableArray *groupArray, NSMutableArray *indexs) {
         self.groupsFriendArray = groupArray;
         self.indexsArray = indexs;
        [GCDQueue executeInMainQueue:^{
           [self.tableView reloadData];
        }];
    }];
    
    
}
#pragma mark - Table view data source

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexsArray.copy;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CellGroup *group = [self.groupsFriendArray objectAtIndex:section];
    return group.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupsFriendArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    
    CellGroup *group = [self.groupsFriendArray objectAtIndex:section];
    hearderView.customTitle.text = group.headTitle;
    hearderView.customIcon = group.headTitleImage;
    return hearderView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CellGroup *group = [self.groupsFriendArray objectAtIndex:indexPath.section];
    id data = [group.items objectAtIndex:indexPath.row];
    LinkmanFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
    cell.data = data;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CellGroup *group = [self.groupsFriendArray objectAtIndex:indexPath.section];
    id data = [group.items objectAtIndex:indexPath.row];
    __weak __typeof(&*self) weakSelf = self;
    NSString *displayName = nil;
    if ([data isKindOfClass:[LMRamGroupInfo class]]) {
        LMRamGroupInfo *groupInfo = (LMRamGroupInfo *) data;
        displayName = groupInfo.groupName;
    } else {
        LMContactAccountInfo *contact = (LMContactAccountInfo *)data;
        data = contact.normalInfo;
        displayName = contact.username;
    }
    NSString *title = [NSString stringWithFormat:LMLocalizedString(@"Chat Share contact to", nil), self.contact.username, displayName];
    if (self.retweetModel) {
        if (self.retweetModel.retweetMessage.messageType == GJGCChatFriendContentTypeVideo) {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send video to", nil), displayName];
        } else if (self.retweetModel.retweetMessage.messageType == GJGCChatFriendContentTypeImage) {
            title = [NSString stringWithFormat:LMLocalizedString(@"Chat Send image to", nil), displayName];
        } else {
            title = [NSString stringWithFormat:LMLocalizedString(@"Link Send to", nil), displayName];
        }
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf sendShareCardMessageWithChat:data];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    alertController.automaticallyAdjustsScrollViewInsets = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)sendShareCardMessageWithChat:(id)data {
    if (self.retweetModel) {
        self.retweetModel.toFriendModel = data;
        __weak __typeof(&*self) weakSelf = self;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeAnnularDeterminate;
        hud.labelText = LMLocalizedString(@"Common Loading", nil);
        [[LMRetweetMessageManager sharedManager] retweetMessageWithModel:self.retweetModel complete:^(NSError *error, float progress) {
            [GCDQueue executeInMainQueue:^{
                if (!error) {
                    if (progress <= 1) {
                        hud.progress = progress;
                    } else {
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Send successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }
                } else {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Send failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }
            }];
        }];
    } else {
        [MBProgressHUD showMessage:LMLocalizedString(@"Sending...", nil) toView:self.view];
        // create name card
        ChatMessageInfo *messageInfo = nil;
        if ([data isKindOfClass:[AccountInfo class]]) {
            AccountInfo *info = (AccountInfo *) data;
            messageInfo = [LMMessageTool makeCardChatMessageWithUsername:self.contact.username avatar:self.contact.avatar uid:self.contact.pub_key msgOwer:info.pub_key sender:[[LKUserCenter shareCenter] currentLoginUser].address];
        } else {
            LMRamGroupInfo *info = (LMRamGroupInfo *) data;
            messageInfo = [LMMessageTool makeCardChatMessageWithUsername:self.contact.username avatar:self.contact.avatar uid:self.contact.pub_key msgOwer:info.groupIdentifer sender:[[LKUserCenter shareCenter] currentLoginUser].address];
        }
        messageInfo.sendstatus = GJGCChatFriendSendMessageStatusSending;
        [[MessageDBManager sharedManager] saveMessage:messageInfo];

        if ([data isKindOfClass:[LMRamGroupInfo class]]) {
            LMRamGroupInfo *info = (LMRamGroupInfo *) data;
            // creat new session
            [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:info.groupIdentifer groupChat:YES lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:messageInfo.messageType textMessage:@""] ecdhKey:info.groupEcdhKey talkName:nil];
        } else {
            AccountInfo *info = (AccountInfo *) data;
            NSString *ecdhKey = [KeyHandle getECDHkeyUsePrivkey:[LKUserCenter shareCenter].currentLoginUser.prikey PublicKey:info.pub_key];
            [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:info.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:messageInfo.messageType textMessage:@""] ecdhKey:ecdhKey talkName:nil];
        }
    }
}

- (void)dealloc {
    
    [self.tableView removeFromSuperview];
    self.tableView = nil;
    [self.indexsArray removeAllObjects];
    self.indexsArray = nil;
    [self.groupsFriendArray removeAllObjects];
    self.groupsFriendArray = nil;
    
}
@end

