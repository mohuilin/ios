//
//  LMMessageExt.h
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMMessageExt : LMBaseModel

@property(nonatomic, copy) NSString *messageId;
@property(nonatomic, copy) NSString *hashid;
@property(nonatomic, assign) int status;
@property(nonatomic, assign) int payCount;
@property(nonatomic, assign) int crowdCount;

@end
