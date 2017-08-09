//
//  GJGCChatGroupViewController.m
//  Connect
//
//  Created by KivenLin on 14-11-3.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatGroupViewController.h"
#import "GJGCChatGroupDataSourceManager.h"
#import "ChatGroupSetViewController.h"
#import "LMGroupChooseNoteMemberlistPage.h"

@interface GJGCChatGroupViewController ()


@end

@implementation GJGCChatGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.noteGroupMembers = [NSMutableArray array];
    [self setRightButtonWithStateImage:@"menu_white" stateHighlightedImage:nil stateDisabledImage:nil titleName:nil];
    [self setStrNavTitle:self.dataSourceManager.title];
    RegisterNotify(ConnnectGroupInfoDidChangeNotification, @selector(groupInfoChange:));
    RegisterNotify(ConnnectContactDidChangeNotification, @selector(contactInfoChange:));
    NSString *deleteGroupMemberNoti = [GJGCChatInputConst panelNoti:GJGCChatInputTextViewDeleteNoteGroupMemberNoti formateWithIdentifier:self.inputPanel.panelIndentifier];
    RegisterNotify(deleteGroupMemberNoti, @selector(deleteGroupMember:));
}


- (void)deleteGroupMember:(NSNotification *)note {
    NSString *groupName = note.object;
    for (LMRamMemberInfo *groupMember in self.noteGroupMembers) {
        if ([groupName isEqualToString:groupMember.username]) {
            [self.noteGroupMembers removeObject:groupMember];
            break;
        }
    }
}

- (void)contactInfoChange:(NSNotification *)note {
    AccountInfo *user = note.object;
    if (!user) {
        return;
    }
    for (LMRamMemberInfo *member in self.taklInfo.chatGroupInfo.membersArray) {
        if ([member.address isEqualToString:user.address]) {
            if ([member.username isEqualToString:user.username] && [member.avatar isEqualToString:user.avatar]) {
                break;
            }
            member.username = user.username;
            member.avatar = user.avatar;
            [[GroupDBManager sharedManager] updateGroupMembserAvatarUrl:member.avatar address:member.address groupId:self.taklInfo.chatIdendifier];
            [[GroupDBManager sharedManager] updateGroupMembserUsername:member.username address:member.address groupId:self.taklInfo.chatIdendifier];
            self.taklInfo.chatGroupInfo.membersArray = self.taklInfo.chatGroupInfo.membersArray;
            break;
        }
    }
}

- (void)groupInfoChange:(NSNotification *)note {

    NSString *groupIdentifer = (NSString *) note.object;

    LMRamGroupInfo *group = [[GroupDBManager sharedManager] getGroupByGroupIdentifier:groupIdentifer];
    self.taklInfo.chatGroupInfo = group;
    self.taklInfo.name = [NSString stringWithFormat:@"%@(%lu)", group.groupName, group.membersArray.count];
    self.dataSourceManager.title = self.taklInfo.name;
    [GCDQueue executeInMainQueue:^{
        self.titleView.title = self.taklInfo.name;
    }];
}

- (void)dealloc {
    RemoveNofify;
}

- (void)initDataManager {
    self.dataSourceManager = [[GJGCChatGroupDataSourceManager alloc] initWithTalk:self.taklInfo withDelegate:self];
}

- (void)rightButtonPressed:(id)sender {
    ChatGroupSetViewController *setController = [[ChatGroupSetViewController alloc] initWithTalkInfo:self.taklInfo];
    [self.navigationController pushViewController:setController animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reserveChatInputPanelState];
    });
}

#pragma mark - Group chat when adding a @ function

- (void)inputTextChangeWithText:(NSString *)text {
    __weak typeof(self) weakSelf = self;
    if ([text isEqualToString:@"@"]) {
        NSMutableArray *temArray = [NSMutableArray array];
        for (LMRamMemberInfo *info in self.taklInfo.chatGroupInfo.membersArray) {
            [temArray addObject:info];
        }
        LMGroupChooseNoteMemberlistPage *page = [[LMGroupChooseNoteMemberlistPage alloc] initWithMembers:temArray];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:page];
        page.ChooseGroupMemberCallBack = ^(LMRamMemberInfo *realmMembser) {
            AccountInfo *member = realmMembser.normalInfo;
            if (member) {
                [weakSelf.inputPanel appendFocusOnOther:[NSString stringWithFormat:@"@%@ ", member.username]];
                if (![weakSelf.noteGroupMembers containsObject:member]) {
                    [weakSelf.noteGroupMembers objectAddObject:member];
                }
            } else {
                [weakSelf.inputPanel appendFocusOnOther:@"@"];
            }
        };
        [weakSelf presentViewController:nav animated:YES completion:nil];
    }
}

#pragma mark -Long press headavatar @ funcation

- (void)chatCellDidLongPressOnHeadView:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *contentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    LMRamMemberInfo *member = [[GroupDBManager sharedManager] getGroupMemberByGroupId:self.taklInfo.chatIdendifier memberAddress:contentModel.senderAddress];
    if (member) {
        if (![self.noteGroupMembers containsObject:member.normalInfo]) {
            [self.noteGroupMembers objectAddObject:member.normalInfo];
        }
        [self.inputPanel appendFocusOnOther:[NSString stringWithFormat:@"@%@ ", contentModel.senderName]];
    }
}

@end
