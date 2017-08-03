//
//  KQXPasswordInputController.h
//  KQXPasswordInput
//
//  Created by Qingxu Kuang on 16/8/23.
//  Copyright © 2016年 Asahi Kuang. All rights reserved.
//

#import <UIKit/UIKit.h>


@class KQXPasswordInputController;

@protocol KQXPasswordInputControllerDelegate <NSObject>

@optional

- (void)passwordInputControllerDidClosed;

@end

typedef NS_ENUM(NSInteger, KQXPasswordCategory) {
    KQXPasswordCategoryVerify = 0,
    KQXPasswordCategorySet = 1
};

typedef void (^CompleteWithSelfBlock)(KQXPasswordInputController *inputPassVc,NSString *psw);

@interface KQXPasswordInputController : UIViewController

@property(nonatomic, weak) id <KQXPasswordInputControllerDelegate> delegate;


- (instancetype)initWithPasswordCategory:(KQXPasswordCategory)category complete:(CompleteWithSelfBlock)complete;

- (void)verfilySuccess:(BOOL)success;

@end
