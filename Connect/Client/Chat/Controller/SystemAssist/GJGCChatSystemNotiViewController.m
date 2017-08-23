//
//  GJGCSystemNotiViewController.m
//  ZYChat
//
//  Created by ZYVincent on 14-11-11.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCChatSystemNotiViewController.h"
#import "CommonClausePage.h"
#import "WallteNetWorkTool.h"
#import "LMReciptNotesViewController.h"
#import "RedBagNetWorkTool.h"
#import "LMChatRedLuckyDetailController.h"
#import "NetWorkOperationTool.h"
#import "LMVerifyInGroupViewController.h"
#import "ApplyJoinToGroupCell.h"
#import "LMRedLuckyShowView.h"
#import "SystemTool.h"
#import "LMMessageTool.h"

@interface GJGCChatSystemNotiViewController () <GJGCChatBaseCellDelegate, LMRedLuckyShowViewDelegate>

@end

@implementation GJGCChatSystemNotiViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setStrNavTitle:self.dataSourceManager.title];
}

#pragma mark - 内部初始化

- (void)initDataManager {
    self.dataSourceManager = [[GJGCChatSystemNotiDataManager alloc] initWithTalk:self.taklInfo withDelegate:self];
}

#pragma mark - chatInputPanel Delegte

- (BOOL)chatInputPanelShouldShowMyFavoriteItem:(GJGCChatInputPanel *)panel {
    return NO;
}

- (void)transforCellDidTap:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    NSString *url = [NSString stringWithFormat:@"%@%@", txDetailBaseUrl, chatContentModel.hashID];
    CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:url];
    page.title = LMLocalizedString(@"Wallet Transaction detail", nil);
    [self.navigationController pushViewController:page animated:YES];
}


- (void)chatCellDidTapDetail:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    if (chatContentModel.hashID.length) {
        [self showRedBagDetailWithHashId:chatContentModel.hashID];
    }
}

- (void)chatCellDidTapOnGroupReviewed:(GJGCChatBaseCell *)tappedCell {

    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    LMOtherModel *model = (LMOtherModel *) chatContentModel.contentModel;
    ApplyJoinToGroupCell *joinToGroupCell = (ApplyJoinToGroupCell *) tappedCell;
    if (!model.userIsinGroup) {
        chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:NO refused:NO isNoted:YES];
        [joinToGroupCell haveNoteThisMessage];
    }
    ChatMessageInfo *chatMessageInfo = [self.dataSourceManager messageByMessageId:chatContentModel.localMsgId];
    ReviewedStatus *reviewedStatus = (ReviewedStatus *)chatMessageInfo.msgContent;
    if (reviewedStatus.newaccept == NO) {
        reviewedStatus.newaccept = YES;
        [[MessageDBManager sharedManager] updataMessage:chatMessageInfo];
    }
    LMVerifyInGroupViewController *page = [[LMVerifyInGroupViewController alloc] init];
    page.model = model;

    if (!model.handled) {
        page.VerifyCallback = ^(BOOL refused) {
            chatContentModel.statusMessageString = [GJGCChatSystemNotiCellStyle formateCellStatusWithHandle:YES refused:refused isNoted:YES];
            model.handled = YES;
            [joinToGroupCell showStatusLabelWithResult:refused];
            
            /// 更新 refused 状态
            reviewedStatus.refused = refused;
            [[MessageDBManager sharedManager] updataMessage:chatMessageInfo];
        };
    }
    [self.navigationController pushViewController:page animated:YES];
}

- (void)redBagCellDidTap:(GJGCChatBaseCell *)tappedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tappedCell];
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    [self grabRedBagWithHashId:chatContentModel.hashID senderName:LMLocalizedString(@"Wallet Connect term", nil) sendAddress:nil];
}


- (void)grabRedBagWithHashId:(NSString *)hashId senderName:(NSString *)senderName sendAddress:(NSString *)sendAddress {
    
    [[LMWalletManager sharedManager] checkWalletExistAndCreateWalletOrCurrencyWithCurrency:CurrencyTypeBTC complete:^(NSError *error) {
        if (!error) {
            [MBProgressHUD showLoadingMessageToView:self.view];
            [RedBagNetWorkTool grabSystemRedBagWithHashId:hashId complete:^(GrabRedPackageResp *response, NSError *error) {
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:self.view];
                }];
                if (error) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network equest failed please try again later", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                    }];
                } else {
                    switch (response.status) {
                        case 0://failed
                        {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode Error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                            }];
                        }
                            break;
                        case 1://success
                        {
                            //create tips message
                            if (![senderName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
                                NSString *operation = [NSString stringWithFormat:@"%@/%@", self.taklInfo.chatUser.address, [[LKUserCenter shareCenter] currentLoginUser].address];
                                ChatMessageInfo *chatMessage = [LMMessageTool makeNotifyMessageWithMessageOwer:self.taklInfo.chatIdendifier content:operation noteType:NotifyMessageTypeLuckyPackageSender_Reciver ext:hashId];
                                [[MessageDBManager sharedManager] saveMessage:chatMessage];
                                [self.dataSourceManager showGetRedBagMessageWithWithMessage:chatMessage];
                            }
                            LMRedLuckyShowView *redLuckyView = [[LMRedLuckyShowView alloc] initWithFrame:[UIScreen mainScreen].bounds redLuckyGifImages:nil];
                            redLuckyView.hashId = hashId;
                            [redLuckyView setDelegate:self];
                            [redLuckyView showRedLuckyViewIsGetARedLucky:YES];
                        }
                            break;
                        case 2: //have garbed
                        {
                            [self getSystemRedBagDetailWithHashId:hashId];
                        }
                            break;
                        case 4: //luckypackage is complete
                        case 3: {//failed
                            LMRedLuckyShowView *redLuckyView = [[LMRedLuckyShowView alloc] initWithFrame:[UIScreen mainScreen].bounds redLuckyGifImages:nil];
                            redLuckyView.hashId = hashId;
                            [redLuckyView setDelegate:self];
                            [redLuckyView showRedLuckyViewIsGetARedLucky:NO];
                        }
                            break;
                        case 5://User does not bind phone number
                        {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Your account is not bound to the phone", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                            }];
                        }
                            break;
                        case 6://A phone number can only grab once
                        {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Set A phone number can only grab once", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                            }];
                        }
                            break;
                        case 7://system luckypackage have been frozen
                        {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat system luckypackage have been frozen", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                            }];
                        }
                            break;
                        case 8://one device can only grab a luckypackage
                        {
                            [GCDQueue executeInMainQueue:^{
                                [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat one device can only grab a luckypackage", nil) withType:ToastTypeFail showInView:self.view complete:nil];
                            }];
                        }
                            break;
                        default:
                            break;
                    }
                }
            }];
        }
    }];
    
}


#pragma mark - garb luckybackage delegate

- (void)redLuckyShowView:(LMRedLuckyShowView *)showView goRedLuckyDetailWithSender:(UIButton *)sender {
    [showView dismissRedLuckyView];
    [MBProgressHUD showLoadingMessageToView:self.view];
    [self getSystemRedBagDetailWithHashId:showView.hashId];
}

#pragma mark - cell tap

- (void)systemNotiBaseCellDidTapOnPublicMessage:(GJGCChatBaseCell *)tapedCell {
    NSIndexPath *tapIndexPath = [self.chatListTable indexPathForCell:tapedCell];
    GJGCChatSystemNotiModel *contentModel = (GJGCChatSystemNotiModel *) [self.dataSourceManager contentModelAtIndex:tapIndexPath.row];
    switch (contentModel.systemJumpType) {
        case 1: { //jumpType is 1 mean url
            if ([SystemTool isNationChannel]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
            }
        }
            break;
        default: {
            if (GJCFStringIsNull(contentModel.systemJumpUrl)) {
                return;
            }
            CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:contentModel.systemJumpUrl];
            page.title = contentModel.systemNotiTitle.string;
            [self.navigationController pushViewController:page animated:YES];
        }
            break;
    }
}

@end
