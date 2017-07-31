//
//  LMNoteCreateWalletView.h
//  Connect
//
//  Created by MoHuilin on 2017/7/28.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LMNoteCreateWalletViewDelegate <NSObject>

- (void)createWallet;

@end

@interface LMNoteCreateWalletView : UIView

@property (nonatomic ,weak) id<LMNoteCreateWalletViewDelegate> delegate;

@end
