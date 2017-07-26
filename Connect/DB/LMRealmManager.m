//
//  LMRealmManager.m
//  Connect
//
//  Created by Connect on 2017/7/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMRealmManager.h"

@implementation LMRealmManager

CREATE_SHARED_MANAGER(LMRealmManager)

- (void)configRealm{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [docPath objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.realm", [[LKUserCenter shareCenter] currentLoginUser].address];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    
    
    /// config realm
    config.fileURL = [NSURL URLWithString:filePath];
    config.readOnly = NO;
    config.schemaVersion = 1.0;
    
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

@end
