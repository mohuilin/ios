//
//  LMURLRouter.h
//  Connect
//
//  Created by MoHuilin on 2017/7/18.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LMURLRouter;


@protocol IServerable;
@protocol IPortable;
@protocol IProjectable;
@protocol IVersionable;
@protocol IApiable;


typedef LMURLRouter <IPortable> *(^Server)(NSString *server);

typedef LMURLRouter <IProjectable> *(^Port)(int64_t port);

typedef LMURLRouter <IVersionable> *(^Project)(NSString *project);

typedef LMURLRouter <IApiable> *(^Version)(NSString *version);

typedef LMURLRouter *(^Api)(NSString *api);


@protocol IServerable <NSObject>
@property (nonatomic ,copy ,readonly) Server server;
@end

@protocol IPortable <NSObject>
@property (nonatomic ,copy ,readonly) Port port;
@end

@protocol IProjectable <NSObject>
@property (nonatomic ,copy ,readonly) Project project;
@end

@protocol IVersionable <NSObject>
@property (nonatomic ,copy ,readonly) Version apiVersion;
@end

@protocol IApiable <NSObject>
@property (nonatomic ,copy ,readonly) Api api;
@end

@interface LMURLRouter : NSObject

+ (NSString *)makeURL:(void(^)(LMURLRouter <IServerable>*router))block;

@end
