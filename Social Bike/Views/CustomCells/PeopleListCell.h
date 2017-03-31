//
//  PeopleListCell.h
//  Social Bike
//
//  Created by Max Ostapchuk on 2/16/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>


@class User;

@interface PeopleListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profilePhoto;

@property (weak, nonatomic) IBOutlet UILabel *profileNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *profilePosition;
@property (weak, nonatomic) IBOutlet UIButton *sendMsgBtn;
@property (weak, nonatomic) IBOutlet UIView *onlineLabel;

@property (nonatomic) NSInteger currentRow;

- (IBAction)sendMsgBtnClick:(id)sender;
- (void)loadImageForUser:(User*)user;
- (void)configurateImageView:(UIImageView*)imgView;

@end
