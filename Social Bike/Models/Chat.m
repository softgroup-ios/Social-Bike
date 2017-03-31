//
//  Chat.m
//  Social Bike
//
//  Created by sxsasha on 16.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "Chat.h"
#import <Firebase/Firebase.h>
#import "JSQMessages.h"
#import "MessagesData.h"
#import "User.h"
#import "constants.h"
#import "FIRServerManager.h"
#import "CloudinaryManager.h"

@interface Chat ()

@property (nonatomic, strong) FIRDatabaseReference *allRef;
@property (nonatomic, strong) FIRDatabaseReference *chatSourceRef;
@property (nonatomic, strong) FIRDatabaseReference *chatInfoRef;
@property (strong, nonatomic) NSString  *imageURL;
@property (strong, nonatomic) NSMutableDictionary<NSString*, NSNumber*> *usersDict;

@property (copy, nonatomic) void(^completeLoadUser)(User *user);
@end

@implementation Chat


- (instancetype)initWithChatInfo:(NSDictionary *)chatInfo
                  andSnapshotKey:(NSString *)chatID {
    
    self = [super init];
    if (self) {
        
        _allRef = [[FIRDatabase database] reference];
        _chatInfoRef = [[_allRef child:ALL_CHATS_INFO] child:chatID];
        _chatSourceRef = [[_allRef child:ALL_CHATS] child:chatID];

        _chatID = chatID;
        _usersDict = [NSMutableDictionary dictionaryWithDictionary:[chatInfo objectForKey:@"users"]];
        
        //setup name of dialog
        NSDictionary* dialog = [chatInfo objectForKey:@"dialog"];
        if (dialog) {
            _isDialog = YES;
            _isOwnChat = NO;
            NSString* myName = [FIRServerManager sharedManager].getMyName;
            NSString* myID = [FIRServerManager sharedManager].getMyId;
            
            [dialog enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([key isEqualToString:myID]) {
                    if (![myName isEqualToString:obj]) {
                        //update name
                    }
                }
                else {
                    _name = obj;
                    __weak Chat *selfWeak = self;
                    [[FIRServerManager sharedManager] getUserWithID:key successBlock:^(User *user, NSError *error) {
                        if (user && !error) {
                            if (selfWeak.completeLoadUser) {
                                selfWeak.completeLoadUser(user);
                            }
                            selfWeak.usersModel = [NSMutableArray arrayWithObject:user];
                        }
                    }];
                    return;
                }
            }];
        }
        else {
            _name = [chatInfo objectForKey:@"name"];
            _adminID = [chatInfo objectForKey:@"admin"];
            NSString *myID = [[FIRServerManager sharedManager]getMyId];
            _isOwnChat = [myID isEqualToString:_adminID];
            
            NSMutableArray *array = [NSMutableArray arrayWithArray:_usersDict.allKeys];
            [array removeObject:myID];
            
            __weak Chat *selfWeak = self;
            [[FIRServerManager sharedManager]getUsersWithIDs:array successBlock:^(NSArray<User *> *users, NSError *error) {
                if (!error) {
                    selfWeak.usersModel = [NSMutableArray arrayWithArray:users];
                }
            }];
        }
        
        _createDate = [chatInfo objectForKey:@"date"];
        _imageURL = [chatInfo objectForKey:@"photo"];
        _lastMessage = [JSQMessage createFromDict:[chatInfo objectForKey:@"last"]];
        _countMessages = ((NSNumber*)[chatInfo objectForKey:@"count"]).longValue;
    }
    return self;
}


#pragma mark - Work With Chat

- (void)deleteChat {
    [self.chatSourceRef removeValue];
    [self.chatInfoRef removeValue];
}

- (void)leaveChat:(NSString*)userID {
    
    [self.chatInfoRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[snapshot.value objectForKey:@"users"]];
        
        if ([dict objectForKey:userID]) {
            [dict removeObjectForKey:userID];
            NSDictionary *updateUsersInfo = @{[NSString stringWithFormat:@"/%@/",@"users"]:dict};
            [self.chatInfoRef updateChildValues:updateUsersInfo];
        }
    }];
}

- (void)leaveOrDelete {
    
    if (_isOwnChat) {
        [self deleteChat];
    }
    else {
        NSString *userID = [FIRServerManager sharedManager].getMyId;
        [self leaveChat:userID];
    }
}

- (void)setPhoto: (UIImage*)image {
    if(!_isOwnChat){
        return;
    }

    if (image) {
        [[CloudinaryManager sharedManager] uploadImage:image withName:self.chatID completionBlock:^(NSString *url, NSError *error) {
            if (url && !error) {
                self.imageURL = url;
                [[self.chatInfoRef child:@"photo"] setValue:url];
            }
        }];
    }
}

- (void)changeName:(NSString*)name  {
    if(_isOwnChat) {
        _name = name;
        [[self.chatInfoRef child:@"name"] setValue:name];
    }
}

- (void)addUser:(User*)user  {
    if(_isOwnChat) {
        [self.usersModel addObject:user];
        NSNumber *count = [_usersDict objectForKey:user.uid];
        if (!count) {
            [_usersDict setObject:@(0) forKey:user.uid];
        }
    }
}

- (void)removeUser:(User*)user   {
    if(_isOwnChat) {
        [self.usersModel removeObject:user];
        NSNumber *count = [_usersDict objectForKey:user.uid];
        if (count) {
            [_usersDict removeObjectForKey:user.uid];
            [self removeUserFromFIR:user.uid];
        }
    }
}

- (void)addSelf  {
    NSString* myID = [FIRServerManager sharedManager].getMyId;
    NSNumber *count = [_usersDict objectForKey:myID];
    if (!count) {
        [_usersDict setObject:@(0) forKey:myID];
        [self updatePermissions];
    }
}

- (void)removeUserFromFIR:(NSString*)uid {
    [[[self.chatInfoRef child:@"users"] child:uid] removeValue];
}

- (void)updatePermissions  {
    [[self.chatInfoRef child:@"users"] updateChildValues:_usersDict];
}

- (void)updateCountOfReadMessageForUser:(NSString*)userID {
    
    [self.chatInfoRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        _countMessages = ((NSNumber*)[snapshot.value objectForKey:@"count"]).longValue;
        
        NSNumber *allCount = [snapshot.value objectForKey:@"count"];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[snapshot.value objectForKey:@"users"]];
        _countMessages = allCount.longValue;
        
        if ([dict objectForKey:userID]) {
            [dict setObject:allCount forKey:userID];
            NSDictionary *updateUsersInfo = @{[NSString stringWithFormat:@"/%@/",@"users"]:dict};
            [self.chatInfoRef updateChildValues:updateUsersInfo];
        }
    }];
}

- (void)updateLastMessage:(NSDictionary*)message
                   forUser:(NSString*)userID {
    
    [self.chatSourceRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary *post = @{
                               @"last":message,
                               @"count":[NSNumber numberWithLong:snapshot.childrenCount]
                               };
        [self.chatInfoRef updateChildValues:post withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            if (!error) {
                [self updateCountOfReadMessageForUser:userID];
            }
        }];
    }];
}

- (NSInteger) unreadMessage:(NSString*)userID {
    
    NSNumber *count = [self.usersDict objectForKey:userID];
    
    if (count) {
        return _countMessages - count.longValue;
    }
    return 0;
}

- (void)loadChatImage:(imageLoad)complete{
    if(_isDialog){
        User *user = _usersModel[0];
        if(!user){
            self.completeLoadUser = ^(User *user){
                [[CloudinaryManager sharedManager] downloadImage:user.photo completionBlock:^(UIImage *image) {
                    if(image) {
                        UIImage *resizeImage = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(50, 50)];
                        complete(resizeImage);
                    }
                }];
            };
        }
        else {
            [[CloudinaryManager sharedManager] downloadImage:user.photo completionBlock:^(UIImage *image) {
                if(image) {
                    UIImage *resizeImage = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(50, 50)];
                    complete(resizeImage);
                }
            }];
        }
    }else{
        if (self.imageURL) {
            [[CloudinaryManager sharedManager] downloadImage:self.imageURL completionBlock:^(UIImage *image) {
                if(image) {
                    UIImage *resizeImage = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(50, 50)];
                    complete(resizeImage);
                }
            }];
        }
    }
}

@end
