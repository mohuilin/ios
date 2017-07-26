//
//  LMSeedModel.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMSeedModel : LMBaseModel

@property (nonatomic ,copy) NSString *encryptSeed;
@property (nonatomic ,assign)int version;
@property (nonatomic ,assign)int ver;

@end
