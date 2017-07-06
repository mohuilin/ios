//
//  LMLinkManDataManager.h
//  Connect
//
//  Created by bitmain on 2017/2/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CellGroup.h"

@protocol LMLinkManDataManagerDelegate <NSObject>

- (void)listChange:(NSMutableArray *)linkDataArray withTabBarCount:(NSUInteger)count;

@end

@interface LMLinkManDataManager : NSObject

@property(weak, nonatomic) id <LMLinkManDataManagerDelegate> delegate;

// set up
+ (instancetype)sharedManager;

#pragma mark - The outside world needs the method, the contact is in use
/**
 *  get common group
 *
 */
- (NSMutableArray *)getListCommonGroup;
/**
 *  get all friend
 *
 */
- (NSMutableArray *)getListFriendsArr;
/**
 *  get sort data
 *
 */
- (NSMutableArray *)getListGroupsFriend;
/**
 *  get indexs
 *
 */
- (NSMutableArray *)getListIndexs;
/**
 *  get indexs
 *
 */
- (NSMutableArray *)getOffenFriend;
/**
 *  clear all array
 *
 */
- (void)clearArrays;


/**
 *  clear unread bridge
 *
 */
- (void)clearUnreadCountWithType:(int)type;

- (void)getRecommandGroupArrayWithRecommonUser:(AccountInfo *)recmmondUser complete:(void (^)(NSMutableArray *groupArray,NSMutableArray *indexs))complete;

- (void)getRecommandUserGroupArrayChatUser:(AccountInfo *)chatUser complete:(void (^)(NSMutableArray *groupArray,NSMutableArray *indexs))complete;

- (void)getInviteGroupMemberWithSelectedUser:(NSArray *)selectedUsers complete:(void (^)(NSMutableArray *groupArray,NSMutableArray *indexs))complete;


@end
