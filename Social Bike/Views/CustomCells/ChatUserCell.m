//
//  ChatUserCell.m
//  Social Bike
//
//  Created by Tony Hrabovskyi on 2/16/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "ChatUserCell.h"
#import "FIRServerManager.h"
#import "User.h"

@interface ChatUserCell ()

@property (weak, nonatomic) IBOutlet UIImageView *userPhoto;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) id<ChatEditingDelegate> delegate;
@property (weak, nonatomic) User *showingUser;
@end

@implementation ChatUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _userPhoto.layer.cornerRadius = _userPhoto.frame.size.width / 2;
    _userPhoto.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setupCellForUser:(User*)user andDelegate:(id<ChatEditingDelegate>)delegate {
    
    _showingUser = user;
    _delegate = delegate;
    _userPhoto.image = [UIImage imageNamed:@"default-avatar"];
    _rightButton.imageView.image = [UIImage imageNamed:@"remove_button"];
    
    __weak UIImageView *weakImageView = _userPhoto;
    [[FIRServerManager sharedManager] loadProfilePhotoForUser:user successBlock:^(UIImage *image) {
        if (image) {
            weakImageView.image = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(100,100)];
        }
    }];
    
    _nameLabel.text = [NSString stringWithFormat:@"%@ %@",user.name,user.lastName];
    _positionLabel.text = [user position];
}


#pragma mark - Actions

- (IBAction)rightButtonAction:(id)sender {
    [_delegate removeUserFromChat:_showingUser];
}



@end
