//
//  BaseDB.h
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMGlobal.h"
#import "NSString+Hash.h"
#import "NSDictionary+LMSafety.h"
#import <Realm/Realm.h>

@interface BaseDB : NSObject

/**
 * update realm model value
 * @param executeBlock
 */
- (void)executeRealmWithBlock:(void (^)())executeBlock;


/**
 * save or update realm model ,call with realm handler
 * @param executeBlock
 */
- (void)executeRealmWithRealmBlock:(void (^)(RLMRealm *realm))executeBlock;

@end
