//
//  LMCurrencyAddress.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMCurrencyAddress : LMBaseModel
@property (nonatomic,assign) int currency;
@property (nonatomic,assign)int index;
@property (nonatomic,copy)NSString *address;
@property (nonatomic,assign)long long int balance;
@property (nonatomic,assign)long long int amount;
@property (nonatomic,copy)NSString *label;
@property (nonatomic,assign)int status;

@property(readonly) RLMLinkingObjects *addressOwer;

@end
RLM_ARRAY_TYPE(LMCurrencyAddress)
