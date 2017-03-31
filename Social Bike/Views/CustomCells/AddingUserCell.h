//
//  ChatUsersCell.h
//  Social Bike
//
//  Created by Tony Hrabovskyi on 2/20/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@interface AddingUserCell : UITableViewCell
- (void)setupCellForUser:(User*)userModel;

@end
