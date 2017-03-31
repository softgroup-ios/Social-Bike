//
//  PeopleListCell.m
//  Social Bike
//
//  Created by Max Ostapchuk on 2/16/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "PeopleListCell.h"
#import "FIRServerManager.h"
#import "constants.h"

@implementation PeopleListCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    [self configurateImageView:self.profilePhoto];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    UIView * selectedBackgroundView = [[UIView alloc] init];
    [selectedBackgroundView setBackgroundColor:TEST_COLOR];
    [self setSelectedBackgroundView:selectedBackgroundView];
}

-(void)configurateImageView:(UIImageView*)imgView{
    
    imgView.image = [UIImage imageNamed:@"default-avatar"];
    imgView.layer.cornerRadius = imgView.frame.size.width / 2;
    imgView.clipsToBounds = YES;
}

- (IBAction)sendMsgBtnClick:(id)sender {
    
}

- (void)loadImageForUser:(User*)user; {
    NSInteger currentRow = _currentRow;
    [[FIRServerManager sharedManager] loadProfilePhotoForUser:user successBlock:^(UIImage *image) {
        if (image && currentRow == self.currentRow) {
            CGSize size = CGSizeMake(50,50);
            self.profilePhoto.image = [FIRServerManager imageWithImage:image scaledToSize:size];
        }
        else {
            
        }
    }];
}

@end
