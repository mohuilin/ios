//
//  MemberHeaderView.h
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMRamMemberInfo.h"


typedef void(^TapMemberHeaderViewBlock)(LMRamMemberInfo *info);

@interface MemberHeaderView : UIControl

- (instancetype)initWithImage:(NSString *)avatar name:(NSString *)name;

- (instancetype)initWithImage:(NSString *)avatar name:(NSString *)name tapBlock:(TapMemberHeaderViewBlock)tapBlock;

- (instancetype)initWithAccountInfo:(LMRamMemberInfo *)info tapBlock:(TapMemberHeaderViewBlock)tapBlock;

@property(nonatomic, copy) TapMemberHeaderViewBlock tapBlock;

@end
