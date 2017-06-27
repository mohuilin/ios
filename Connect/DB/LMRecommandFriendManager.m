//
//  LMRecommandFriendManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRecommandFriendManager.h"
#import "Protofile.pbobjc.h"
#import "LMFriendRecommandInfo.h"

@interface LMRecommandFriendManager ()


@end

static LMRecommandFriendManager *manager = nil;

@implementation LMRecommandFriendManager

+ (LMRecommandFriendManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
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

+ (void)tearDown {
    manager = nil;
}

- (void)deleteAllRecommandFriend; {
    
    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo allObjects];
    for (LMFriendRecommandInfo *info in results) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:info];
        }];
    }
}

- (void)deleteRecommandFriendWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMFriendRecommandInfo *friendRequestInfo = [[LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ", address]] lastObject];
    if (friendRequestInfo) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:friendRequestInfo];
        }];
    }
}

- (void)saveRecommandFriend:(NSArray *)friendArray; {
    if (friendArray.count <= 0) {
        return;
    }
    NSMutableArray *addArray = [NSMutableArray array];
    for (LMFriendRecommandInfo *recommandInfo in friendArray) {
        if (!(recommandInfo.username.length <= 0 || recommandInfo.address.length <= 0)) {
            [addArray addObject:recommandInfo];
        }
    }
    if (addArray.count > 0) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm addOrUpdateObjectsFromArray:addArray];
        }];
    }
}

- (NSArray *)getRecommandFriendsWithPage:(int)page {
    if (page <= 0) {
        page = 1;
    }
    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo allObjects];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSInteger number = (page * 20);
    NSInteger previousNumber = (page - 1) * 20;
    if (results.count >= number) {
        
        for (NSInteger index = previousNumber; index < number; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
            [resultArray addObject:ramFriendInfo];
        }
        
    } else {
        
        for (NSInteger index = previousNumber; index < results.count; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
            [resultArray addObject:ramFriendInfo];
        }
        
    }
    if (resultArray.count > 0) {
        NSArray *result = resultArray.copy;
        result = [result sortedArrayUsingComparator:^NSComparisonResult(LMFriendRecommandInfo *obj1, LMFriendRecommandInfo *obj2) {
            return [obj2.pubKey compare:obj1.pubKey];
        }];
        return result;
    }
    return nil;
}

- (BOOL)isExistUser:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return NO;
    }
    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ", address]];
    if (results.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)updateRecommandFriendStatus:(int32_t)status withAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMFriendRecommandInfo *recommandInfo = [[LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]] lastObject];
    [self executeRealmWithBlock:^{
        recommandInfo.status = status;
    }];
}

- (NSArray *)getRecommandFriendsWithPage:(int)page withStatus:(int)status {
    if (page <= 0) {
        page = 1;
    }
    
    RLMResults<LMFriendRecommandInfo *> *results = [LMFriendRecommandInfo objectsWhere:[NSString stringWithFormat:@"status = %d ", status]];
    NSMutableArray *resultArray = [NSMutableArray array];
    NSInteger number = (page * 20);
    NSInteger previousNumber = (page - 1) * 20;
    if (results.count >= number) {
        
        for (NSInteger index = previousNumber; index < number; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
            [resultArray addObject:ramFriendInfo];
        }
        
    } else {
        
        for (NSInteger index = previousNumber; index < results.count; index++) {
            LMFriendRecommandInfo *ramFriendInfo = results[index];
            [resultArray addObject:ramFriendInfo];
        }
        
    }
    if (resultArray.count > 0) {
        NSArray *result = resultArray.copy;
        result = [result sortedArrayUsingComparator:^NSComparisonResult(LMFriendRecommandInfo *obj1, LMFriendRecommandInfo *obj2) {
            return [obj2.pubKey compare:obj1.pubKey];
        }];
        return result;
    }
    return nil;
}
@end

