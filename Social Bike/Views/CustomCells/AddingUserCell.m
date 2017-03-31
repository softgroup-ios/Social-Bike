//
//  ChatUsersCell.m
//  Social Bike
//
//  Created by Tony Hrabovskyi on 2/20/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "AddingUserCell.h"
#import "FIRServerManager.h"
#import "User.h"

@interface AddingUserCell ()
@property (weak, nonatomic) IBOutlet UIImageView *photoImagaView;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;

@property (assign, nonatomic) BOOL isReused;

@end

@implementation AddingUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCellForUser:(User*)userModel {
    
    _isReused = FALSE;
    _photoImagaView.image = [UIImage imageNamed:@"default-avatar"];
    
    __weak UIImageView *weakImageView = _photoImagaView;
    [[FIRServerManager sharedManager] loadProfilePhotoForUser:userModel successBlock:^(UIImage *image) {
        if (image && !_isReused) {
            weakImageView.image = image;
        }
    }];
    
    _fullNameLabel.text = userModel.displayName;
    _positionLabel.text = userModel.position;
    
}

- (void)prepareForReuse {
    _isReused = TRUE;
}


@end
