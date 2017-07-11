//
//  LMRealmManager.m
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRealmManager.h"

@implementation LMRealmManager
static LMRealmManager *manager = nil;
CREATE_SHARED_MANAGER(LMRealmManager)
+ (void)tearDown {
    manager = nil;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}
@end
