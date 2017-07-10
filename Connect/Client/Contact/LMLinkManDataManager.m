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
#import "GroupDBManager.h"
#import "NetWorkOperationTool.h"
#import "KTSContactsManager.h"
#import "PhoneContactInfo.h"
#import "ConnectTool.h"
#import "AddressBookCallBack.h"
#import "LMHistoryCacheManager.h"
#import "LMContactAccountInfo.h"
#import "LMRamGroupInfo.h"
#import "NSString+Pinyin.h"
#import "LMFriendRequestInfo.h"
#import "LMRamGroupInfo.h"
#import "LMRamMemberInfo.h"


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


@property (nonatomic ,strong) RLMResults *contactResults;
@property (nonatomic ,strong) RLMResults *commonGroupResults;
@property (nonatomic ,strong) RLMResults *allNewFriendRequest;


@property (nonatomic ,strong) RLMNotificationToken *contactResultsToken;
@property (nonatomic ,strong) RLMNotificationToken *commonGroupResultsToken;
@property (nonatomic, strong) RLMNotificationToken *allNewFriendRequestTolen;


@end


@implementation LMLinkManDataManager

CREATE_SHARED_MANAGER(LMLinkManDataManager)

- (instancetype)init {
    if (self = [super init]) {
        [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
            [GCDQueue executeInMainQueue:^{
                [self.commonGroup removeAllObjects];
                for (LMRamGroupInfo *group in groups) {
                    if (![self.commonGroup containsObject:group]) {
                        [self.commonGroup objectAddObject:group];
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

#pragma mark -  lazy

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

#pragma mark - back methods

- (NSMutableArray *)getListCommonGroup {
    return self.commonGroup;
}

- (NSMutableArray *)getListFriendsArr {
    return self.friendsArr;
}

- (NSMutableArray *)getListGroupsFriend {
    return self.groupsFriend;
}

- (NSMutableArray *)getOffenFriend {
    return self.offenFriends;

}

- (NSMutableArray *)getListIndexs {
    return self.indexs;
}


- (void)getInviteGroupMemberWithSelectedUser:(NSArray *)selectedUsers complete:(void (^)(NSMutableArray *groupArray,NSMutableArray *indexs))complete{
    NSMutableArray *groupArray = [NSMutableArray array];
    
    // 使用 NSPredicate 查询
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"pub_key != %@",kSystemIdendifier];
    RLMResults *results = [self.contactResults objectsWithPredicate:pred];
    
    //formart group
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    NSMutableArray *temItems = nil;
    for (LMContactAccountInfo *contact in results) {
        AccountInfo *userInfo = contact.normalInfo;
        if ([selectedUsers containsObject:userInfo]) {
            userInfo.isThisGroupMember = YES;
        }else {
            userInfo.isThisGroupMember = NO;
        }
        NSString *prex = @"";
        NSString *name = userInfo.remarks.length ? userInfo.remarks:userInfo.username;
        if (name.length) {
            prex = [[name transformToPinyin] substringToIndex:1];
        }
        // to leave
        if ([prex preIsInAtoZ]) {
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
        [temItems objectAddObject:userInfo];
        [groupDict setObject:temItems forKey:prex];
    }
    
    NSMutableArray *indexs = [NSMutableArray array];
    
    //index
    for (NSObject *obj in set) {
        if (![indexs containsObject:obj]) {
            [indexs objectAddObject:obj];
        }
    }
    NSMutableArray *deleteIndexs = [NSMutableArray array];
    for (NSString *pre in indexs) {
        if (![set containsObject:pre]) {
            [deleteIndexs addObject:pre];
        }
    }
    [indexs removeObjectsInArray:deleteIndexs];
    
    [indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];
    
    for (NSString *prex in indexs) {
        NSMutableArray *items = [groupDict valueForKey:prex];
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = prex;
        group.items = items;
        [groupArray objectAddObject:group];
    }
    if (complete) {
        complete(groupArray,indexs);
    }
}

- (void)getRecommandUserGroupArrayChatUser:(AccountInfo *)chatUser complete:(void (^)(NSMutableArray *groupArray,NSMutableArray *indexs))complete{
    NSMutableArray *groupArray = [NSMutableArray array];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"address != %@ and pub_key != %@",
                         chatUser.address,kSystemIdendifier];
    if (!chatUser) { //group chat
        pred = [NSPredicate predicateWithFormat:@"pub_key != %@",kSystemIdendifier];
    }
    RLMResults *results = [self.contactResults objectsWithPredicate:pred];
    
    //formart group
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    NSMutableArray *temItems = nil;
    for (LMContactAccountInfo *contact in results) {
        NSString *prex = @"";
        NSString *name = contact.remarks.length ? contact.remarks:contact.username;
        if (name.length) {
            prex = [[name transformToPinyin] substringToIndex:1];
        }
        // to leave
        if ([prex preIsInAtoZ]) {
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
        [temItems objectAddObject:contact];
        [groupDict setObject:temItems forKey:prex];
    }
    
    NSMutableArray *indexs = [NSMutableArray array];
    
    //index
    for (NSObject *obj in set) {
        if (![indexs containsObject:obj]) {
            [indexs objectAddObject:obj];
        }
    }
    NSMutableArray *deleteIndexs = [NSMutableArray array];
    for (NSString *pre in indexs) {
        if (![set containsObject:pre]) {
            [deleteIndexs addObject:pre];
        }
    }
    [indexs removeObjectsInArray:deleteIndexs];
    
    [indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];

    for (NSString *prex in indexs) {
        NSMutableArray *items = [groupDict valueForKey:prex];
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = prex;
        group.items = items;
        [groupArray objectAddObject:group];
    }
    
    if (complete) {
        complete(groupArray,indexs);
    }
}


- (void)getRecommandGroupArrayWithRecommonUser:(AccountInfo *)recmmondUser complete:(void (^)(NSMutableArray *groupArray,NSMutableArray *indexs))complete{
    if (!recmmondUser) {
        return;
    }
    NSMutableArray *groupArray = [NSMutableArray array];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"address != %@ and pub_key != %@",
                         recmmondUser.address,kSystemIdendifier];
    RLMResults *results = [self.contactResults objectsWithPredicate:pred];
    //formart group
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    NSMutableArray *temItems = nil;
    for (LMContactAccountInfo *contact in results) {
        NSString *prex = @"";
        NSString *name = contact.remarks.length ? contact.remarks:contact.username;
        if (name.length) {
            prex = [[name transformToPinyin] substringToIndex:1];
        }
        // to leave
        if ([prex preIsInAtoZ]) {
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
        [temItems objectAddObject:contact];
        [groupDict setObject:temItems forKey:prex];
    }
    
    NSMutableArray *indexs = [NSMutableArray array];
    
    //index
    for (NSObject *obj in set) {
        if (![indexs containsObject:obj]) {
            [indexs objectAddObject:obj];
        }
    }
    NSMutableArray *deleteIndexs = [NSMutableArray array];
    for (NSString *pre in indexs) {
        if (![set containsObject:pre]) {
            [deleteIndexs addObject:pre];
        }
    }
    [indexs removeObjectsInArray:deleteIndexs];
    
    [indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];
    
    
    // common group
    if (self.commonGroup.count > 0) {
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = LMLocalizedString(@"Link Group Common", nil);;
        group.items = self.commonGroup;
        group.headTitleImage = @"contract_group_chat";
        [groupArray objectAddObject:group];
    }
    
    for (NSString *prex in indexs) {
        NSMutableArray *items = [groupDict valueForKey:prex];
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = prex;
        group.items = items;
        [groupArray objectAddObject:group];
    }
    
    if (complete) {
        complete(groupArray,indexs);
    }
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
 *  detail user array
 */
- (void)detailGroupFriendFormat {
    NSArray *contacts = [[UserDBManager sharedManager] getAllUsers];
    [self.offenFriends removeAllObjects];
    [self.normalFriends removeAllObjects];
    [self.friendsArr removeAllObjects];
    for (AccountInfo *contact in contacts) {
        if (contact.isOffenContact) {
            if (![self.offenFriends containsObject:contact]) {
                [self.offenFriends objectAddObject:contact];
            }
        } else {
            if (![self.normalFriends containsObject:contact]) {
                [self.normalFriends objectAddObject:contact];
            }
        }
        if (![self.friendsArr containsObject:contact]) {
            [self.friendsArr objectAddObject:contact];
        }
    }
    [self addDataToGroupArray];
}
/**
 *  get all user array
 */
- (void)getAllLinkMan {
    
    [[GroupDBManager sharedManager] getCommonGroupListWithComplete:^(NSArray *groups) {
        [GCDQueue executeInMainQueue:^{
            [self.commonGroup removeAllObjects];
            for (LMRamGroupInfo *group in groups) {
                if (![self.commonGroup containsObject:group]) {
                    [self.commonGroup objectAddObject:group];
                }
            }
            [self detailGroupFriendFormat];
        }];
    }];
}
#pragma mark - notification method

- (void)addNotification {
    RegisterNotify(ConnnectUserAddressChangeNotification, @selector(AddressBookChange:));
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
- (void)clearUnreadCountWithType:(int)type {
    [[BadgeNumberManager shareManager] clearBadgeNumber:ALTYPE_CategoryTwo_NewFriend Completion:^{
        self.friendNewItem.addMeUser = nil;
        [self reloadBadgeValue];
    }];
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

- (void)formartFiendsGrouping {
    
    if (!self.contactResults ||
        !self.commonGroupResults||!self.allNewFriendRequest) {
        self.contactResults = [[UserDBManager sharedManager] getRealmUsers];
        self.commonGroupResults = [[GroupDBManager sharedManager] realmCommonGroupList];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          self.allNewFriendRequest = [[UserDBManager sharedManager] getAllNewFriendResults];
        });
        __weak __typeof(&*self)weakSelf = self;
        //register notification
        self.contactResultsToken = [self.contactResults addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            if (!error) {
                ///reload data
                [weakSelf.offenFriends removeAllObjects];
                [weakSelf.normalFriends removeAllObjects];
                [weakSelf.friendsArr removeAllObjects];
                
                for (LMContactAccountInfo *contact in results) {
                    if (contact.isOffenContact) {
                        [weakSelf.offenFriends addObject:contact];
                    } else {
                        [weakSelf.normalFriends addObject:contact];
                    }
                    [weakSelf.friendsArr objectAddObject:contact];
                }
                [weakSelf addDataToGroupArray];
            }
        }];
        self.commonGroupResultsToken = [self.commonGroupResults addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            if (!error) {
                [weakSelf.commonGroup removeAllObjects];
                for (LMRamGroupInfo *realmGroup in results) {
                    if (realmGroup) {
                        [weakSelf.commonGroup addObject:realmGroup];
                    }
                }
                [weakSelf addDataToGroupArray];
            }
        }];
        self.allNewFriendRequestTolen = [self.allNewFriendRequest addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            if (!error) {
                
                LMFriendRequestInfo *friendRequestInfo = [results lastObject];
                if (friendRequestInfo) {
                    AccountInfo *newFriend = (AccountInfo *)friendRequestInfo.normalInfo;
                    if (!newFriend) {
                        return;
                    }
                    //badge
                    [[BadgeNumberManager shareManager] getBadgeNumberCountWithMin:ALTYPE_CategoryTwo_NewFriend max:ALTYPE_CategoryTwo_PhoneContact Completion:^(NSUInteger count) {
                        [GCDQueue executeInMainQueue:^{
                            if (count > 0) {
                                weakSelf.friendNewItem.addMeUser = newFriend;
                                weakSelf.redCount = count;
                                weakSelf.friendNewItem.FriendBadge = [NSString stringWithFormat:@"%d", (int) count];
                                if ([weakSelf.delegate respondsToSelector:@selector(listChange: withTabBarCount:)]) {
                                    [weakSelf.delegate listChange:weakSelf.groupsFriend withTabBarCount:weakSelf.redCount];
                                }
                            }else {
                                weakSelf.redCount = 0;
                            }
                        }];
                    }];
                }
            }
        }];
        
    }
}

- (void)addDataToGroupArray {

    //clear group
    [self.groupsFriend removeAllObjects];
    
    //formart group
    NSMutableSet *set = [NSMutableSet set];
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    NSMutableArray *temItems = nil;
    for (LMContactAccountInfo *contact in self.normalFriends) {
        NSString *prex = @"";
        NSString *name = contact.remarks.length ? contact.remarks:contact.username;
        if (name.length) {
            prex = [[name transformToPinyin] substringToIndex:1];
        }
        // to leave
        if ([prex preIsInAtoZ]) {
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
        [temItems objectAddObject:contact];
        [groupDict setObject:temItems forKey:prex];
    }
    
    //index
    for (NSObject *obj in set) {
        if (![self.indexs containsObject:obj]) {
            [self.indexs objectAddObject:obj];
        }
    }
    NSMutableArray *deleteIndexs = [NSMutableArray array];
    for (NSString *pre in self.indexs) {
        if (![set containsObject:pre]) {
            [deleteIndexs addObject:pre];
        }
    }
    [self.indexs removeObjectsInArray:deleteIndexs];
    
    [self.indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        NSString *str1 = obj1;
        NSString *str2 = obj2;
        return [str1 compare:str2];
    }];

    // new friends
    NSMutableArray *newItems = [NSMutableArray array];
    self.friendNewItem.addMeUser = nil;
    [newItems objectAddObject:self.friendNewItem];
    CellGroup *newFriendGroup = [[CellGroup alloc] init];
    newFriendGroup.items = newItems;
    [self.groupsFriend objectAddObject:newFriendGroup];
    
    // common
    if (self.offenFriends.count > 0) {
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = LMLocalizedString(@"Link Favorite Friend", nil);
        group.items = self.offenFriends;
        group.headTitleImage = @"table_header_favorite";
        [self.groupsFriend objectAddObject:group];
    }
    // common group
    if (self.commonGroup.count > 0) {
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = LMLocalizedString(@"Link Group Common", nil);;
        group.items = self.commonGroup;
        group.headTitleImage = @"contract_group_chat";
        [self.groupsFriend objectAddObject:group];
    }

    for (NSString *prex in self.indexs) {
        NSMutableArray *items = [groupDict valueForKey:prex];
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = prex;
        group.items = items;
        [self.groupsFriend objectAddObject:group];
    }
    [self reloadBadgeValue];
}

- (void)dealloc {
    RemoveNofify;
    [self.commonGroupResultsToken stop];
    [self.contactResultsToken stop];
    self.contactResultsToken = nil;
    self.commonGroupResultsToken = nil;
    [self.allNewFriendRequestTolen stop];
    self.allNewFriendRequestTolen = nil;
}

@end
