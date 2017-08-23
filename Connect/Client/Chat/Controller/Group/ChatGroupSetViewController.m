//
//  ChatGroupSetViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatGroupSetViewController.h"
#import "ChatGroupSetGroupNameViewController.h"
#import "ChatSetMyNameViewController.h"
#import "ChooseContactViewController.h"
#import "GroupMembersListViewController.h"
#import "LMchatGroupQRCodeViewController.h"
#import "LMchatGroupManageViewController.h"
#import "NetWorkOperationTool.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"
#import "RecentChatDBManager.h"
#import "IMService.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "YYImageCache.h"
#import "MessageDBManager.h"
#import "LMRamGroupInfo.h"
#import "LMRamMemberInfo.h"
#import "LMMessageAdapter.h"
#import "LMMessageTool.h"
#import "LMConnectIMChater.h"


typedef NS_ENUM(NSUInteger, SourceType) {
    SourceTypeGroup = 5
};

@interface ChatGroupSetViewController ()

@property(nonatomic, copy) NSString *currentGroupName;

@property(nonatomic, copy) NSString *currentMyName;

@property(nonatomic, weak) GJGCChatFriendTalkModel *talkModel;

@property(nonatomic, strong) NSArray *members;

@property(assign, nonatomic) BOOL isGroupMaster;

@property(weak, nonatomic) LMRamMemberInfo *groupMasterInfo;
//Show arrow
@property(assign, nonatomic) BOOL isHaveSow;
@property(nonatomic, strong) RLMNotificationToken *groupToken;
@property(nonatomic, strong) LMRamGroupInfo *groupInfo;

@end


@implementation ChatGroupSetViewController


- (instancetype)initWithTalkInfo:(GJGCChatFriendTalkModel *)talkInfo {
    if (self = [super init]) {
        self.talkModel = talkInfo;
        NSMutableArray *temArray = [NSMutableArray array];
        AccountInfo *currentUser = [[LKUserCenter shareCenter] currentLoginUser];
        self.currentGroupName = talkInfo.chatGroupInfo.groupName;
        for (LMRamMemberInfo *member in talkInfo.chatGroupInfo.membersArray) {
            if ([currentUser.address isEqualToString:member.address]) {
                self.currentMyName = member.groupNicksName;
            }
            [temArray addObject:member];
        }
        self.members = temArray;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self syncGroupBaseInfo];
    if ([self.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        self.isHaveSow = YES;
    } else if (!self.talkModel.chatGroupInfo.isPublic) {
        self.isHaveSow = YES;
    }
    self.title = LMLocalizedString(@"Link Group", nil);
    
    
    self.groupInfo = self.talkModel.chatGroupInfo;
    RegisterNotify(ConnnectGroupInfoDidChangeNotification, @selector(grouInfoChange:))
    [self addNotification];
}
- (void)addNotification {
    __weak typeof(self.groupInfo)weakGroupInfo = self.groupInfo;
    __weak typeof(self)weakSelf = self;
   self.groupToken = [self.groupInfo addNotificationBlock:^(BOOL deleted, NSArray<RLMPropertyChange *> * _Nullable changes, NSError * _Nullable error) {
       if (!error) {
           for (RLMPropertyChange *property in changes) {
               if ([property.name isEqualToString:@"admin"]) {
                   [weakSelf addChnageGroupAdmin:weakGroupInfo];
               }
           }
       }
   }];
}
- (void)addChnageGroupAdmin:(LMRamGroupInfo *)groupInfo {
    NSMutableArray *temArray = [NSMutableArray array];
    for (LMRamMemberInfo *info in groupInfo.membersArray) {
        [temArray addObject:info];
    }
    self.members = temArray.copy;
    [GCDQueue executeInMainQueue:^{
       [self reloadDataOnMainQueue];
    }];
  
}
- (void)syncGroupBaseInfo {
    GroupId *groupIdentifier = [GroupId new];
    groupIdentifier.identifier = self.talkModel.chatGroupInfo.groupIdentifer;

    [NetWorkOperationTool POSTWithUrlString:GroupSyncSettingInfoUrl postProtoData:groupIdentifier.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GroupSettingInfo *groupSetInfo = [GroupSettingInfo parseFromData:data error:&error];
            [[GroupDBManager sharedManager] executeRealmWithBlock:^{
                self.talkModel.chatGroupInfo.isPublic = groupSetInfo.public_p;
                self.talkModel.chatGroupInfo.isGroupVerify = groupSetInfo.reviewed;
                self.talkModel.chatGroupInfo.avatarUrl = groupSetInfo.avatar;
                self.talkModel.chatGroupInfo.summary = groupSetInfo.summary;
            }];
            if ([[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:self.talkModel.chatIdendifier] != groupSetInfo.mute) {
                if (groupSetInfo.mute) {
                    [[RecentChatDBManager sharedManager] setMuteWithIdentifer:self.talkModel.chatIdendifier];
                } else {
                    [[RecentChatDBManager sharedManager] removeMuteWithIdentifer:self.talkModel.chatIdendifier];
                }
            }
            [[GroupDBManager sharedManager] updateGroupPublic:groupSetInfo.public_p reviewed:groupSetInfo.reviewed summary:groupSetInfo.summary avatar:groupSetInfo.avatar withGroupId:self.talkModel.chatGroupInfo.groupIdentifer];
            [self reloadDataOnMainQueue];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:GroupSyncSettingInfoUrl] withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];

}

- (void)grouInfoChange:(NSNotification *)note {
    NSString *groupIdentifer = (NSString *) note.object;

    LMRamGroupInfo *group = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:groupIdentifer];
    self.talkModel.chatGroupInfo = group;
    NSMutableArray *temArray = [NSMutableArray array];
    for (LMRamMemberInfo *info in group.membersArray) {
        [temArray addObject:info];
    }
    self.members = temArray.copy;
    NSMutableArray *avatars = [NSMutableArray array];
    for (LMRamMemberInfo *membser in group.membersArray) {
        if (avatars.count == 9) {
            break;
        }
        [avatars objectAddObject:membser.avatar];
    }
    self.currentGroupName = group.groupName;
    AccountInfo *currentUser = [[LKUserCenter shareCenter] currentLoginUser];
    for (LMRamMemberInfo *info in group.membersArray) {
        if ([currentUser.address isEqualToString:info.address]) {
            self.currentMyName = info.groupNicksName;
            break;
        }
    }
    [self reloadDataOnMainQueue];
}

- (void)reloadDataOnMainQueue {
    [GCDQueue executeInMainQueue:^{
        [self setupCellData];
        [self.tableView reloadData];
    }];
}

- (void)setupCellData {

    __weak typeof(self) weakSelf = self;
    [self.groups removeAllObjects];
    CellGroup *group0 = [[CellGroup alloc] init];
    group0.headTitle = [NSString stringWithFormat:LMLocalizedString(@"Link Members", nil), (unsigned long) self.members.count];

    CellItem *groupMembers = [[CellItem alloc] init];
    groupMembers.type = CellItemTypeGroupMemberCell;

    groupMembers.operation = ^{
        [weakSelf showMembersListPage];
    };

    groupMembers.array = self.members;
    group0.items = @[groupMembers].copy;
    [self.groups objectAddObject:group0];

    CellItem *groupName = [CellItem itemWithIcon:@"message_groupchat_name" title:LMLocalizedString(@"Link Group Name", nil) type:CellItemTypeImageValue1 operation:^{

        if ([weakSelf.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            ChatGroupSetGroupNameViewController *groupName = [[ChatGroupSetGroupNameViewController alloc] initWithCurrentName:weakSelf.currentGroupName groupid:weakSelf.talkModel.chatIdendifier];
            [weakSelf.navigationController pushViewController:groupName animated:YES];
        } else if (!weakSelf.talkModel.chatGroupInfo.isPublic) {
            ChatGroupSetGroupNameViewController *groupName = [[ChatGroupSetGroupNameViewController alloc] initWithCurrentName:weakSelf.currentGroupName groupid:weakSelf.talkModel.chatIdendifier];
            [weakSelf.navigationController pushViewController:groupName animated:YES];
        }
    }];
    groupName.subTitle = self.currentGroupName;
    groupName.tag = SourceTypeGroup;

    CellItem *myName = [CellItem itemWithIcon:@"message_groupchat_myname" title:LMLocalizedString(@"Link My Alias in Group", nil) type:CellItemTypeImageValue1 operation:^{
        LMRamMemberInfo *currentUser = [[GroupDBManager sharedManager] getGroupMemberByGroupId:weakSelf.talkModel.chatIdendifier memberAddress:[LKUserCenter shareCenter].currentLoginUser.address];
        ChatSetMyNameViewController *myName = [[ChatSetMyNameViewController alloc] initWithUpdateUser:currentUser groupIdentifier:weakSelf.talkModel.chatIdendifier];
        [weakSelf.navigationController pushViewController:myName animated:YES];
    }];
    myName.subTitle = self.currentMyName;
    NSString *displayName = LMLocalizedString(@"Link Group is QR Code", nil);
    CellItem *groupQRCode = [CellItem itemWithIcon:@"message_groupchat_qrcode-1" title:displayName type:CellItemTypeImageValue1 operation:^{
        LMchatGroupQRCodeViewController *QRCodeVc = [[LMchatGroupQRCodeViewController alloc] init];
        QRCodeVc.talkModel = weakSelf.talkModel;
        QRCodeVc.titleName = displayName;
        [weakSelf.navigationController pushViewController:QRCodeVc animated:YES];

    }];
    CellGroup *group1 = [[CellGroup alloc] init];
    if ([self.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
        NSString *displayName = LMLocalizedString(@"Link ManageGroup", nil);
        CellItem *manageGroup = [CellItem itemWithIcon:@"message_groupchat_setting" title:displayName type:CellItemTypeImageValue1 operation:^{
            LMchatGroupManageViewController *manageGroup = [[LMchatGroupManageViewController alloc] init];
            manageGroup.switchChangeBlock = ^(BOOL isPublic) {
                [[GroupDBManager sharedManager] executeRealmWithBlock:^{
                    weakSelf.talkModel.chatGroupInfo.isPublic = isPublic;
                }];
            };
            manageGroup.titleName = displayName;
            manageGroup.talkModel = weakSelf.talkModel;
            manageGroup.groupAdminChangeCallBack = ^(NSString *address) {
                [weakSelf addChnageGroupAdmin:weakSelf.groupInfo];
            };
            [weakSelf.navigationController pushViewController:manageGroup animated:YES];
        }];
        group1.items = @[groupName, myName, groupQRCode, manageGroup].copy;
    } else {
        group1.items = @[groupName, myName, groupQRCode].copy;
    }

    [self.groups objectAddObject:group1];

    CellItem *topMessage = [CellItem itemWithTitle:LMLocalizedString(@"Chat Sticky on Top chat", nil) type:CellItemTypeSwitch operation:nil];
    topMessage.switchIsOn = self.talkModel.top;
    topMessage.operationWithInfo = ^(id userInfo) {
        BOOL top = [userInfo boolValue];
        if (top) {
            [SetGlobalHandler topChatWithChatIdentifer:weakSelf.talkModel.chatIdendifier];
        } else {
            [SetGlobalHandler CancelTopChatWithChatIdentifer:weakSelf.talkModel.chatIdendifier];
        }
        weakSelf.talkModel.top = top;
    };

    CellItem *messageNoneNotifi = [CellItem itemWithTitle:LMLocalizedString(@"Chat Mute Notification", nil) type:CellItemTypeSwitch operation:nil];
    messageNoneNotifi.switchIsOn = self.talkModel.mute;
    messageNoneNotifi.operationWithInfo = ^(id userInfo) {
        BOOL notify = [userInfo boolValue];
        [SetGlobalHandler GroupChatSetMuteWithIdentifer:weakSelf.talkModel.chatIdendifier mute:notify complete:^(NSError *erro) {
            if (!erro) {
                if (notify) {
                    [[RecentChatDBManager sharedManager] setMuteWithIdentifer:weakSelf.talkModel.chatIdendifier];
                } else {
                    [[RecentChatDBManager sharedManager] removeMuteWithIdentifer:weakSelf.talkModel.chatIdendifier];
                }
                weakSelf.talkModel.mute = notify;
            }
        }];
    };

    CellItem *savaToContact = [CellItem itemWithTitle:LMLocalizedString(@"Link Save to Contacts", nil) type:CellItemTypeSwitch operation:nil];
    savaToContact.switchIsOn = self.talkModel.chatGroupInfo.isCommonGroup;
    savaToContact.operationWithInfo = ^(id userInfo) {
        BOOL isCommonGroup = [userInfo boolValue];
        if (isCommonGroup) {
            [SetGlobalHandler setCommonContactGroupWithIdentifer:weakSelf.talkModel.chatIdendifier complete:^(NSError *error) {
                if (!error) {
                    [[GroupDBManager sharedManager] updateGroupStatus:YES groupId:weakSelf.talkModel.chatIdendifier];
                    [[GroupDBManager sharedManager] executeRealmWithBlock:^{
                       weakSelf.talkModel.chatGroupInfo.isCommonGroup = isCommonGroup;
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Update fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:2];
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];
                }
            }];
        } else {
            [SetGlobalHandler removeCommonContactGroupWithIdentifer:weakSelf.talkModel.chatIdendifier complete:^(NSError *error) {
                if (!error) {
                    [[GroupDBManager sharedManager] updateGroupStatus:NO groupId:weakSelf.talkModel.chatIdendifier];
                    [[GroupDBManager sharedManager] executeRealmWithBlock:^{
                      weakSelf.talkModel.chatGroupInfo.isCommonGroup = isCommonGroup;
                    }];
                } else {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:2];
                        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];
                }
            }];
        }
    };

    CellGroup *group2 = [[CellGroup alloc] init];
    group2.headTitle = LMLocalizedString(@"Link Group Setting", nil);
    group2.items = @[topMessage, messageNoneNotifi, savaToContact].copy;
    [self.groups objectAddObject:group2];

    CellGroup *group3 = [[CellGroup alloc] init];
    group3.headTitle = LMLocalizedString(@"Link Other", nil);

    CellItem *clearHistory = [CellItem itemWithIcon:@"chat_friend_set_clearhistory" title:LMLocalizedString(@"Link Clear Chat History", nil) type:CellItemTypeNone operation:^{

        UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *clearHistoryAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Clear Chat History", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [weakSelf clearAllChatHistory];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

        [actionController addAction:clearHistoryAction];
        [actionController addAction:cancelAction];
        [weakSelf presentViewController:actionController animated:YES completion:nil];


    }];
    CellItem *leaveGroup = [CellItem itemWithIcon:@"message_group_leave" title:LMLocalizedString(@"Link Delete and Leave", nil) type:CellItemTypeNone operation:^{
        UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Delete and Leave", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showLoadingMessageToView:weakSelf.view];
            }];
            [SetGlobalHandler quitGroupWithIdentifer:weakSelf.talkModel.chatIdendifier complete:^(NSError *erro) {
                [GCDQueue executeInMainQueue:^{
                    if (!erro) {
                        [[YYImageCache sharedCache] removeImageForKey:weakSelf.talkModel.chatGroupInfo.avatarUrl];
                        [MBProgressHUD hideHUDForView:weakSelf.view];
                        [[GroupDBManager sharedManager] deletegroupWithGroupId:weakSelf.talkModel.chatIdendifier];
                        [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                    } else {
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Network connection failed please check network", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }
                }];
            }];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

        [actionController addAction:deleteAction];
        [actionController addAction:cancelAction];
        [weakSelf presentViewController:actionController animated:YES completion:nil];

    }];

    clearHistory.type = CellItemTypeNone;

    group3.items = @[clearHistory, leaveGroup].copy;
    [self.groups objectAddObject:group3];

}

- (void)clearAllChatHistory {
    //delete file
    AccountInfo *chatUser = [[UserDBManager sharedManager] getUserByPublickey:self.talkModel.chatIdendifier];
    if (chatUser) {
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:chatUser.address];
    } else {
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:self.talkModel.chatIdendifier];
    }
    
    //delete message
    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:self.talkModel.chatIdendifier];
    
    //delete recentchat last contetn
    [[RecentChatDBManager sharedManager] removeLastContentWithIdentifier:self.talkModel.chatIdendifier];
    [GCDQueue executeInMainQueue:^{
        SendNotify(DeleteMessageHistoryNotification, self.talkModel.chatIdendifier);
    }];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    __weak __typeof(&*self) weakSelf = self;
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
        cell.textLabel.text = item.title;
        return cell;
    } else if (item.type == CellItemTypeGroupMemberCell) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"GroupMembersCellID"];
        GroupMembersCell *memberCell = (GroupMembersCell *) cell;
        memberCell.data = self.members;
        memberCell.tapAddMemberBlock = ^{
            [weakSelf showAccountListPage];
        };

        memberCell.tapMemberHeaderBlock = ^(LMRamMemberInfo *tapInfo) {
            AccountInfo *userInfo = (AccountInfo *)tapInfo.normalInfo;
            [weakSelf showUserDetailPageWithUser:userInfo];
        };
        return cell;
    } else if (item.type == CellItemTypeNone) {

        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
        cell.textLabel.text = item.title;
        cell.imageView.image = [UIImage imageNamed:item.icon];
        cell.detailTextLabel.text = item.subTitle;

    } else if (item.type == CellItemTypeImageValue1) {

        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellImageValue1ID"];
        NCellImageValue1 *imageCell = (NCellImageValue1 *) cell;
        imageCell.tag = item.tag;
        imageCell.data = item;
        if (imageCell.tag == SourceTypeGroup) {
            if (self.isHaveSow) {
                imageCell.arrowImageView.hidden = NO;
            } else {
                imageCell.arrowImageView.hidden = YES;
            }
        } else {
            imageCell.arrowImageView.hidden = NO;
        }
    }
    return cell;
}

- (void)addNewGroupMembers:(NSArray *)contacts {
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    }];
    [self verifyWith:contacts];
}

- (void)verifyWith:(NSArray *)contacts {
    NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
    NSMutableArray *addresses = [NSMutableArray array];
    for (AccountInfo *user in contacts) {
        [addresses objectAddObject:user.address];
        [userDict setObject:user forKey:user.address];
    }

    GroupInviteUser *inviteUser = [GroupInviteUser new];
    inviteUser.identifier = self.talkModel.chatGroupInfo.groupIdentifer;
    inviteUser.addressesArray = addresses;
    [NetWorkOperationTool POSTWithUrlString:GroupInviteTokenUrl postProtoData:inviteUser.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:hResponse.message withType:ToastTypeFail showInView:self.view complete:nil];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            GroupInviteResponseList *tokenList = [GroupInviteResponseList parseFromData:data error:nil];
            for (GroupInviteResponse *tokenResponse in tokenList.listArray) {
                AccountInfo *info = [userDict valueForKey:tokenResponse.address];
                if (GJCFStringIsNull(info.address)) {
                    continue;
                }
                if ([info.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
                    continue;
                }
                ChatMessageInfo *chatMessage = [LMMessageTool makeJoinGroupChatMessageWithAvatar:self.talkModel.chatGroupInfo.avatarUrl ? self.talkModel.chatGroupInfo.avatarUrl : @"" groupId:self.talkModel.chatGroupInfo.groupIdentifer groupName:self.talkModel.chatGroupInfo.groupName token:tokenResponse.token msgOwer:info.pub_key sender:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
                [[MessageDBManager sharedManager] saveMessage:chatMessage];
                [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:info.pub_key groupChat:NO lastContentShowType:0 lastContent:[GJGCChatFriendConstans lastContentMessageWithType:chatMessage.messageType msgContent:chatMessage.msgContent]];
                /// 发送消息
                [[LMConnectIMChater sharedManager] sendChatMessageInfo:chatMessage progress:nil complete:^(ChatMessageInfo *chatMsgInfo, NSError *error) {
                    
                }];
            }
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:self.view];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Server error,Try later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }];
}

- (void)inviteNewMembers:(NSArray *)membsers {

    __weak typeof(self) weakSelf = self;
    LMRamGroupInfo *group = [[GroupDBManager sharedManager] addMember:membsers ToGroupChat:weakSelf.talkModel.chatIdendifier];
    NSMutableArray *temArray = [NSMutableArray array];
    for (LMRamMemberInfo *info in group.membersArray) {
        [temArray addObject:info];
    }
    self.members = temArray.copy;
    [self reloadDataOnMainQueue];

    NSMutableString *welcomeTip = [NSMutableString string];
    CreateGroupMessage *groupMessage = [[CreateGroupMessage alloc] init];
    groupMessage.secretKey = weakSelf.talkModel.group_ecdhKey;
    groupMessage.identifier = weakSelf.talkModel.chatIdendifier;

    for (AccountInfo *info in membsers) {

        if ([info.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
            continue;
        }
        [welcomeTip appendString:info.username];
        if (info != [membsers lastObject]) {
            [welcomeTip appendString:@"、"];
        }
        [[LMConnectIMChater sharedManager] sendCreateGroupMsg:groupMessage to:info.pub_key];
    }
}

- (void)showAccountListPage {
    //Transformation model
    NSMutableArray *temArray = [NSMutableArray array];
    for (LMRamMemberInfo *memberInfo in self.members) {
        AccountInfo *accountInfo = (AccountInfo *)memberInfo.normalInfo;
        [temArray addObject:accountInfo];
    }
    ChooseContactViewController *page = [[ChooseContactViewController alloc] initWithChooseComplete:^(NSArray *selectContactArray) {
        DDLogInfo(@"%@", selectContactArray);
        [self addNewGroupMembers:selectContactArray];
    }                                                                          defaultSelectedUsers:temArray];

    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
}

- (void)showMembersListPage {
    if (GJCFStringIsNull(self.talkModel.chatIdendifier) || GJCFStringIsNull(self.talkModel.group_ecdhKey)) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Unknown error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
        return;
    }
    GroupMembersListViewController *page1 = [[GroupMembersListViewController alloc] initWithMemberInfos:self.members groupIdentifer:self.talkModel.chatIdendifier groupEchhKey:self.talkModel.group_ecdhKey];
    page1.talkInfo = self.talkModel;
    page1.isGroupMaster = [self.talkModel.chatGroupInfo.admin.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address];
    [self.navigationController pushViewController:page1 animated:YES];
}

- (void)showUserDetailPageWithUser:(AccountInfo *)user {

    AccountInfo *localUser = [[UserDBManager sharedManager] getUserByAddress:user.address];
    if (localUser) {
        user = localUser;
    }

    if ([user.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
        return;
    }
    
    if (!user.stranger) {
        UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
        [self.navigationController pushViewController:page animated:YES];
    } else {
        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
        page.sourceType = UserSourceTypeGroup;
        [self.navigationController pushViewController:page animated:YES];
    }
}

- (void)dealloc {
    self.talkModel = nil;
    RemoveNofify;
    [self.groupToken stop];
    self.groupToken = nil;
    
}
@end
