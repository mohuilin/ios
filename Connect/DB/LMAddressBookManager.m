//
//  LMAddressBookManager.m
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMAddressBookManager.h"
#import "LMRamAddressBook.h"

static LMAddressBookManager *manager = nil;

@implementation LMAddressBookManager
+ (LMAddressBookManager *)sharedManager {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }

        return manager;
    }
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

- (void)saveAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMRamAddressBook *ramBook = [LMRamAddressBook new];
    ramBook.creatTime = [NSDate date];
    ramBook.tag = @"";
    ramBook.address = address;
    [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
       [realm addOrUpdateObject:ramBook];
    }];

}

- (void)saveBitchAddressBook:(NSArray *)addressBooks {
    if (addressBooks.count <= 0) {
        return;
    }
    if (addressBooks.count > 0) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm addOrUpdateObjectsFromArray:addressBooks];
        }];
    }
}

- (NSArray *)getAllAddressBooks {

    RLMResults<LMRamAddressBook *> *ramBooks = [LMRamAddressBook allObjects];
    if (ramBooks.count <= 0) {
        return nil;
    }
    NSMutableArray *temM = [NSMutableArray array];
    for (LMRamAddressBook *info in ramBooks) {
        [temM addObject:info];
    }
    return temM;
}

- (void)updateAddressTag:(NSString *)tag address:(NSString *)address {
    if (GJCFStringIsNull(tag) || GJCFStringIsNull(address)) {
        return;
    }

   LMRamAddressBook *ramBook = [[LMRamAddressBook objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]] lastObject];
    if (ramBook) {
        [self executeRealmWithBlock:^{
            ramBook.tag = tag;
        }];
    }
}

- (void)deleteAddressBookWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMRamAddressBook *ramBook = [[LMRamAddressBook objectsWhere:[NSString stringWithFormat:@"address = '%@' ",address]] lastObject];
    if (ramBook) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
            [realm deleteObject:ramBook];
        }];
    }
}

- (void)clearAllAddress {
    RLMResults<LMRamAddressBook *> *ramBooks = [LMRamAddressBook allObjects];
    for (LMRamAddressBook *info in ramBooks) {
        [self executeRealmWithRealmBlock:^(RLMRealm *realm) {
           [realm deleteObject:info];
        }];
    }
}

@end
