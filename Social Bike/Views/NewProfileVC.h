//
//  NewProfileVC.h
//  Social Bike
//
//  Created by Max Ostapchuk on 3/13/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface NewProfileVC : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)setupOwnProfile;
- (void)setupProfileForUser:(User *)user;

@end
