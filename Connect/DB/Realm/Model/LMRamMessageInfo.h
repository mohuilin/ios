//
//  LMRamMessageInfo.h
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRamMessageInfo : LMBaseModel

@property NSInteger ID;
@property NSString *messageId;
@property NSString *messageOwer;
@property NSString *content;
@property int sendStatus;
@property NSInteger snapTime;
@property NSInteger readTime;
@property int state;
@property NSInteger createTime;

@end
