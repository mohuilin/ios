//
//  LMCurrencyModel.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"
#import "LMCurrencyAddress.h"

@interface LMCurrencyModel : LMBaseModel

@property(copy ,nonatomic) NSString *currency;
@property(assign ,nonatomic) int category;
@property(copy ,nonatomic) NSString *salt;
@property(copy ,nonatomic) NSString *masterAddress;
@property(assign ,nonatomic) int status;
@property(assign ,nonatomic) long long int blance;
@property(copy ,nonatomic) NSString *payload;
@property(strong, nonatomic) RLMArray<LMCurrencyAddress *> <LMCurrencyAddress> *membersArray;

@end
