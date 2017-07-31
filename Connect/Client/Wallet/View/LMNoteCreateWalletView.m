//
//  LMNoteCreateWalletView.m
//  Connect
//
//  Created by MoHuilin on 2017/7/28.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMNoteCreateWalletView.h"
#import "ConnectButton.h"

@implementation LMNoteCreateWalletView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.9];
        
        UILabel *tipLabel = [[UILabel alloc] init];
        tipLabel.text = LMLocalizedString(@"Wallet not create wallet", nil);
        tipLabel.textColor = [UIColor whiteColor];
        tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(50)];
        [self addSubview:tipLabel];
        
        [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(AUTO_HEIGHT(400));
            make.centerX.equalTo(self);
        }];
        
        
        ConnectButton *createWalletBtn = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Wallet Immediately create", nil) disableTitle:LMLocalizedString(@"Wallet Immediately create", nil)];
        [self addSubview:createWalletBtn];
        [createWalletBtn addTarget:self action:@selector(createWallet) forControlEvents:UIControlEventTouchUpInside];
        
        [createWalletBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(AUTO_HEIGHT(100));
            make.centerY.equalTo(self).offset(AUTO_HEIGHT(80));
            make.width.equalTo(self).multipliedBy(0.6);
            make.centerX.equalTo(self);
        }];
    }
    return self;
}

- (void)createWallet{
    if (self.delegate) {
        [self.delegate createWallet];
    }
}

@end
