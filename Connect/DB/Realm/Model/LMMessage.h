//
//  LMMessage.h
//  Connect
//
//  Created by MoHuilin on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
#import "LMMessageExt.h"
#import "ChatMessageInfo.h"

@interface LMMessage : LMBaseModel

@property(nonatomic, copy) NSString *uniqueId;
@property(nonatomic, copy) NSString *messageOwer;
@property(nonatomic, copy) NSString *messageId;
@property(nonatomic, copy) NSString *messageContent;
@property(nonatomic, assign) NSInteger createTime;
@property(nonatomic, assign) NSInteger readTime;
@property(nonatomic, assign) NSInteger snapTime;
@property(nonatomic, assign) int sendstatus;
@property(nonatomic, assign) int state;

@property(nonatomic, strong) LMMessageExt *msgExt;


@end
