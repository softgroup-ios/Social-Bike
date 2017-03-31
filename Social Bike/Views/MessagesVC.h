//
//  MessagesVC.h
//  Social Bike
//
//  Created by sxsasha on 07.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JSQMessagesViewController/JSQMessages.h>


@class User,Chat;

@interface MessagesVC : JSQMessagesViewController

@property (strong, nonatomic) User *anotherUser;
@property (strong, nonatomic) Chat *chat;

@end


