//
//  InputPayPassView.h
//  Connect
//
//  Created by MoHuilin on 2016/11/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, InputPayPassViewStyle) {
    InputPayPassViewSetPass = 0,
    InputPayPassViewVerfyPass,
};

@interface InputPayPassView : UIView

@property(nonatomic, assign) InputPayPassViewStyle style;

@property(nonatomic, copy) void (^requestCallBack)(NSError *error);

+ (InputPayPassView *)inputPayPassWithComplete:(void (^)(InputPayPassView *passView, NSError *error, NSString *baseSeed))complete forgetPassBlock:(void (^)())forgetPassBlock closeBlock:(void (^)())closeBlock;

@end
