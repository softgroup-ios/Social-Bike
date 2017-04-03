//
//  MessagesData.m
//  Social Bike
//
//  Created by sxsasha on 07.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//
#import "MessagesData.h"

#import <Firebase/Firebase.h>

#import "AsyncPhotoMediaItem.h"
#import "CloudinaryManager.h"
#import "MessagesVC.h"
#import "Chat.h"
#import "User.h"

#import "constants.h"

@implementation  JSQMessage (CreateFromDict)

- (NSDictionary *)createDictionary {
    
    NSString *myID = self.senderId;
    NSString *username = self.senderDisplayName;
    NSNumber *typeOfMessage = [NSNumber numberWithInt:self.isMediaMessage];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = CHAT_DATE_FORMAT;
    NSString *dateString = [dateFormatter stringFromDate: self.date];
    
    NSString *body = self.text;

    NSDictionary *post = @{@"uid": myID,
                           @"author": username,
                           @"date":dateString,
                           @"type":typeOfMessage,
                           @"body": body};
    
    return post;
}

- (void)createDictionaryFromMediaMessage:(NSString *)key completionBlock:(void (^)(NSDictionary *dict))completionBlock {
    
    NSString *myID = self.senderId;
    NSString *username = self.senderDisplayName;
    NSNumber *typeOfMessage = [NSNumber numberWithInt:self.isMediaMessage];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = CHAT_DATE_FORMAT;
    NSString *dateString = [dateFormatter stringFromDate: self.date];
    
    JSQPhotoMediaItem *photoItem = (AsyncPhotoMediaItem*)self.media;
    [[CloudinaryManager sharedManager] uploadImage:photoItem.image withName:key completionBlock:^(NSString *url, NSError *error) {
        if (url && !error) {
            NSDictionary *post = @{@"uid": myID,
                                   @"author": username,
                                   @"date":dateString,
                                   @"type":typeOfMessage,
                                   @"body": url};
            completionBlock(post);
        }
        else {
            completionBlock(nil);
        }
    }];
}

+ (JSQMessage*) createFromDict: (NSDictionary*)messageDict {
    
    if (![messageDict isKindOfClass:[NSDictionary class]] || !messageDict) {
        return nil;
    }
    
    NSString *senderID = [messageDict objectForKey:@"uid"];
    NSString *displayName = [messageDict objectForKey:@"author"];
    NSString *dateString = [messageDict objectForKey:@"date"];
    NSString *text = [messageDict objectForKey:@"body"];
    int typeOf = [[messageDict objectForKey:@"type"] intValue];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = CHAT_DATE_FORMAT;
    NSDate *date = [dateFormatter dateFromString:dateString];
    
    BOOL isAllString =  [senderID isKindOfClass:[NSString class]] &&
    [displayName isKindOfClass:[NSString class]]  &&
    [dateString isKindOfClass:[NSString class]]  &&
    [text isKindOfClass:[NSString class]] ;
    
    if (!text || !isAllString || !date) {
        return nil;
    }
    
    if (!typeOf) {
        return [[JSQMessage alloc] initWithSenderId:senderID senderDisplayName:displayName date:date text:text];
    }
    else {
        AsyncPhotoMediaItem *photoItem = [[AsyncPhotoMediaItem alloc]initWithURL:text];
        return [[JSQMessage alloc] initWithSenderId:senderID senderDisplayName:displayName date:date media:photoItem];
    }
}

@end









@interface MessagesData () <FIRMessagingDelegate>

@property (strong, nonatomic) Chat* chat;
@property (strong, nonatomic) FIRDatabaseReference* ref;
@property (strong, nonatomic) FIRDatabaseReference* chats;
@property (strong, nonatomic) FIRDatabaseReference* chatsInfo;
@property (strong, nonatomic) FIRDatabaseReference* currentChat;

@property (weak, nonatomic) id <UpdateChatDelegate> updateChatDelegate;
@property (strong, nonatomic) NSMutableArray <FIRDataSnapshot*> *unreadMessages;

@property (strong, nonatomic) NSString* lastReciveMessageValue;

@property (nonatomic, assign) BOOL lastMessageRecive;
@property (nonatomic, assign) BOOL allMessageRecived;

@end

@implementation MessagesData

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray array];
        self.unreadMessages = [NSMutableArray array];
        self.ref = [[FIRDatabase database] reference];
        
        //init notifications
        //[self connectToFcm];
       // [FIRMessaging messaging].remoteMessageDelegate = self;
    }
    return self;
}



- (void)dealloc {
    if (self.currentChat) {
        self.messages = nil;
        [self.currentChat removeAllObservers];
    }
}

- (instancetype)initChatWithUser:(User*)user
              updateChatDelegate:(id <UpdateChatDelegate>)delegate {
    
    self = [self init];
    if (self) {
        self.chats = [self.ref child:ALL_CHATS];
        self.chatsInfo = [self.ref child:ALL_CHATS_INFO];
        self.updateChatDelegate = delegate;
        [self createOrGetChatWithUser:user];
    }
    return self;
}

- (instancetype)initWithChat:(Chat*)chat
          updateChatDelegate:(id <UpdateChatDelegate>)delegate {
    
    self = [self init];
    if (self) {
        self.chats = [self.ref child:ALL_CHATS];
        self.updateChatDelegate = delegate;
        [self comeToChat:chat];
    }
    return self;
}

#pragma mark - Methods for recive and get messages with any of another users

- (void)createOrGetChatWithUser:(User*)user {
    NSString *myID = self.updateChatDelegate.myID;
    
    NSString* chatName;
    if([myID compare: user.uid] == NSOrderedAscending){
        chatName = [NSString stringWithFormat:@"%@-%@", myID, user.uid];
    }
    else {
        chatName = [NSString stringWithFormat:@"%@-%@", user.uid, myID];
    }
    
    __weak MessagesData *selfWeak = self;
    FIRDatabaseQuery* query = [[selfWeak.chatsInfo queryOrderedByChild:@"name"] queryEqualToValue:chatName];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if (snapshot.hasChildren) {
            FIRDataSnapshot* snapsot = snapshot.children.allObjects.firstObject;
            Chat* chat = [[Chat alloc] initWithChatInfo:snapsot.value andSnapshotKey:snapsot.key];
            [chat addSelf];
            [selfWeak comeToChat:chat];
        }
        else {
            [selfWeak createNewDialogWithUser:user withName:chatName successBlock:^(FIRDatabaseReference *ref, NSString *key) {
                if (!ref) {
                    return;
                }
                [selfWeak.chatsInfo observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                    FIRDataSnapshot *chatSnapshot = [snapshot childSnapshotForPath:key];
                    [selfWeak comeToNewChatWithSnapshot:chatSnapshot];
                }];
            }];
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        
    }];
}

- (void)comeToNewChatWithSnapshot:(FIRDataSnapshot*)chatSnapshot {
    
    self.chat = [[Chat alloc] initWithChatInfo:chatSnapshot.value andSnapshotKey:chatSnapshot.key];
    self.currentChat = [self.chats child:chatSnapshot.key];
    [self observeMessagesStartFromMessage:nil];
}

- (void)comeToChat:(Chat*)chat {
    self.chat = chat;
    self.currentChat = [self.chats child:chat.chatID];
    [self getMessagesInChat];
    [self.chat updateCountOfReadMessageForUser:self.updateChatDelegate.myID];
}

- (void)getMessagesInChat {

    __weak MessagesData *selfWeak = self;
    FIRDatabaseQuery* query = [selfWeak.currentChat queryLimitedToLast:30];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSArray <FIRDataSnapshot*> *allMessageInDict = snapshot.children.allObjects;
        selfWeak.lastReciveMessageValue = allMessageInDict.firstObject.key;
        
        for (FIRDataSnapshot* messageDict in allMessageInDict) {
            JSQMessage *message = [JSQMessage createFromDict:messageDict.value];
            if (message) {
                [selfWeak.messages addObject:message];
            }
        }
        
        //update
        [selfWeak.updateChatDelegate updateWhenComming];
        
        // observe new messages
        FIRDataSnapshot *lastMessage = snapshot.children.allObjects.lastObject;
        NSString *lastMessageKey = lastMessage.key;
        
        [selfWeak observeMessagesStartFromMessage:lastMessageKey];
    }];
}

- (void)loadNewMessagesPortion {
    
    if (self.allMessageRecived) {
        return;
    }
    
    __weak MessagesData *selfWeak = self;
    FIRDatabaseQuery* query = [[selfWeak.currentChat queryLimitedToLast:30] queryEndingAtValue:nil childKey:selfWeak.lastReciveMessageValue];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSArray <FIRDataSnapshot*> *allMessageInDict = snapshot.children.allObjects;
        NSString* lastMessageKey = allMessageInDict.firstObject.key;
        if ([lastMessageKey isEqualToString:selfWeak.lastReciveMessageValue]) {
            selfWeak.allMessageRecived = YES;
            return;
        }
        
        selfWeak.lastReciveMessageValue = lastMessageKey;
        
        __block BOOL lastMessageRecive = NO;
        [allMessageInDict enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(FIRDataSnapshot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!lastMessageRecive) {
                lastMessageRecive = YES;
                return;
            }
            JSQMessage *message = [JSQMessage createFromDict:obj.value];
            if (message) {
                [selfWeak.messages insertObject:message atIndex:0];
            }
        }];
        
        [selfWeak.updateChatDelegate updateWhenGetNewMessagesPortion];
    }];
}

- (void)observeMessagesStartFromMessage:(NSString*)lastMessageKey {
    
    FIRDatabaseQuery *query = self.currentChat;
    if (lastMessageKey) {
        query = [self.currentChat.queryOrderedByKey queryStartingAtValue:lastMessageKey];
    }
    else {
        self.allMessageRecived = YES;
        self.lastMessageRecive = YES;
    }
    
    __weak MessagesData *selfWeak = self;
    [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if (!selfWeak.lastMessageRecive) {
            selfWeak.lastMessageRecive = YES;
            return;
        }
        
        JSQMessage *message = [JSQMessage createFromDict:snapshot.value];
        if (message) {
            [selfWeak.messages addObject:message];
            if ([self isMyMessage:message]) {
                [selfWeak.updateChatDelegate updateWhenGetMyMessage];
            }
            else {
                [selfWeak.updateChatDelegate updateWhenGetNewMessage];
                [selfWeak.chat updateCountOfReadMessageForUser:selfWeak.updateChatDelegate.myID];
            }
        }
    }];
}

- (void)createNewDialogWithUser:(User*)user withName:(NSString*)name successBlock:(void (^)(FIRDatabaseReference* ref, NSString* key))successBlock {
    
    //NSString *key = name;
    NSString *key = [self.chatsInfo childByAutoId].key;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = CHAT_DATE_FORMAT;
    NSString *dateString = [dateFormatter stringFromDate: [NSDate date]];
    
    NSString *myID = self.updateChatDelegate.myID;
    NSString *userID = user.uid;
    
    NSDictionary *users = @{myID:@(0),userID:@(0)};
    
    NSDictionary *post = @{@"users": users,
                           @"name":name,
                           @"dialog":@{userID:[user displayName], myID:self.updateChatDelegate.myName},
                           @"date":dateString,
                           @"last":@"",
                           @"count":@(0)
                           };
    
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/%@/%@/",ALL_CHATS_INFO,key]: post};
    
    [self.ref updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        successBlock(ref, key);
    }];
}


- (void)sendMessage: (JSQMessage*)message {
    
    NSString *key = [self.currentChat childByAutoId].key;
    
    if (message.isMediaMessage) {
        [message createDictionaryFromMediaMessage:key completionBlock:^(NSDictionary *dict) {
            if (dict) {
                NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/%@/",key]: dict};
                
                [self.currentChat updateChildValues:childUpdates];
                [self.chat updateLastMessage:dict forUser:self.updateChatDelegate.myID];
            }
        }];
    }
    else {
        NSDictionary *chatDict = [message createDictionary];
        NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/%@/",key]: chatDict};
        
        [self.currentChat updateChildValues:childUpdates];
        [self.chat updateLastMessage:chatDict forUser:self.updateChatDelegate.myID];
    }
}

#pragma mark - Help Methods

- (BOOL) isMyMessage: (JSQMessage*)message {
    return [message.senderId isEqualToString:self.updateChatDelegate.myID];
}

- (BOOL) isMySnapsotMsg: (FIRDataSnapshot*)snapsot {
    NSString *senderID = [snapsot.value objectForKey:@"uid"];
    return [senderID isEqualToString:self.updateChatDelegate.myID];
}
#pragma mark - Not Using (Use for Notifications)

- (void)connectToFcm {
    
    // Won't connect since there is no token
    if (![[FIRInstanceID instanceID] token]) {
        return;
    }
    
    // Disconnect previous FCM connection if it exists.
    [[FIRMessaging messaging] disconnect];
    
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
        }
    }];
}

#pragma mark - <FIRMessagingDelegate>

- (void)applicationReceivedRemoteMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {
    
}



@end
