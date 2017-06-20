//
//  LMRealmDBManager.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LMRecentChat.h"

@interface LMRealmDBManager : NSObject

+ (void)dataMigrationWithComplete:(void (^)(CGFloat progress))complete;

+ (void)saveInfo:(LMBaseModel *)ramModel;

@end
