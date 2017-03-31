//
//  NewProfileInfoCell.m
//  Social Bike
//
//  Created by Max Ostapchuk on 3/13/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "NewProfileInfoCell.h"
#import "StringValidator.h"


@implementation NewProfileInfoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _cellIcon.layer.cornerRadius = _cellIcon.frame.size.width / 2;
    _cellIcon.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configurateInfoCell:(NSString*)model andSection:(BOOL)section{
    if(model){
        _infoLabel.text = model;
    }
    if(section){
        _cellIcon.image = [UIImage imageNamed:@"cell_phone_icon"];
        _infoLabel.text = [StringValidator checkPhoneNumberWithNewString:model];
    }
    else
        _cellIcon.image = [UIImage imageNamed:@"cell_mail_icon"];
}

@end
