//
//  LMSeedModel.h
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@interface LMSeedModel : LMBaseModel

@property NSString *walletId;
@property NSString *encryptSeed;
@property NSString *salt;
@property int n;
@property int status;
@property int version;


@end
