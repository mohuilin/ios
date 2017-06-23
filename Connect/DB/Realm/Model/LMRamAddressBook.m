//
//  LMRamAddressBook.m
//  Connect
//
//  Created by Connect on 2017/6/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRamAddressBook.h"
#import "AddressBookInfo.h"
@implementation LMRamAddressBook

+ (NSString *)primaryKey {
    return @"address";
}
- (LMBaseModel *)initWithNormalInfo:(BaseInfo *)info {
    if (self == [super init]) {
        if ([info isKindOfClass:[AddressBookInfo class]]) {
            AddressBookInfo * addressBook = (AddressBookInfo *)info;
            self.tag = addressBook.tag;
            self.address = addressBook.address;
        }
    }
    return self;
}
- (BaseInfo *)normalInfo {
    AddressBookInfo * addressBook = [AddressBookInfo new];
    addressBook.tag = self.tag;
    addressBook.address = self.address;
    return addressBook;

}
@end
