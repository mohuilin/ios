//
//  RedBagNetWorkTool.m
//  Connect
//
//  Created by MoHuilin on 16/8/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RedBagNetWorkTool.h"
#import "NetWorkOperationTool.h"
#import "Protofile.pbobjc.h"
#import "ConnectTool.h"
#import "WallteNetWorkTool.h"
#import "UIAlertController+Blocks.h"
#import "UIViewController+CurrencyVC.h"


@implementation RedBagNetWorkTool

+ (void)getSendRedBagBaseInfoComplete:(void (^)(PendingPackage *pendRedBag ,NSError *error))complete{
    [NetWorkOperationTool POSTWithUrlString:RedBagPendingUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            PendingPackage *pendRedBag = [PendingPackage parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(pendRedBag,nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

+ (void)getRedBagDetailWithHashId:(NSString *)hashId complete:(void (^)(RedPackageInfo *bagInfo,NSError *error))complete{
    
    if (GJCFStringIsNull(hashId)) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"hashId is nil" code:-1 userInfo:nil]);
        }
        return;
    }
    RedPackageHash *hash = [[RedPackageHash alloc] init];
    hash.id_p = hashId;
    
    [NetWorkOperationTool POSTWithUrlString:RedBagInfoUrl postProtoData:hash.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            
            RedPackageInfo *bagInfo = [RedPackageInfo parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(bagInfo,nil);
                }
            } else{
                if (complete) {
                    complete(nil,error);
                }
            }
 
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

+ (void)grabRedBagWithHashId:(NSString *)hashId complete:(void (^)(GrabRedPackageResp *response,NSError *error))complete{

    if (GJCFStringIsNull(hashId)) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"hashid is null" code:-1 userInfo:nil]);
        }
        return;
    }
    
    
    RedPackageHash *pend = [[RedPackageHash alloc] init];
    pend.id_p = hashId;
    
    [NetWorkOperationTool POSTWithUrlString:RedBagGrabInfoUrl postProtoData:pend.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GrabRedPackageResp *redPack = [GrabRedPackageResp parseFromData:data error:&error];
            if (!error) {
                // update db
                if (complete) {
                    complete(redPack,nil);
                }
            } else{
                    if (complete) {
                        complete(nil,error);
                    }
                }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

#pragma mark - system packet

+ (void)grabSystemRedBagWithHashId:(NSString *)hashId complete:(void (^)(GrabRedPackageResp *response,NSError *error))complete{
    
    if (GJCFStringIsNull(hashId)) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"hashid is null" code:-1 userInfo:nil]);
        }
        return;
    }
    
    RedPackageHash *pend = [[RedPackageHash alloc] init];
    pend.id_p = hashId;
    
    [NetWorkOperationTool POSTWithUrlString:RedBagGrabSystemUrl postProtoData:pend.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GrabRedPackageResp *redPack = [GrabRedPackageResp parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(redPack,nil);
                }
            } else{
                if (complete) {
                    complete(nil,error);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}


+ (void)getSystemRedBagDetailWithHashId:(NSString *)hashId complete:(void (^)(RedPackageInfo *bagInfo,NSError *error))complete{
    
    if (GJCFStringIsNull(hashId)) {
        if (complete) {
            complete(nil,[NSError errorWithDomain:@"hashId is nil" code:-1 userInfo:nil]);
        }
        return;
    }
    RedPackageHash *hash = [[RedPackageHash alloc] init];
    hash.id_p = hashId;
    
    [NetWorkOperationTool POSTWithUrlString:RedBagSystemInfoUrl postProtoData:hash.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            
            RedPackageInfo *bagInfo = [RedPackageInfo parseFromData:data error:&error];
            if (!error) {
                if (complete) {
                    complete(bagInfo,nil);
                }
            }else{
                if (complete) {
                    complete(nil,error);
                }
            }
            
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}



@end
