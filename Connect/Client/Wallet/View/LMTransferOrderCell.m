//
//  LMTransferOrderCell.m
//  Connect
//
//  Created by MoHuilin on 2017/7/21.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMTransferOrderCell.h"

@implementation LMTransferOrderCell

- (void)awakeFromNib{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

@end
