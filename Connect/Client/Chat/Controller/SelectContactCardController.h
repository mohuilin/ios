//
//  SelectContactCardController.h
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseTableViewController.h"
#import "AccountInfo.h"

@interface SelectContactCardController : BaseTableViewController


- (instancetype)initWihtTalkUser:(AccountInfo *)talkUser complete:(void (^)(AccountInfo *user))complete cancel:(void (^)())cancel;

@end
