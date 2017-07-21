//
//  LMTransferOrderView.h
//  Connect
//
//  Created by MoHuilin on 2017/7/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OriginalTransaction;

@protocol LMTransferOrderViewDelegate <NSObject>

- (void)comfirm;

@end

@interface LMTransferOrderView : UIView

@property (nonatomic ,weak) id <LMTransferOrderViewDelegate> delegate;

- (void)comfigOrderDetail:(OriginalTransaction *)orderDetail;

@end
