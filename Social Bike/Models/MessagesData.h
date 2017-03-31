//
//  MessagesData.h
//  Social Bike
//
//  Created by sxsasha on 07.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"

@class FIRDatabaseReference, Chat, MessagesVC;

typedef void (^SuccessBlock)(BOOL status, NSError *error);
typedef void (^GetMsgBlock)();



@protocol UpdateChatDelegate <NSObject>
- (NSString*)myName;
- (NSString*)myID;

- (void)updateWhenComming;
- (void)updateWhenGetNewMessage;
- (void)updateWhenGetMyMessage;
- (void)updateWhenGetNewMessagesPortion;
@end



@interface JSQMessage (CreateFromDict)
- (NSDictionary *)createDictionary;
- (void)createDictionaryFromMediaMessage:(NSString *)key completionBlock:(void (^)(NSDictionary *dict))completionBlock;
+ (JSQMessage *)createFromDict:(NSDictionary *)messageDict;
@end




@class User;

@interface MessagesData : NSObject

@property (strong, nonatomic) NSMutableArray *messages;

- (instancetype)initChatWithUser:(User*)user
              updateChatDelegate:(id <UpdateChatDelegate>)delegate;

- (instancetype)initWithChat:(Chat*) chat
          updateChatDelegate:(id <UpdateChatDelegate>)delegate;

- (void)sendMessage:(JSQMessage*)message;
- (void)loadNewMessagesPortion;

@end
