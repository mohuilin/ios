//
//  LMTransFriendsViewController.h
//  Connect
//
//  Created by Edwin on 16/7/20.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"

typedef void (^changeListBlock)();

@interface LMTransFriendsViewController : LMBaseViewController

- (instancetype)initWithSelectedMembers:(NSArray *)seletedMembers changeListBlock:(changeListBlock)changeListBlock complete:(void (^)(NSString *hashId,NSString *tips))complete;

@end
