//
//  LMBaseModel.h
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Realm/Realm.h>

@interface LMBaseModel : RLMObject

@property(nonatomic, assign) NSInteger ID;

/**
 * init with normarl model eg:Accountinfo
 * @param info
 * @return
 */
- (LMBaseModel *)initWithNormalInfo:(id)info;

/**
 * get normarl info eg:Accountinfo 
 * @return
 */
- (id)normalInfo;

@end
