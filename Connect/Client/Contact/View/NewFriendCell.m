//
//  NewFriendCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NewFriendCell.h"
#import "AccountInfo.h"
#import "UIImage+Color.h"


@interface NewFriendCell ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end

@implementation NewFriendCell
- (IBAction)rithtButtonAction:(id)sender {
    if ([self.data isKindOfClass:[AccountInfo class]]) {
        AccountInfo *user = (AccountInfo *)self.data;
        user.customOperation?user.customOperation():nil;
    }else {
        if (self.addButtonBlock) {
            LMFriendRecommandInfo *recommandInfo = (LMFriendRecommandInfo *)self.data;
            self.addButtonBlock(recommandInfo);
        }
    }
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    
    return self;
}

- (void)setup{
    
    
    self.nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.messageLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    self.addButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
    
    self.layoutMargins = UIEdgeInsetsZero;
    self.separatorInset = UIEdgeInsetsZero;
    
    [_addButton setBackgroundImage:[UIImage imageWithColor:XCColor(55, 198, 92)] forState:UIControlStateNormal];
    [_addButton setBackgroundImage:[UIImage imageWithColor:XCColor(242, 242, 242)] forState:UIControlStateDisabled];
    [_addButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
}

- (void)setData:(id)data{
    [super setData:data];
    if ([data isKindOfClass:[AccountInfo class]]) {
        AccountInfo *user = (AccountInfo *)data;
        self.messageLabel.hidden = NO;
        if (user.remarks && user.remarks.length) {
            _nameLabel.text = user.remarks;
        } else{
            _nameLabel.text = user.username;
        }
        
        switch (user.status) {
            case RequestFriendStatusVerfing:
            {
                [_addButton setTitle:LMLocalizedString(@"Link Verify", nil) forState:UIControlStateDisabled];
                _addButton.enabled = NO;
            }
                break;
            case RequestFriendStatusAdded:
            {
                [_addButton setTitle:LMLocalizedString(@"Link Added", nil) forState:UIControlStateDisabled];
                _addButton.enabled = NO;
            }
                break;
                
            case RequestFriendStatusAccept:
            {
                [_addButton setTitle:LMLocalizedString(@"Link Accept", nil) forState:UIControlStateNormal];
                _addButton.enabled = YES;
            }
                break;
            default:
                break;
        }
        _messageLabel.text = user.message;
        [self.avatarView setPlaceholderImageWithAvatarUrl:user.avatar];
    }else   // recommand man
    {
        if ([data isKindOfClass:[LMFriendRecommandInfo class]]) {
            LMFriendRecommandInfo *recommandInfo = (LMFriendRecommandInfo *)data;
            self.messageLabel.hidden = YES;
            [_addButton setTitle:LMLocalizedString(@"Link Add", nil) forState:UIControlStateNormal];
            _addButton.enabled = YES;
            _nameLabel.text = recommandInfo.username;
            [self.avatarView setPlaceholderImageWithAvatarUrl:recommandInfo.avatar];
        }
    }
}

@end
