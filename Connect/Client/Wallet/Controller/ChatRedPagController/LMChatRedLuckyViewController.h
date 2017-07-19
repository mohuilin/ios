//
//  LMChatRedLuckyViewController.h
//  Connect
//
//  Created by Edwin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "LMRedLuckyShowView.h"

@class AccountInfo;

@interface LMChatRedLuckyViewController : LMBaseViewController

/**
 *  Construction of red envelopes controller
 */
@property(nonatomic, copy) void (^didGetRedLuckyMoney)(NSString *money, NSString *hashId, NSString *tips);

/**
 *  @brief Construction of red envelopes controller。
 *  @param style : Construct a controller style (0. a single red envelope or a group of red envelopes)）
 *  @param reciverIdentifier : Group ID or user address
 *  @see LMChatRedLuckyStyle
 */
- (instancetype)initChatRedLuckyViewControllerWithCategory:(LuckypackageTypeCategory)category reciverIdentifier:(NSString *)reciverIdentifier;

@property(nonatomic, strong) AccountInfo *userInfo; // users
@end
