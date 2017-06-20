//
//  LMRecentChat.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRecentChat : LMBaseModel

@property (nonatomic ,copy) NSString *identifier2;
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, assign) BOOL isTopChat;
@property(nonatomic, assign) int unReadCount;

@end
