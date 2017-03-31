//
//  Chat.h
//  Social Bike
//
//  Created by sxsasha on 16.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>


@class UIImage, JSQMessage, User;

@interface Chat : NSObject

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *createDate;
@property (strong, nonatomic, readonly) NSString *chatID;
@property (strong, nonatomic, readonly) JSQMessage *lastMessage;
@property (strong, nonatomic) NSMutableArray <User*> *usersModel;

@property (assign, nonatomic, readonly) long countMessages;
@property (strong, nonatomic, readonly) NSString *adminID;
@property (assign, nonatomic, readonly) BOOL isOwnChat;
@property (assign, nonatomic, readonly) BOOL isDialog;
typedef void(^imageLoad)(UIImage* image);

- (instancetype)initWithChatInfo:(NSDictionary *)chatInfo
                  andSnapshotKey:(NSString *)snapshotKey;

- (void)setPhoto: (UIImage*)image;
- (void)changeName: (NSString*)name;
- (void)addUser:(User*)user;
- (void)removeUser:(User*)user;
- (void)updatePermissions;
- (void)leaveOrDelete;
- (void)addSelf;

- (void)updateLastMessage:(NSDictionary*)message forUser:(NSString*)userID;
- (void)updateCountOfReadMessageForUser: (NSString*) userID;

- (NSInteger)unreadMessage:(NSString*)userID;
- (void)loadChatImage:(imageLoad)complete;

@end
