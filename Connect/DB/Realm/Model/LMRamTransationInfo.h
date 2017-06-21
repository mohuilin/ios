//
//  LMRamTransationInfo.h
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMRamTransationInfo : LMBaseModel

@property NSString *messageId;

@property NSString *hashId;

@property int status;

@property int payCount;

@property int crowdCount;


@end
