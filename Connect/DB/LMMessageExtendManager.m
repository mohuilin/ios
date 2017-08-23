//
//  LMMessageExtendManager.m
//  Connect
//
//  Created by Connect on 2017/4/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMMessageExtendManager.h"
#import "LMMessageExt.h"

#define MessageExtenTable @"t_transactiontable"


static LMMessageExtendManager *manager = nil;

@implementation LMMessageExtendManager

+ (LMMessageExtendManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

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

- (void)saveBitchMessageExtend:(NSArray *)array {
    if (array.count <= 0) {
        return;
    }
    for (NSDictionary *dic  in array) {
        LMMessageExt *msgExt = [[LMMessageExt alloc] init];
        msgExt.messageId = [dic safeObjectForKey:@"message_id"];
        msgExt.hashid = [dic safeObjectForKey:@"hashid"];
        msgExt.status = [[dic safeObjectForKey:@"status"] intValue];
        msgExt.payCount = [[dic safeObjectForKey:@"pay_count"] intValue];
        msgExt.crowdCount = [[dic safeObjectForKey:@"crowd_count"] intValue];

        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm addOrUpdateObject:msgExt];
        }];
    }
}

- (void)saveBitchMessageExtendDict:(NSDictionary *)dic {
    if (!dic) {
        return;
    }

    LMMessageExt *msgExt = [[LMMessageExt alloc] init];
    msgExt.messageId = [dic safeObjectForKey:@"message_id"];
    msgExt.hashid = [dic safeObjectForKey:@"hashid"];
    msgExt.status = [[dic safeObjectForKey:@"status"] intValue];
    msgExt.payCount = [[dic safeObjectForKey:@"pay_count"] intValue];
    msgExt.crowdCount = [[dic safeObjectForKey:@"crowd_count"] intValue];

    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
        [realm addOrUpdateObject:msgExt];
    }];
}

- (void)updateMessageExtendStatus:(int)status withHashId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return;
    }

    LMMessageExt *msgExt = [[LMMessageExt objectsWhere:[NSString stringWithFormat:@"hashid = '%@'", hashId]] lastObject];
    if (msgExt) {
        [self executeRealmWithBlock:^{
            msgExt.status = status;
        }];
    }
}

- (void)updateMessageExtendPayCount:(int)payCount withHashId:(NSString *)hashId {

    if (GJCFStringIsNull(hashId)) {
        return;
    }
    LMMessageExt *msgExt = [[LMMessageExt objectsWhere:[NSString stringWithFormat:@"hashid = '%@'", hashId]] lastObject];
    if (msgExt) {
        [self executeRealmWithBlock:^{
            msgExt.payCount = payCount;
        }];
    }
}

- (void)updateMessageExtendPayCount:(int)payCount status:(int)status withHashId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return;
    }
    LMMessageExt *msgExt = [[LMMessageExt objectsWhere:[NSString stringWithFormat:@"hashid = '%@'", hashId]] lastObject];
    if (msgExt) {
        [self executeRealmWithBlock:^{
            msgExt.status = status;
            msgExt.payCount = payCount;
        }];
    }
}


- (int)getStatus:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return 0;
    }

    LMMessageExt *msgExt = [[LMMessageExt objectsWhere:[NSString stringWithFormat:@"hashid = '%@'", hashId]] lastObject];
    return msgExt.status;
}

- (int)getPayCount:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return 0;
    }
    LMMessageExt *msgExt = [[LMMessageExt objectsWhere:[NSString stringWithFormat:@"hashid = '%@'", hashId]] lastObject];
    return msgExt.payCount;
}

- (NSString *)getMessageId:(NSString *)hashId {
    if (GJCFStringIsNull(hashId)) {
        return nil;
    }
    LMMessageExt *msgExt = [[LMMessageExt objectsWhere:[NSString stringWithFormat:@"hashid = '%@'", hashId]] lastObject];
    return msgExt.messageId;
}

@end
