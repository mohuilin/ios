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
    ramBook.creatTime = [[NSDate date] timeIntervalSince1970] * 1000;
    ramBook.tag = @"";
    ramBook.address = address;
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:ramBook];
    [realm commitWriteTransaction];


}

- (void)saveBitchAddressBook:(NSArray *)addressBooks {
    if (addressBooks.count <= 0) {
        return;
    }
    NSMutableArray *bitchValues = [NSMutableArray array];
    for (AddressBookInfo *addressBook in addressBooks) {
        if (GJCFStringIsNull(addressBook.address)) {
            continue;
        }
        long long int time = [[NSDate date] timeIntervalSince1970] * 1000;
        LMRamAddressBook *ramBook = [LMRamAddressBook new];
        ramBook.address = addressBook.address;
        if (addressBook.tag.length <= 0) {
            addressBook.tag = @"";
        }
        ramBook.tag = addressBook.tag;
        ramBook.creatTime = time;
        [bitchValues addObject:ramBook];
    }
    if (bitchValues.count > 0) {
        RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
        [realm beginWriteTransaction];
        [realm addOrUpdateObjectsFromArray:bitchValues];
        [realm commitWriteTransaction];
    }
}

- (NSArray *)getAllAddressBooks {

    RLMResults<LMRamAddressBook *> *ramBooks = [LMRamAddressBook allObjects];
    if (ramBooks.count <= 0) {
        return nil;
    }
    NSMutableArray *temM = [NSMutableArray array];
    for (LMRamAddressBook *ramBook in ramBooks) {
        AddressBookInfo *info = [[AddressBookInfo alloc] init];
        info.address = ramBook.address;
        info.tag = ramBook.tag;
        [temM objectAddObject:info];
    }
    return temM.copy;
}

- (void)updateAddressTag:(NSString *)tag address:(NSString *)address {
    if (GJCFStringIsNull(tag) || GJCFStringIsNull(address)) {
        return;
    }
    LMRamAddressBook *ramBook = [[LMRamAddressBook objectsWhere:[NSString stringWithFormat:@"address = '%@' ", address]] lastObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    ramBook.tag = tag;
    [realm commitWriteTransaction];

}

- (void)deleteAddressBookWithAddress:(NSString *)address {
    if (GJCFStringIsNull(address)) {
        return;
    }
    LMRamAddressBook *ramBook = [[LMRamAddressBook objectsWhere:[NSString stringWithFormat:@"address = '%@' ", address]] lastObject];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    [realm beginWriteTransaction];
    [realm deleteObject:ramBook];
    [realm commitWriteTransaction];
}

- (void)clearAllAddress {
    RLMResults<LMRamAddressBook *> *ramBooks = [LMRamAddressBook allObjects];
    RLMRealm *realm = [RLMRealm defaultLoginUserRealm];
    for (LMRamAddressBook *info in ramBooks) {
        [realm beginWriteTransaction];
        [realm deleteObject:info];
        [realm commitWriteTransaction];
    }
}

@end
