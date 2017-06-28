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
#import "LMContactAccountInfo.h"
#import "LMRamGroupInfo.h"
#import "NSString+Pinyin.h"
#import "LMFriendRequestInfo.h"


@interface LMLinkManDataManager ()<NSMutableCopying>

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
                for (LMGroupInfo *group in groups) {
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
- (NSMutableArray *)getListGroupsFriend:(AccountInfo *)shareContact {
    
    if (self.groupsFriend.count <= 1) {
        return nil;
    }
    //get prex
    NSString *prex = [self getPrex:shareContact];
    NSMutableArray *temGroupArray = [NSMutableArray array];
    for (NSInteger index = 1; index < self.groupsFriend.count;index++) {
        NSMutableDictionary * dic = [self.groupsFriend[index] mutableCopy];
        NSMutableArray *temArray = [dic[@"items"] mutableCopy];
        NSString *temTitle = dic[@"title"];
        NSMutableArray *temCommonArray = [NSMutableArray array];
        id data = temArray[0];
        if ([data isKindOfClass:[AccountInfo class]]) {
            if (![prex isEqualToString:@"C"]) { // is not egual with connect
                if ([temArray containsObject:shareContact]) {  //delete shareContact
                    if (![self judgeDic:dic addArray:temCommonArray withArray:temArray withUser:shareContact]) {
                        continue;
                    };
                } else {  // delete Connect
                    if ([temTitle isEqualToString:@"C"]) {
                        if (![self judgeDic:dic addArray:temCommonArray withArray:temArray withUser:nil]) {
                            continue;
                        };
                    }
                }
            }else {    // is equal connect
                if ([self.offenFriends containsObject:shareContact]) {  // shareConnect exiset in offenArray
                    if (![self judgeDic:dic addArray:temCommonArray withArray:temArray withUser:shareContact]) {
                        continue;
                    };
                }else {    // connect and shareConnect is common group
                    if ([temArray containsObject:shareContact]) {
                        if (![self judgeSpecialDic:dic addArray:temCommonArray withArray:temArray withUser:shareContact]) {
                            continue;
                        }
                    }
                }
            }
        }
         [temGroupArray addObject:dic];
     }
    return temGroupArray;

}
- (BOOL)judgeSpecialDic:(NSMutableDictionary *)dic addArray:(NSMutableArray *)temCommonArray withArray:(NSMutableArray *)temArray withUser:(AccountInfo *)user {
    if (temArray.count > 2) {
        for (AccountInfo *info in temArray) {
            if (![info.address isEqualToString:user.address] && ![info.pub_key isEqualToString:kSystemIdendifier]) {
                [temCommonArray addObject:[info mutableCopy]];
            }
            dic[@"items"] = temCommonArray;
        }
        return YES;
    }else {
        return NO;
    }
}
- (BOOL)judgeDic:(NSMutableDictionary *)dic addArray:(NSMutableArray *)temCommonArray withArray:(NSMutableArray *)temArray withUser:(AccountInfo *)user {
    if (temArray.count > 1) {
        for (AccountInfo *info in temArray) {
            if (user) {
                if (![info.address isEqualToString:user.address]) {
                    [temCommonArray addObject:[info mutableCopy]];
                }
            }else {
                if (![info.pub_key isEqualToString:kSystemIdendifier]) {
                    [temCommonArray addObject:[info mutableCopy]];
                }
            }
            dic[@"items"] = temCommonArray;
        }
        return YES;
    }else {
        return NO;
    }
}
- (NSString *)getPrex:(AccountInfo *)contact {
    if (!contact) {
        return nil;
    }
    NSString *prex = @"";
    NSString *name = contact.normalShowName;
    if (name.length) {
        prex = [[name transformToPinyin] substringToIndex:1];
    }
    // to leave
    if ([prex preIsInAtoZ]) {
        prex = [prex uppercaseString];
    } else {
        prex = @"#";
    }
    return prex;
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
            for (LMGroupInfo *group in groups) {
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
    
    RegisterNotify(kFriendListChangeNotification, @selector(downAllContacts));
    
    
//    RegisterNotify(ConnnectDownAllCommonGroupCompleteNotification, @selector(downAllCommomGroup:));
//    RegisterNotify(BadgeNumberManagerBadgeChangeNotification, @selector(badgeValueChange));
//    RegisterNotify(kNewFriendRequestNotification, @selector(newFriendRequest:));
//    RegisterNotify(kAcceptNewFriendRequestNotification, @selector(addNewUser:));
//    RegisterNotify(ConnnectContactDidChangeNotification, @selector(ContactChange:));
//    RegisterNotify(ConnnectContactDidChangeDeleteUserNotification, @selector(deleteUser:));
//    RegisterNotify(ConnnectRemoveCommonGroupNotification, @selector(RemoveCommonGroup:));
//    RegisterNotify(ConnnectAddCommonGroupNotification, @selector(AddCommonGroup:));
//    RegisterNotify(ConnnectQuitGroupNotification, @selector(quitGroup:));
//    RegisterNotify(ConnectUpdateMyNickNameNotification, @selector(groupNicknameChange));
//    RegisterNotify(ConnnectGroupInfoDidChangeNotification, @selector(groupInfoChnage:));

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

/**
 *  get all contacts
 */
- (void)downAllContacts {
    [self detailGroupFriendFormat];
}

- (void)formartFiendsGrouping {
    
    if (!self.contactResults ||
        !self.commonGroupResults||!self.allNewFriendRequest) {
        self.contactResults = [[UserDBManager sharedManager] getRealmUsers];
        self.commonGroupResults = [[GroupDBManager sharedManager] realmCommonGroupList];
        self.allNewFriendRequest = [[UserDBManager sharedManager] getAllNewFriendResults];
        __weak __typeof(&*self)weakSelf = self;
        //register notification
        self.contactResultsToken = [self.contactResults addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            if (!error) {
                ///reload data
                NSMutableArray *contacts = [NSMutableArray array];
                for (LMContactAccountInfo *contact in results) {
                    AccountInfo *info = (AccountInfo *)contact.normalInfo;
                    if (info) {
                        [contacts addObject:info];
                    }
                }
                [weakSelf.offenFriends removeAllObjects];
                [weakSelf.normalFriends removeAllObjects];
                [weakSelf.friendsArr removeAllObjects];
                for (AccountInfo *contact in contacts) {
                    if (contact.isOffenContact) {
                        if (![weakSelf.offenFriends containsObject:contact]) {
                            [weakSelf.offenFriends objectAddObject:contact];
                        }
                    } else {
                        if (![weakSelf.normalFriends containsObject:contact]) {
                            [weakSelf.normalFriends objectAddObject:contact];
                        }
                    }
                    if (![weakSelf.friendsArr containsObject:contact]) {
                        [weakSelf.friendsArr objectAddObject:contact];
                    }
                }
                [weakSelf addDataToGroupArray];
            }
        }];
        self.commonGroupResultsToken = [self.commonGroupResults addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            if (!error) {
                [weakSelf.commonGroup removeAllObjects];
                for (LMRamGroupInfo *realmGroup in results) {
                    LMGroupInfo *group = (LMGroupInfo *)realmGroup.normalInfo;
                    if (group) {
                        [weakSelf.commonGroup addObject:group];
                    }
                }
                [weakSelf addDataToGroupArray];
            }
        }];
        self.allNewFriendRequestTolen = [self.allNewFriendRequest addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
            if (!error) {
                
                DDLogInfo(@"%@",results);
                LMFriendRequestInfo *friendRequestInfo = [results lastObject];
                if (friendRequestInfo) {
                    AccountInfo *newFriend = (AccountInfo *)friendRequestInfo.normalInfo;
                    if (!newFriend) {
                        return;
                    }
                    weakSelf.friendNewItem.addMeUser = newFriend;
                    [weakSelf reloadBadgeValue];
                }
            }
        }];
        
    }
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
            [deleteIndexs addObject:pre];
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
    if (self.offenFriends.count > 0) {
        NSMutableDictionary *offenFriendGroup = [NSMutableDictionary dictionary];
        offenFriendGroup[@"title"] = LMLocalizedString(@"Link Favorite Friend", nil);
        offenFriendGroup[@"titleicon"] = @"table_header_favorite";
        offenFriendGroup[@"items"] = self.offenFriends;
        [self.groupsFriend objectAddObject:offenFriendGroup];
    }
    // common group
    if (self.commonGroup.count > 0) {
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
