//
//  RLMRealm+LMRLMRealm.h
//  Connect
//
//  Created by MoHuilin on 2017/6/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Realm/Realm.h>

@interface RLMRealm (LMRLMRealm)

+ (RLMRealm *)defaultLoginUserRealm;

@end
