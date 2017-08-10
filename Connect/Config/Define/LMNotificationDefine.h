//
//  LMNotificationDefine.h
//  Connect
//
//  Created by Connect on 2017/3/23.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

// Download the completed notification

extern NSString *const ConnnectDownAllCommonGroupCompleteNotification;

// Group is closed for notifications

extern NSString *const ConnnectGroupDismissNotification;

// Message sent a successful notification

extern NSString *const ConnnectUploadFileFailNotification;

// Global notification contact information is best to bring out publickey or address

extern NSString *const ConnnectContactDidChangeNotification;

// user address change

extern NSString *const ConnnectUserAddressChangeNotification;

// Global Notification Group Information Modification Batch Group ID only refreshes a row for the most recent session

extern NSString *const ConnnectGroupInfoDidChangeNotification;

// Global notifications delete members

extern NSString *const ConnnectGroupInfoDidDeleteMember;

// add user

extern NSString *const ConnnectGroupInfoDidAddMembers;

// Global notification to add a friend to a successful notification

extern NSString *const ConnnectSendAddRequestSuccennNotification;


// Accept a friend request a successful notification

extern NSString *const kAcceptNewFriendRequestNotification;

// transfer status is exchange

extern NSString *const TransactionStatusChangeNotification;

// Received an external red envelope message

extern NSString *const ConnectGetOuterRedpackgeNotification;

extern NSString *const BadgeNumberManagerBadgeChangeNotification;

// Group change

extern NSString *const GroupAdminChangeNotification;

// Enter group notification

extern NSString *const GroupNewMemberEnterNotification;

extern NSString *const LinkRefreshLinkData;
extern NSString *const SocketDataVerifyIllegalityNotification;

extern NSString *const DeleteMessageHistoryNotification;

extern NSString *const RereweetMessageNotification;

extern NSString *const DeleteGroupReviewedMessageNotification;
// LKUserCenterLoginStatusNoti
extern NSString *const LKUserCenterLoginStatusNoti;
// LKUserCenterLoginFailNoti
extern NSString *const LKUserCenterLoginFailNoti;
// LKUserCenterUserInfoUpdateNotification
extern NSString *const LKUserCenterUserInfoUpdateNotification;
