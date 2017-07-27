//
//  LMRecipFriendsViewController.h
//  Connect
//
//  Created by Edwin on 16/7/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "AccountInfo.h"

@interface LMRecipFriendsViewController : LMBaseViewController

- (instancetype)initWithChatUser:(AccountInfo *)chatUser callBack:(void (^)(NSDecimalNumber *money, NSString *hashId, NSString *note))callBack;

@end
