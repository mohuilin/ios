//
//  LMURLRouter.m
//  Connect
//
//  Created by MoHuilin on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMURLRouter.h"

@interface LMURLRouter ()<IVersionable,IPortable,IProjectable,IVersionable,IApiable>

@property (nonatomic ,copy) NSString *apiUrl;

@end

@implementation LMURLRouter

+ (NSString *)makeURL:(void(^)(LMURLRouter <IServerable>*router))block{
    if (block) {
        LMURLRouter <IServerable>*router = [[LMURLRouter<IServerable> alloc] init];
        block(router);
        return router.apiUrl;
    }
    return nil;
}

- (Server)server{
    return ^(NSString *server){
        if (server) {
            self.apiUrl = server;
        } else {
            self.apiUrl = @"http://192.168.40.4";
        }
        return self;
    };
}

- (Port)port{
    return ^(int64_t port){
        if (port) {
            self.apiUrl = [NSString stringWithFormat:@"%@:%lld",self.apiUrl,port];
        } else {
            self.apiUrl = [NSString stringWithFormat:@"%@:%d",self.apiUrl,10086];
        }
        return self;
    };
}

- (Project)project{
    return ^(NSString *project){
        if (project) {
            self.apiUrl = [NSString stringWithFormat:@"%@/%@",self.apiUrl,project];
        } else {
            self.apiUrl = [NSString stringWithFormat:@"%@/connect",self.apiUrl];
        }
        return self;
    };
}

- (Version)apiVersion{
    return ^(NSString *version){
        if (version) {
            self.apiUrl = [NSString stringWithFormat:@"%@/%@",self.apiUrl,version];
        } else {
            self.apiUrl = [NSString stringWithFormat:@"%@/v1",self.apiUrl];
        }
        return self;
    };
}

- (Api)api{
    return ^(NSString *api){
        if (api) {
            self.apiUrl = [NSString stringWithFormat:@"%@/%@",self.apiUrl,api];
        }
        return self;
    };
}

@end
