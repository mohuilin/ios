//
//  GroupMembersCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMRamMemberInfo.h"
#import "BaseCell.h"

typedef void(^TapMemberHeaderBlock)(LMRamMemberInfo *tapUser);

typedef void(^TapAddMemberBlock)();


@interface GroupMembersCell : BaseCell

@property(nonatomic, copy) TapMemberHeaderBlock tapMemberHeaderBlock;

@property(nonatomic, copy) TapAddMemberBlock tapAddMemberBlock;

@end
