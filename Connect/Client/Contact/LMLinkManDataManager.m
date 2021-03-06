//
//  LMLinkManDataManager.m
//  Connect
//
//  Created by bitmain on 2017/2/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMLinkManDataManager.h"
#import "UserDBManager.h"
#import "NewFriendItemModel.h"
#import "NSString+Pinyin.h"
#import "BadgeNumberManager.h"
#import "LMGroupInfo.h"
#import "GroupDBManager.h"
#import "NetWorkOperationTool.h"
#import "KTSContactsManager.h"
#import "PhoneContactInfo.h"
#import "ConnectTool.h"
#import "AddressBookCallBack.h"
#import "LMHistoryCacheManager.h"


@interface LMLinkManDataManager ()

// user list
@property(nonatomic, strong) NSMutableArray *friendsArr;
// common friends
@property(nonatomic, strong) NSMutableArray *normalFriends;
// offenFriends
@property(nonatomic, strong) NSMutableArray *offenFriends;
// group of common
@property(nonatomic, strong) NSMutableArray *commonGroup;
// new friens model
@property(nonatomic, strong) NewFriendItemModel *friendNewItem;
// sort list
@property(nonatomic, strong) NSMutableArray *groupsFriend;
// indexs
@property(nonatomic, strong) NSMutableArray *indexs;
// point members
@property(assign, nonatomic) NSUInteger redCount;


@end


@implementation LMLinkManDataManager

CREATE_SHARED_MANAGER(LMLinkManDataManager)

- (instancetype)init {
    if (self = [super init]) {
        [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
            [GCDQueue executeInMainQueue:^{
                for (LMGroupInfo *group in groups) {
                    if (![self.commonGroup containsObject:group]) {
                        [self.commonGroup objectAddObject:group];
                    } else {
                        [self.commonGroup replaceObjectAtIndex:[self.commonGroup indexOfObject:group] withObject:group];
                    }
                }
                [self formartFiendsGrouping];
            }];
        }];
        // regiser notification
        [self addNotification];
    }
    return self;

}

#pragma mark -  懒加载

- (NSMutableArray *)friendsArr {
    if (!_friendsArr) {
        _friendsArr = [NSMutableArray array];
    }

    return _friendsArr;
}

- (NSMutableArray *)offenFriends {
    if (!_offenFriends) {
        _offenFriends = [NSMutableArray array];
    }

    return _offenFriends;
}

- (NSMutableArray *)commonGroup {
    if (!_commonGroup) {
        _commonGroup = [NSMutableArray array];
    }

    return _commonGroup;
}

- (NSMutableArray *)normalFriends {
    if (!_normalFriends) {
        _normalFriends = [NSMutableArray array];
    }

    return _normalFriends;
}

- (NSMutableArray *)groupsFriend {
    if (!_groupsFriend) {
        _groupsFriend = [NSMutableArray array];
    }
    return _groupsFriend;
}

- (NewFriendItemModel *)friendNewItem {
    if (!_friendNewItem) {
        _friendNewItem = [NewFriendItemModel new];
        _friendNewItem.title = LMLocalizedString(@"Link New friend", nil);
        _friendNewItem.icon = @"contract_new_friend";
    }
    return _friendNewItem;
}

- (NSMutableArray *)indexs {
    if (!_indexs) {
        _indexs = [NSMutableArray array];
    }
    return _indexs;
}

#pragma mark - lazy

- (NSMutableArray *)getListCommonGroup {
    return self.commonGroup;
}

- (NSMutableArray *)getListFriendsArr {
    return self.friendsArr;
}

- (NSMutableArray *)getListGroupsFriend {
    return self.groupsFriend;
}

- (NSMutableArray *)getListIndexs {
    return self.indexs;
}

- (void)clearArrays {

    [self.friendsArr removeAllObjects];
    self.friendsArr = nil;
    [self.commonGroup removeAllObjects];
    self.friendsArr = nil;
    [self.indexs removeAllObjects];
    self.indexs = nil;
    [self.normalFriends removeAllObjects];
    self.normalFriends = nil;
    [self.offenFriends removeAllObjects];
    self.offenFriends = nil;
    [self.groupsFriend removeAllObjects];
    self.groupsFriend = nil;

    self.friendNewItem = nil;
}

/**
 *  get all user array
 */
- (void)getAllLinkMan {
    [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
        [GCDQueue executeInMainQueue:^{
            for (LMGroupInfo *group in groups) {
                if (![self.commonGroup containsObject:group]) {
                    [self.commonGroup objectAddObject:group];
                } else {
                    [self.commonGroup replaceObjectAtIndex:[self.commonGroup indexOfObject:group] withObject:group];
                }
            }
            [self formartFiendsGrouping];
        }];
    }];
}

#pragma mark - notification method

- (void)addNotification {
    RegisterNotify(kAcceptNewFriendRequestNotification, @selector(addNewUser:));

    RegisterNotify(kFriendListChangeNotification, @selector(downAllContacts));

    RegisterNotify(kNewFriendRequestNotification, @selector(newFriendRequest:));

    RegisterNotify(ConnnectContactDidChangeNotification, @selector(ContactChange:));

    RegisterNotify(ConnnectContactDidChangeDeleteUserNotification, @selector(deleteUser:));

    RegisterNotify(ConnnectUserAddressChangeNotification, @selector(AddressBookChange:));
    RegisterNotify(ConnnectRemoveCommonGroupNotification, @selector(RemoveCommonGroup:));
    RegisterNotify(ConnnectAddCommonGroupNotification, @selector(AddCommonGroup:));

    RegisterNotify(ConnnectDownAllCommonGroupCompleteNotification, @selector(downAllCommomGroup:));

    RegisterNotify(BadgeNumberManagerBadgeChangeNotification, @selector(badgeValueChange));

    RegisterNotify(ConnnectQuitGroupNotification, @selector(quitGroup:));

    RegisterNotify(ConnectDownAllNewGroupAvatarNotification, @selector(groupAvatarChange));
    RegisterNotify(ConnectUpdateMyNickNameNotification, @selector(groupNicknameChange));
    RegisterNotify(ConnnectGroupInfoDidChangeNotification, @selector(groupInfoChnage:));
    CFErrorRef *error = nil;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(nil, error);
    if (!error) {
        // contact address book change
        registerExternalChangeCallbackForAddressBook(addressBookRef);
    }
}

/**
 *  address exchange
 */
- (void)AddressBookChange:(NSNotification *)note {
    DDLogInfo(@"Change of address book...");
    [self uploadContactAndGetNewPhoneFriends];
}

- (void)uploadContactAndGetNewPhoneFriends {
    __weak __typeof(&*self) weakSelf = self;
    [GCDQueue executeInGlobalQueue:^{
        [[KTSContactsManager sharedManager] importContacts:^(NSArray *contacts, BOOL reject) {
            if (reject) {
                [GCDQueue executeInGlobalQueue:^{
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Address Book Access Denied", nil) message:LMLocalizedString(@"Link access to your Address Book in Settings", nil) preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:okAction];
                    [[weakSelf getCurrentVC] presentViewController:alertController animated:YES completion:nil];
                }];
                return;
            }
            NSMutableArray *hashMobiles = [NSMutableArray array];
            NSMutableArray *phoneContacts = [PhoneContactInfo mj_objectArrayWithKeyValuesArray:contacts];
            for (PhoneContactInfo *info in phoneContacts) {
                for (Phone *phone in info.phones) {
                    NSString *phoneStr = phone.phoneNum;
                    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+" withString:@""];
                    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
                    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
                    if ([phoneStr hasPrefix:[RegexKit phoneCode].stringValue]) {
                        phoneStr = [phoneStr substringFromIndex:2];
                    }
                    PhoneInfo *phoneInfo = [[PhoneInfo alloc] init];
                    phoneInfo.code = [RegexKit phoneCode].intValue;
                    phoneInfo.mobile = [phoneStr hmacSHA512StringWithKey:hmacSHA512Key];
                    [hashMobiles objectAddObject:phoneInfo];
                }
            }
            [SetGlobalHandler syncPhoneContactWithHashContact:hashMobiles complete:^(NSTimeInterval time) {
                if (time) {
                    // update check
                    [weakSelf getRegisterUserByNet];
                }
            }];
        }];
    }];
}

- (UIViewController *)getCurrentVC {
    UIViewController *result = nil;

    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }

    UIView *frontView = [[window subviews] objectAtIndexCheck:0];
    id nextResponder = [frontView nextResponder];

    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;

    return result;
}

- (void)getRegisterUserByNet {
    __weak __typeof(&*self) weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:ContactPhoneBookUrl signNoEncryptPostData:nil
                                   complete:^(id response) {
                                       HttpResponse *hResponse = (HttpResponse *) response;

                                       if (hResponse.code != successCode) {
                                           return;
                                       }
                                       NSData *data = [ConnectTool decodeHttpResponse:hResponse];
                                       if (data) {
                                           // cache
                                           [[LMHistoryCacheManager sharedManager] cacheRegisterContacts:data];

                                           PhoneBookUsersInfo *users = [PhoneBookUsersInfo parseFromData:data error:nil];
                                           NSData *notedData = [[LMHistoryCacheManager sharedManager] getNotificatedContact];
                                           ContactsNotificatedAddress *noteAddress;
                                           if (notedData) {
                                               noteAddress = [ContactsNotificatedAddress parseFromData:[[LMHistoryCacheManager sharedManager] getNotificatedContact] error:nil];
                                           } else {
                                               noteAddress = [ContactsNotificatedAddress new];
                                           }
                                           NSMutableArray *notedAddress = [NSMutableArray arrayWithArray:noteAddress.addressesArray];
                                           NSInteger count = 0;
                                           for (PhoneBookUserInfo *phoneBookUser in users.usersArray) {
                                               UserInfo *user = phoneBookUser.user;
                                               AccountInfo *userInfo = [[AccountInfo alloc] init];
                                               userInfo.avatar = user.avatar;
                                               userInfo.address = user.address;
                                               userInfo.stranger = ![[UserDBManager sharedManager] isFriendByAddress:userInfo.address];
                                               if (!userInfo.stranger) {
                                                   continue;
                                               } else {
                                                   AccountInfo *requestUser = [[UserDBManager sharedManager] getFriendRequestBy:user.address];
                                                   // no request and no notification user
                                                   if (!requestUser && ![noteAddress.addressesArray containsObject:user.address]) {
                                                       count++;
                                                       if (![notedAddress containsObject:user.address]) {
                                                           [notedAddress objectAddObject:user.address];
                                                       }
                                                   }
                                               }
                                           }
                                           // save notification data
                                           noteAddress.addressesArray = notedAddress;
                                           [[LMHistoryCacheManager sharedManager] cacheNotificatedContacts:noteAddress.data];
                                           if (count > 0) {
                                               BadgeNumber *createBadge = [[BadgeNumber alloc] init];
                                               createBadge.type = ALTYPE_CategoryTwo_PhoneContact;
                                               createBadge.count = count;
                                               createBadge.displayMode = ALDisplayMode_Number;
                                               [[BadgeNumberManager shareManager] setBadgeNumber:createBadge Completion:^(BOOL result) {
                                                   if (result) {
                                                       [weakSelf reloadBadgeValue];
                                                   }
                                               }];
                                           }
                                       }
                                   } fail:^(NSError *error) {

            }];
}

/**
 *  group mesage exchange
 */
- (void)groupInfoChnage:(NSNotification *)note {
    [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *commonGroups) {
        [GCDQueue executeInMainQueue:^{
            for (LMGroupInfo *group in commonGroups) {
                if (![self.commonGroup containsObject:group]) {
                    [self.commonGroup objectAddObject:group];
                } else {
                    [self.commonGroup replaceObjectAtIndex:[self.commonGroup indexOfObject:group] withObject:group];
                }
            }
            [self formartFiendsGrouping];
        }];
    }];

}

- (void)groupAvatarChange {
    [GCDQueue executeInMainQueue:^{
        if ([self.delegate respondsToSelector:@selector(listChange:withTabBarCount:)]) {
            [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
        }
    }];
}

/**
 *  group nick exchange
 */
- (void)groupNicknameChange {
    [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
        [GCDQueue executeInMainQueue:^{
            // replace data
            for (LMGroupInfo *group in groups) {
                if (![self.commonGroup containsObject:group]) {
                    [self.commonGroup objectAddObject:group];
                } else {
                    [self.commonGroup replaceObjectAtIndex:[self.commonGroup indexOfObject:group] withObject:group];
                }
            }
            if (groups.count > 0) {
                if ([self.delegate respondsToSelector:@selector(listChange:withTabBarCount:)]) {
                    [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
                }
            }
        }];
    }];
}

/**
 * quit group
 */
- (void)quitGroup:(NSNotification *)note {
    NSString *groupid = note.object;
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    // delete common man
    for (LMGroupInfo *group in self.commonGroup) {
        if ([group.groupIdentifer isEqualToString:groupid]) {
            [[GroupDBManager sharedManager] deletegroupWithGroupId:group.groupIdentifer];
            [self.commonGroup removeObject:group];
            // exchange ui
            NSInteger index = 1;
            if (self.offenFriends.count > 0) {
                index = 2;
            }
            NSMutableDictionary *commonGroup = [self.groupsFriend objectAtIndexCheck:index];
            if (self.commonGroup.count <= 0) {
                [self.groupsFriend removeObject:commonGroup];
                if ([self.delegate respondsToSelector:@selector(listChange:withTabBarCount:)]) {
                    [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(listChange:withTabBarCount:)]) {
                    [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
                }
            }
            break;
        }
    }
}

- (void)badgeValueChange {
    [self reloadBadgeValue];
}

/**
 * download all data
 */
- (void)downAllCommomGroup:(NSNotification *)note {
    NSInteger count = [note.object integerValue];
    if (count != self.commonGroup.count) {
        [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
            [GCDQueue executeInMainQueue:^{
                for (LMGroupInfo *group in groups) {
                    if (![self.commonGroup containsObject:group]) {
                        [self.commonGroup objectAddObject:group];
                    } else {
                        [self.commonGroup replaceObjectAtIndex:[self.commonGroup indexOfObject:group] withObject:group];
                    }
                }
                [self formartFiendsGrouping];
            }];
        }];
    }
}

/**
 *  join common group
 */
- (void)AddCommonGroup:(NSNotification *)note {
    NSString *identifier = note.object;
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    NSInteger index = 1;
    if (self.offenFriends.count > 0) {
        index = 2;
    }
    LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
    // filter
    if (![self.commonGroup containsObject:group]) {
        if (group != nil) {
            [self.commonGroup objectAddObject:group];
        }
    }
    if (self.commonGroup.count == 1) {
        self.commonGroup = [[GroupDBManager sharedManager] commonGroupList].mutableCopy;
        NSMutableDictionary *commonGroup = [NSMutableDictionary dictionary];
        commonGroup[@"title"] = LMLocalizedString(@"Link Group Common", nil);
        commonGroup[@"titleicon"] = @"contract_group_chat";
        commonGroup[@"items"] = self.commonGroup;
        if (self.groupsFriend.count <= 0) {
            index = 0;
        }
        [_groupsFriend objectInsert:commonGroup atIndex:index];

    }
    if ([self.delegate respondsToSelector:@selector(listChange:withTabBarCount:)]) {
        [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
    }
}

/**
 *  delete common group
 */
- (void)RemoveCommonGroup:(NSNotification *)note {

    NSString *identifier = note.object;
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    NSInteger index = 1;
    if (self.offenFriends.count > 0) {
        index = 2;
    }
    NSMutableDictionary *commonGroup = [self.groupsFriend objectAtIndexCheck:index];
    for (LMGroupInfo *group in self.commonGroup) {
        if ([group.groupIdentifer isEqualToString:identifier]) {
            [self.commonGroup removeObject:group];
            break;
        }
    }
    if (self.commonGroup.count <= 0) {
        [self.groupsFriend removeObject:commonGroup];
    }
    if ([self.delegate respondsToSelector:@selector(listChange:withTabBarCount:)]) {
        [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
    }
}

- (void)clearUnreadCountWithType:(int)type {
    [[BadgeNumberManager shareManager] clearBadgeNumber:ALTYPE_CategoryTwo_NewFriend Completion:^{
        self.friendNewItem.addMeUser = nil;
        [self reloadBadgeValue];
    }];
}

/**
 *  delete user
 */
- (void)deleteUser:(NSNotification *)note {
    AccountInfo *userInfo = note.object;
    if (!userInfo) {
        return;
    }
    for (AccountInfo *user in self.offenFriends) {
        if ([userInfo.address isEqualToString:user.address]) {
            [self.offenFriends removeObject:user];
            break;
        }
    }
    for (AccountInfo *user in self.friendsArr) {
        if ([userInfo.address isEqualToString:user.address]) {
            [self.friendsArr removeObject:user];
            break;
        }
    }
    for (AccountInfo *user in self.normalFriends) {
        if ([userInfo.address isEqualToString:user.address]) {
            [self.normalFriends removeObject:user];
            break;
        }
    }
    [self addDataToGroupArray];
}

/**
 * contact exchange
 */
- (void)ContactChange:(NSNotification *)note {

    AccountInfo *changeUser = note.object;
    if (!changeUser) {
        return;
    }
    if (!changeUser.isOffenContact && [self.offenFriends containsObject:changeUser]) {
        [self.offenFriends removeObject:changeUser];
    } else if (changeUser.isOffenContact) {
        [self.normalFriends removeObject:changeUser];
    }
    [self formartFiendsGrouping];
    return;
}

/**
 *  new friend request
 */
- (void)newFriendRequest:(NSNotification *)note {

    AccountInfo *newFriend = note.object;
    if (!newFriend) {
        return;
    }
    self.friendNewItem.addMeUser = newFriend;
    [self reloadBadgeValue];
}

- (void)reloadBadgeValue {
    //badge
    [[BadgeNumberManager shareManager] getBadgeNumberCountWithMin:ALTYPE_CategoryTwo_NewFriend max:ALTYPE_CategoryTwo_PhoneContact Completion:^(NSUInteger count) {
        [GCDQueue executeInMainQueue:^{
            if (count > 0) {
                self.redCount = count;
                self.friendNewItem.FriendBadge = [NSString stringWithFormat:@"%d", (int) count];
                if ([self.delegate respondsToSelector:@selector(listChange: withTabBarCount:)]) {
                    [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
                }
            } else {
                self.redCount = 0;
                if (self.friendNewItem.FriendBadge) {
                    self.friendNewItem.FriendBadge = nil;
                }
                if ([self.delegate respondsToSelector:@selector(listChange: withTabBarCount:)]) {
                    [self.delegate listChange:self.groupsFriend withTabBarCount:self.redCount];
                }
            }
        }];
    }];
}

/**
 *  get all contacts
 */
- (void)downAllContacts {
    [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *commonGroups) {
        [self.commonGroup removeAllObjects];
        self.commonGroup = commonGroups.mutableCopy;
        [self formartFiendsGrouping];
    }];
}

/**
 *  add new user
 */
- (void)addNewUser:(NSNotification *)note {
    AccountInfo *userInfo = note.object;

    if (!userInfo) {
        return;
    }
    [self formartFiendsGrouping];
}

- (void)formartFiendsGrouping {
    [[UserDBManager sharedManager] getAllUsersWithComplete:^(NSArray *contacts) {
        [GCDQueue executeInMainQueue:^{
            for (AccountInfo *contact in contacts) {
                if (contact.isOffenContact) {
                    if (![self.offenFriends containsObject:contact]) {
                        [self.offenFriends objectAddObject:contact];
                    } else {
                        [self.offenFriends replaceObjectAtIndex:[self.offenFriends indexOfObject:contact] withObject:contact];
                    }
                } else {
                    if (![self.normalFriends containsObject:contact]) {
                        [self.normalFriends objectAddObject:contact];
                    } else {
                        [self.normalFriends replaceObjectAtIndex:[self.normalFriends indexOfObject:contact] withObject:contact];
                    }
                }
                if (![self.friendsArr containsObject:contact]) {
                    [self.friendsArr objectAddObject:contact];
                } else {
                    [self.friendsArr replaceObjectAtIndex:[self.friendsArr indexOfObject:contact] withObject:contact];
                }
            }
            [self addDataToGroupArray];
        }];
    }];
}

- (void)addDataToGroupArray {

    //indexs
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    NSMutableArray *temItems = nil;
    for (AccountInfo *info in self.normalFriends) {
        NSString *prex = @"";
        NSString *name = info.normalShowName;
        if (name.length) {
            prex = [[name transformToPinyin] substringToIndex:1];
        }
        // to leave
        if ([self preIsInAtoZ:prex]) {
            prex = [prex uppercaseString];
        } else {
            prex = @"#";
        }
        [set addObject:prex];
        // keep items
        temItems = [groupDict valueForKey:prex];
        if (!temItems) {
            temItems = [NSMutableArray array];
        }
        [temItems objectAddObject:info];
        [groupDict setObject:temItems forKey:prex];
    }
    for (NSObject *obj in set) {
        if (![self.indexs containsObject:obj]) {
            [self.indexs objectAddObject:obj];
        }
    }

    NSMutableArray *deleteIndexs = [NSMutableArray array];
    for (NSString *pre in self.indexs) {
        if (![set containsObject:pre]) {
            [deleteIndexs objectAddObject:pre];
        }
    }
    [self.indexs removeObjectsInArray:deleteIndexs];
    // array sort
    [self.indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];

    [self.groupsFriend removeAllObjects];
    // new friends
    NSMutableDictionary *newGroup = [NSMutableDictionary dictionary];
    NSMutableArray *newItems = [NSMutableArray array];
    self.friendNewItem.addMeUser = nil;
    [newItems objectAddObject:self.friendNewItem];
    newGroup[@"items"] = newItems;
    [self.groupsFriend objectAddObject:newGroup];
    // common
    if (self.offenFriends.count) {
        NSMutableDictionary *LoveGroup = [NSMutableDictionary dictionary];
        LoveGroup[@"title"] = LMLocalizedString(@"Link Favorite Friend", nil);
        LoveGroup[@"titleicon"] = @"table_header_favorite";
        LoveGroup[@"items"] = self.offenFriends;
        [self.groupsFriend objectAddObject:LoveGroup];
    }
    // common group
    if (self.commonGroup.count) {
        NSMutableDictionary *commonGroup = [NSMutableDictionary dictionary];
        commonGroup[@"title"] = LMLocalizedString(@"Link Group Common", nil);
        commonGroup[@"titleicon"] = @"contract_group_chat";
        commonGroup[@"items"] = self.commonGroup;
        [self.groupsFriend objectAddObject:commonGroup];
    }

    NSMutableDictionary *group = nil;
    NSMutableArray *items = nil;

    for (NSString *prex in self.indexs) {
        group = [NSMutableDictionary dictionary];
        items = [groupDict valueForKey:prex];
        group[@"title"] = prex;
        group[@"items"] = items;
        [self.groupsFriend objectAddObject:group];
    }

    // refresh 
    [self reloadBadgeValue];
}

- (void)dealloc {
    RemoveNofify;
}

#pragma mark - 拼音的方法

- (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}

@end
