//
//  RLMRealm+LMRLMRealm.m
//  Connect
//
//  Created by MoHuilin on 2017/6/20.
//  Copyright © 2017年 Connect. All rights reserved.
//

@implementation RLMRealm (LMRLMRealm)

+ (RLMRealm *)defaultLoginUserRealm {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSArray *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [docPath objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@.realm", [[LKUserCenter shareCenter] currentLoginUser].address];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSLog(@"数据库目录 = %@", filePath);
    // Use the default directory, but replace the filename with the username
    config.fileURL = [NSURL URLWithString:filePath];
    config.readOnly = NO;
    config.schemaVersion = 1.0;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {

    };
    // Set this as the configuration used for the default Realm
    [RLMRealmConfiguration setDefaultConfiguration:config];
    return [self realmWithConfiguration:config error:nil];
}

@end
