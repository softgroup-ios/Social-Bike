//
//  ChatListCell.h
//  Social Bike
//
//  Created by Max Ostapchuk on 2/16/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Chat.h"

@interface ChatListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *chatMainImage;
@property (weak, nonatomic) IBOutlet UILabel *chatName;
@property (weak, nonatomic) IBOutlet UILabel *lastMessageSendTime;
@property (weak, nonatomic) IBOutlet UIImageView *lastMessageOwnerPhoto;
@property (weak, nonatomic) IBOutlet UILabel *lastMessageText;
@property (nonatomic) NSInteger currentRow;

@property (weak, nonatomic) IBOutlet UILabel *unreadMsgCount;

- (void)loadLastMessageImage:(Chat*)chat;
- (void)setUnreadMessages:(NSInteger)count;

@end
