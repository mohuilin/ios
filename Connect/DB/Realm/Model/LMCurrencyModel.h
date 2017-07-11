//
//  LMCurrencyModel.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMCurrencyModel : LMBaseModel

@property NSString *currency;
@property int category;
@property NSString *salt;
@property NSString *masterAddress;
@property int status;
@property long long int blance;

@end
