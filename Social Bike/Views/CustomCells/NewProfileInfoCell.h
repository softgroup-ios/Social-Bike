//
//  NewProfileInfoCell.h
//  Social Bike
//
//  Created by Max Ostapchuk on 3/13/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewProfileInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellIcon;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
-(void)configurateInfoCell:(NSString*)model andSection:(BOOL)section;

@end
