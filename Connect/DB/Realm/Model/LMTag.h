//
//  LMTag.h
//  Connect
//
//  Created by MoHuilin on 2017/6/22.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMTag : LMBaseModel

@property (nonatomic ,copy) NSString *tag;

@end

RLM_ARRAY_TYPE(LMTag)
