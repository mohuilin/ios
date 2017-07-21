//
//  LMCurrencyAddress.m
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCurrencyAddress.h"
#import "LMCurrencyModel.h"

@implementation LMCurrencyAddress
+ (NSString *)primaryKey {
 return @"address";
}
+ (NSDictionary<NSString *, RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{
             @"addressOwer": [RLMPropertyDescriptor descriptorWithClass:LMCurrencyModel.class propertyName:@"addressListArray"],
             };
}
@end
