//
//  LMRandomSeedController.h
//  Connect
//
//  Created by bitmain on 2017/3/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseViewController.h"
typedef NS_ENUM(NSUInteger,SeedSouceType) {
    SeedSouceTypeCommon = 1 << 0,
    SeedSouceTypeWallet = 1 << 1
};

@interface LMRandomSeedController : BaseViewController

@property (nonatomic, assign) SeedSouceType seedSourceType;

@property(nonatomic, strong) void(^SeedBlock)(NSString *randomSeed) ;

- (instancetype)initWithMobile:(NSString *)mobile token:(NSString *)token;



@end
