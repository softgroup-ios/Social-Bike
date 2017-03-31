//
//  ChatListCell.m
//  Social Bike
//
//  Created by Max Ostapchuk on 2/16/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "ChatListCell.h"
#import "constants.h"
#import "User.h"
#import "JSQMessages.h"
#import "FIRServerManager.h"

@implementation ChatListCell

- (void)awakeFromNib {
    [super awakeFromNib];
            
    [self configurateUnreadMsgCount:self.unreadMsgCount];
    [self configurateImageView:self.chatMainImage];
    [self configurateImageView:self.lastMessageOwnerPhoto];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    UIView * selectedBackgroundView = [[UIView alloc] init];
    [selectedBackgroundView setBackgroundColor:TEST_COLOR];
    [self setSelectedBackgroundView:selectedBackgroundView];
}

-(void)configurateImageView:(UIImageView*)imgView {
    
    imgView.image = [UIImage imageNamed:@"default-avatar"];;
    imgView.layer.cornerRadius = imgView.frame.size.width / 2;
    imgView.clipsToBounds = YES;
}

-(void)configurateUnreadMsgCount:(UILabel*)label{
    
    [label setHidden:YES];
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 8.0;
    label.backgroundColor = TEST_COLOR;
    label.textColor = [UIColor whiteColor];
}

- (void)loadLastMessageImage:(Chat*)chat{
    __block NSInteger currentRow = _currentRow;
    NSString *userId = chat.lastMessage.senderId;
    [[FIRServerManager sharedManager] getUserWithID:userId successBlock:^(User *user, NSError *error) {
        if(!error){
            if(currentRow == self.currentRow){
                [[FIRServerManager sharedManager] loadProfilePhotoForUser:user successBlock:^(UIImage *image) {
                    if(image)
                        self.lastMessageOwnerPhoto.image = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(100,100)];
                }];
            }
        }
    }];
}

-(void)setUnreadMessages:(NSInteger)count{
    if(count>0){
        [self.unreadMsgCount setHidden:NO];
        self.unreadMsgCount.text = [NSString stringWithFormat:@"%ld",count];
    }
    else {
        [self.unreadMsgCount setHidden:YES];
    }
}

@end
