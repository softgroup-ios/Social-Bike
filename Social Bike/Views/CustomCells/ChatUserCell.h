//
//  ChatUserCell.h
//  Social Bike
//
//  Created by Tony Hrabovskyi on 2/16/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@protocol ChatEditingDelegate <NSObject>
- (void)removeUserFromChat:(User*)user;
@end

@interface ChatUserCell : UITableViewCell
- (void)setupCellForUser:(User*)user andDelegate:(id<ChatEditingDelegate>)delegate;
@end

