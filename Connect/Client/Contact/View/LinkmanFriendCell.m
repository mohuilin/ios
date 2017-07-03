//
//  LinkmanFriendCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LinkmanFriendCell.h"
#import "YYImageCache.h"
#import "LMRamGroupInfo.h"
#import "LMContactAccountInfo.h"


@interface LinkmanFriendCell ()

@end


@implementation LinkmanFriendCell

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
    self.nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
}

- (void)setData:(id)data{
    [super setData:data];
    if ([data isKindOfClass:[LMRamGroupInfo class]]) {
        LMRamGroupInfo *groupInfo = (LMRamGroupInfo *)data;
        _nameLabel.text = groupInfo.groupName;
        [self.avatarImageView setPlaceholderImageWithAvatarUrl:groupInfo.avatarUrl];
    } else if([data isKindOfClass:[LMContactAccountInfo class]]){
        LMContactAccountInfo *contact = (LMContactAccountInfo *)data;
        if (!GJCFStringIsNull(contact.remarks)) {
            _nameLabel.text = contact.remarks;
        } else{
            _nameLabel.text = contact.username;
        }
        if (![contact.pub_key isEqualToString:kSystemIdendifier]) {
            [self.avatarImageView setPlaceholderImageWithAvatarUrl:contact.avatar];
        } else{
            self.avatarImageView.image = [UIImage imageNamed:contact.avatar];
        }
    }
}
@end
