//
//  ChatFriendSetViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatFriendSetViewController.h"
#import "ChooseContactViewController.h"
#import "IMService.h"
#import "NetWorkOperationTool.h"
#import "GroupDBManager.h"
#import "RecentChatDBManager.h"
#import "UserDBManager.h"
#import "UserDetailPage.h"
#import "InviteUserPage.h"
#import "MessageDBManager.h"
#import "StringTool.h"
#import "AppDelegate.h"
#import "LMRamGroupInfo.h"
#import "LMRamMemberInfo.h"
#import "LMIMHelper.h"
#import "LMMessageAdapter.h"

@interface ChatFriendSetViewController ()

@property(nonatomic, strong) NSMutableArray *members;
@property(nonatomic, strong) GJGCChatFriendTalkModel *talkModel;
@property(nonatomic, copy) NSString *groupEcdhKey;

@end

@implementation ChatFriendSetViewController

- (instancetype)initWithTalkModel:(GJGCChatFriendTalkModel *)talkModel {
    if (self = [super init]) {
        self.members = [NSMutableArray array];
        [self.members addObject:talkModel.chatUser];
        self.talkModel = talkModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Detail", nil);
}

- (void)setupCellData {
    __weak __typeof(&*self) weakSelf = self;

    //-----
    CellGroup *group = [[CellGroup alloc] init];
    CellItem *item = [[CellItem alloc] init];
    item.type = CellItemTypeGroupMemberCell;
    item.array = self.members;
    group.items = @[item].copy;
    [self.groups objectAddObject:group];

    CellItem *topMessage = [CellItem itemWithTitle:LMLocalizedString(@"Chat Sticky on Top", nil) type:CellItemTypeSwitch operation:nil];
    topMessage.switchIsOn = self.talkModel.top;
    topMessage.operationWithInfo = ^(id userInfo) {
        if ([userInfo boolValue]) {
            [SetGlobalHandler topChatWithChatIdentifer:weakSelf.talkModel.chatUser.pub_key];
        } else {
            [SetGlobalHandler CancelTopChatWithChatIdentifer:weakSelf.talkModel.chatUser.pub_key];
        }
    };
    CellItem *messageNoneNotifi = [CellItem itemWithTitle:LMLocalizedString(@"Chat Mute Notification", nil) type:CellItemTypeSwitch operation:nil];
    messageNoneNotifi.switchIsOn = self.talkModel.mute;
    messageNoneNotifi.operationWithInfo = ^(id userInfo) {
        BOOL noti = [userInfo boolValue];
        [[IMService instance] openOrCloseSesionMuteWithAddress:weakSelf.talkModel.chatUser.address mute:noti complete:^(NSError *erro, id data) {
            if (!erro) {
                if (noti) {
                    [[RecentChatDBManager sharedManager] setMuteWithIdentifer:weakSelf.talkModel.chatUser.pub_key];
                } else {
                    [[RecentChatDBManager sharedManager] removeMuteWithIdentifer:weakSelf.talkModel.chatUser.pub_key];
                }
            }
        }];
    };
    CellGroup *group0 = [[CellGroup alloc] init];
    group0.items = @[topMessage, messageNoneNotifi].copy;
    [self.groups objectAddObject:group0];

    //-----
    CellGroup *group1 = [[CellGroup alloc] init];

    CellItem *clearHistory = [CellItem itemWithIcon:@"chat_friend_set_clearhistory" title:LMLocalizedString(@"Link Clear Chat History", nil) type:CellItemTypeNone operation:^{
        UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Clear Chat History", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [weakSelf clearAllChatHistory];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

        [actionController addAction:deleteAction];
        [actionController addAction:cancelAction];
        [weakSelf presentViewController:actionController animated:YES completion:nil];

    }];
    clearHistory.type = CellItemTypeNone;

    group1.items = @[clearHistory].copy;
    [self.groups objectAddObject:group1];
}

- (void)clearAllChatHistory {
    AccountInfo *chatUser = [[UserDBManager sharedManager] getUserByPublickey:self.talkModel.chatUser.pub_key];
    if (chatUser) {
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:chatUser.address];
    } else {
        [ChatMessageFileManager deleteRecentChatAllMessageFilesByAddress:self.talkModel.chatUser.pub_key];
    }
    [[MessageDBManager sharedManager] deleteAllMessageByMessageOwer:self.talkModel.chatUser.pub_key];
    
    //delete recentchat last contetn
    [[RecentChatDBManager sharedManager] removeLastContentWithIdentifier:self.talkModel.chatIdendifier];
    
    [GCDQueue executeInMainQueue:^{
        SendNotify(DeleteMessageHistoryNotification, self.talkModel.chatIdendifier);
    }];

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    /**
     *
     CellItemTypeNone,
     CellItemTypeArrow,
     CellItemTypeSwitch,
     CellItemTypeLabel,
     CellItemTypeTextFieldWithLabel,
     CellItemTypeTextField,
     */

    __weak __typeof(&*self) weakSelf = self;
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
            [weakSelf showUserDetailPageWithUser:(AccountInfo *)tapInfo];
        };

        return cell;
    } else if (item.type == CellItemTypeNone) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
        cell.textLabel.text = item.title;
        cell.imageView.image = [UIImage imageNamed:item.icon];
    }

    return cell;
}

- (void)showUserDetailPageWithUser:(AccountInfo *)user {

    AccountInfo *localUser = [[UserDBManager sharedManager] getUserByAddress:user.address];
    if (localUser) {
        user = localUser;
    }
    if (!user.stranger) {
        UserDetailPage *page = [[UserDetailPage alloc] initWithUser:user];
        [self.navigationController pushViewController:page animated:YES];
    } else {
        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:user];
        page.sourceType = UserSourceTypeTransaction;
        [self.navigationController pushViewController:page animated:YES];
    }
}


- (void)addNewGroupMembers:(NSArray *)contacts {
    NSMutableArray *addMemberArray = [NSMutableArray array];
    [addMemberArray addObjectsFromArray:self.members];
    for (AccountInfo *info in contacts) {
        if ([addMemberArray containsObject:info]) {
            continue;
        }
        [addMemberArray objectAddObject:info];
    }
    self.members = addMemberArray;
    //self.membsers (not contain self)
    [self createGroupRequestWithMembersArray:self.members];

}


- (void)createGroupRequestWithMembersArray:(NSArray *)array {

    NSMutableString *groupName = [NSMutableString string];

    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];
    [groupName appendString:[NSString stringWithFormat:LMLocalizedString(@"Link user friends", nil), loginUser.username]];
    //generate group ecdhkey
    self.groupEcdhKey = [LMIMHelper getECDHkeyUsePrivkey:[LMIMHelper creatNewPrivkey] PublicKey:[LMIMHelper getPubkeyByPrikey:[LMIMHelper creatNewPrivkey]]];

    CreateGroupMessage *groupMessage = [[CreateGroupMessage alloc] init];
    groupMessage.secretKey = self.groupEcdhKey;

    NSMutableArray *addUsersArray = [NSMutableArray array];
    for (AccountInfo *user in array) {
        AddGroupUserInfo *addUser = [[AddGroupUserInfo alloc] init];
        addUser.address = user.address;

        GcmData *groupInfoGcmData = [ConnectTool createGcmWithData:groupMessage.data publickey:user.pub_key needEmptySalt:YES];
        NSString *backUp = [NSString stringWithFormat:@"%@/%@", [[LKUserCenter shareCenter] currentLoginUser].pub_key, [StringTool hexStringFromData:groupInfoGcmData.data]];
        addUser.backup = backUp;
        [addUsersArray objectAddObject:addUser];
    }

    CreateGroup *group = [[CreateGroup alloc] init];
    group.name = groupName;
    group.usersArray = addUsersArray;
    __weak __typeof(&*self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:GroupCreateGroupUrl postProtoData:group.data complete:^(id hresponse) {

        HttpResponse *httpResponse = (HttpResponse *) hresponse;

        if (httpResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Create group fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }
        [weakSelf createGroupCompleteWtihResponse:httpResponse];
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Create group fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}


/**
 *  handle group create response
 *
 *  @param responseObject
 */
- (void)createGroupCompleteWtihResponse:(HttpResponse *)httpResponse {
    NSData *data = [ConnectTool decodeHttpResponse:httpResponse];
    if (data) {
        GroupInfo *group = [GroupInfo parseFromData:data error:nil];
        [self broadcastGroupInfoToAllMembers:group];
    }
}


/**
 *  Broadcast group information to each member
 *
 *  @param groupInfo
 */
- (void)broadcastGroupInfoToAllMembers:(GroupInfo *)groupInfo {
    __weak typeof(self) weakSelf = self;
    if (groupInfo.membersArray.count < 3) {

        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Create group fail", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }

    NSMutableString *content = [NSMutableString string];
    for (AccountInfo *info in self.members) {
        if ([info.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
            continue;
        }
        if ([[self.members lastObject] isEqual:info]) {
            [content appendFormat:@"%@", info.username];
        } else {
            [content appendFormat:@"%@、", info.username];
        }
    }
    content = [NSString stringWithFormat:LMLocalizedString(@"Link invited to the group chat", nil), LMLocalizedString(@"Chat You", nil), content].mutableCopy;
    NSString *groupName = groupInfo.group.name;
    //  [content appendString:LMLocalizedString(@"Link Join Group", nil)];

    LMRamGroupInfo *lmGroup = [[LMRamGroupInfo alloc] init];
    lmGroup.groupName = groupInfo.group.name;
    lmGroup.groupIdentifer = groupInfo.group.identifier;
    lmGroup.groupEcdhKey = self.groupEcdhKey;
    lmGroup.avatarUrl = groupInfo.group.avatar;
    lmGroup.isPublic = groupInfo.group.public_p;
    lmGroup.isGroupVerify = groupInfo.group.reviewed;
    lmGroup.summary = groupInfo.group.summary;

    NSMutableArray *AccoutInfoArray = [NSMutableArray array];
    LMRamMemberInfo *admin = nil;
    for (GroupMember *member in groupInfo.membersArray) {
        LMRamMemberInfo *accountInfo = [[LMRamMemberInfo alloc] init];
        accountInfo.username = member.username;
        accountInfo.avatar = member.avatar;
        accountInfo.address = member.address;
        accountInfo.groupNicksName = member.nick;
        if (accountInfo.groupNicksName.length <= 0) {
            accountInfo.groupNicksName = member.username;
        }
        accountInfo.pubKey = member.pubKey;
        accountInfo.isGroupAdmin = (member.role != 0);
        accountInfo.identifier = groupInfo.group.identifier;
        accountInfo.univerStr = [[NSString stringWithFormat:@"%@%@",accountInfo.address,accountInfo.identifier] sha1String];
        if (!accountInfo.isGroupAdmin) {
            [AccoutInfoArray objectAddObject:accountInfo];
        } else {
            admin = accountInfo;
            lmGroup.admin = accountInfo;
        }
    }
    if (admin) {
        [AccoutInfoArray insertObject:admin atIndex:0];
    }
    [lmGroup.membersArray addObjects:AccoutInfoArray];
    [[GroupDBManager sharedManager] savegroup:lmGroup];

    [[RecentChatDBManager sharedManager] createNewChatWithIdentifier:groupInfo.group.identifier groupChat:YES lastContentShowType:1 lastContent:content ecdhKey:self.groupEcdhKey talkName:groupName];

    [SetGlobalHandler uploadGroupEcdhKey:self.groupEcdhKey groupIdentifier:groupInfo.group.identifier];

    Group *group = groupInfo.group;
    CreateGroupMessage *groupMessage = [[CreateGroupMessage alloc] init];
    groupMessage.secretKey = self.groupEcdhKey;
    groupMessage.identifier = group.identifier;

    for (AccountInfo *info in self.members) {

        if ([info.pub_key isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].pub_key]) {
            continue;
        }
        MessageData *messageData = [LMMessageAdapter packageMessageDataWithTo:info.pub_key chatType:0 msgType:0 ext:nil groupEcdh:nil cipherData:groupMessage];
        NSString *sign = [ConnectTool signWithData:messageData.data];
        MessagePost *messagePost = [[MessagePost alloc] init];
        messagePost.sign = sign;
        messagePost.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
        messagePost.msgData = messageData;
        [[IMService instance] asyncSendGroupInfo:messagePost];
    }
    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD hideHUDForView:self.view];
    }];

    // inteface jump
    [self.navigationController popToRootViewControllerAnimated:NO];
    AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    [[appDelegate shareMainTabController] createGroupWithGroupInfo:lmGroup content:content];
}


/**
 *  Display select contact interface
 */
- (void)showAccountListPage {

    __weak __typeof(&*self) weakSelf = self;
    ChooseContactViewController *page = [[ChooseContactViewController alloc] initWithChooseComplete:^(NSArray *selectContactArray) {
        DDLogInfo(@"%@", selectContactArray);
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showMessage:LMLocalizedString(@"Chat Creating group", nil) toView:weakSelf.view];
        }];
        [weakSelf addNewGroupMembers:selectContactArray];
    }                                                                           defaultSelectedUser:[self.members firstObject]];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
}

@end
