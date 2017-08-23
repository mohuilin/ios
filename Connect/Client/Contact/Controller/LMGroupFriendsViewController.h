//
//  LMGroupFriendsViewController.h
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

@interface LMGroupFriendsViewController : LMBaseViewController

- (instancetype)initWithMembers:(NSArray *)member complete:(void (^)(long long amount,NSString *hashId,NSString *tips))complete;

@end
