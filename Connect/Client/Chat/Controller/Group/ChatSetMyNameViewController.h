//
//  ChatSetMyNameViewController.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSetViewController.h"
#import "AccountInfo.h"
#import "LMRamMemberInfo.h"

@interface ChatSetMyNameViewController : BaseSetViewController

- (instancetype)initWithUpdateUser:(LMRamMemberInfo *)user groupIdentifier:(NSString *)groupid;

@end
