//
//  LMBaseModel.m
//  Connect
//
//  Created by MoHuilin on 2017/6/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMBaseModel.h"

@implementation LMBaseModel

- (LMBaseModel *)initWithNormalInfo:(id)info {
    if (self = [super init]) {}
    return self;
}

- (id)normalInfo {
    return nil;
}

+ (NSString *)primaryKey {
    return @"ID";
}

+ (NSDictionary *)defaultPropertyValues {
    return @{
            @"ID": @([self getNextID])
    };
}

+ (NSInteger)getNextID {
    LMBaseModel *lastModel = [[[self allObjects] sortedResultsUsingKeyPath:@"ID" ascending:YES] lastObject];
    if (lastModel) {
        return lastModel.ID + 1;
    } else {
        return 1;
    }
}

@end
