//
//  MainTabController.h
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMRamGroupInfo.h"
#import "LMRamMemberInfo.h"

@interface MainTabController : UITabBarController

- (void)chatWithFriend:(AccountInfo *)chatUser;

- (void)chatWithFriend:(AccountInfo *)user withObject:(NSDictionary *)obj;

- (void)createGroupWithGroupInfo:(LMRamGroupInfo *)groupInfo content:(NSString *)tipMessage;

- (void)changeLanguageResetController;

@end
