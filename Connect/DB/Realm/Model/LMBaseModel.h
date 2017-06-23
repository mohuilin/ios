//
//  LMBaseModel.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Realm/Realm.h>

@interface LMBaseModel : RLMObject

@property (nonatomic ,assign) NSInteger ID;

- (LMBaseModel *)initWithNormalInfo:(id)info;

- (id)normalInfo;

@end
