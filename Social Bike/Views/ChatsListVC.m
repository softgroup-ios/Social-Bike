//
//  ChatsListVCTableViewController.m
//  Social Bike
//
//  Created by sxsasha on 10.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "ChatsListVC.h"

#import "SWRevealViewController.h"
#import <Firebase/Firebase.h>

#import "User.h"

#import "MessagesVC.h"
#import "Chat.h"

#import "constants.h"

#import "ChatListCell.h"
#import "FIRServerManager.h"
@import FirebaseAuth;

@interface ChatsListVC ()

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (nonatomic, strong) FIRDatabaseReference *allChats;
@property (nonatomic, strong) NSString *chatsFolderName;

@property (strong, nonatomic) NSMutableArray <Chat*> *arrayOfChats;

@property (strong, nonatomic) NSString *myID;
@property (strong, nonatomic) NSString *myName;

@property (assign, nonatomic) BOOL isLastChat;

@property (assign, nonatomic) FIRDatabaseHandle addHandle;
@property (assign, nonatomic) FIRDatabaseHandle removeHandle;
@property (assign, nonatomic) FIRDatabaseHandle changeHandle;


@end

@implementation ChatsListVC

#pragma mark - Main overriden methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftmenu_icon"] style:UIBarButtonItemStylePlain target:self.revealViewController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = menuButton;
    [self.view addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewChat:)];
    
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self setupMyIDAndMyName];
    [self initAll];
    
    [self closeRevealVC];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadAllChats];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribe];
}

- (void)dealloc {
    [self unsubscribe];
}

-(void)closeRevealVC{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController tapGestureRecognizer];
    [revealController panGestureRecognizer];
}

#pragma mark - Helps methods

- (void)initAll {
    
    self.ref = [[FIRDatabase database] reference];
    self.chatsFolderName = ALL_CHATS_INFO;
    self.allChats = [self.ref child: self.chatsFolderName];
}

- (void)unsubscribe {
    [self.allChats removeObserverWithHandle:self.addHandle];
    [self.allChats removeObserverWithHandle:self.removeHandle];
    [self.allChats removeObserverWithHandle:self.changeHandle];
}

- (BOOL) chatIsAvalibleForMe: (FIRDataSnapshot*) snapshot {
    
    FIRDataSnapshot *usersPermission = [snapshot childSnapshotForPath:@"users"];
    if (![usersPermission.value isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    NSString *isAvalible = [usersPermission.value objectForKey:self.myID];
    return isAvalible? YES:NO;
}


- (void)createNewChatWithName: (NSString*) chatName {
    
    NSString *key = [self.allChats childByAutoId].key;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = CHAT_DATE_FORMAT;
    NSString *dateString = [dateFormatter stringFromDate: [NSDate date]];

    NSDictionary *users = @{self.myID:@(0)};

    
    NSDictionary *post = @{@"users": users,
                           @"name": chatName,
                           @"date":dateString,
                           @"admin":self.myID,
                           @"last":@"",
                           @"count":@(0)
                           };
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/%@/%@/",self.chatsFolderName,key]: post};
    
    [self.ref updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        
    }];
}



#pragma mark - Load Chats

- (void)loadAllChats {
    
    self.arrayOfChats = [NSMutableArray array];
    [self.tableView reloadData];
    self.isLastChat = NO;
    
    __weak ChatsListVC *selfWeak = self;
    [selfWeak.allChats observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSArray <FIRDataSnapshot*> *allChatsInDict = snapshot.children.allObjects;
        
        for (FIRDataSnapshot *snapshot in allChatsInDict) {
            if([selfWeak chatIsAvalibleForMe:snapshot]) {
                Chat *chat = [[Chat alloc]initWithChatInfo:snapshot.value andSnapshotKey:snapshot.key];
                if (chat) {
                    [selfWeak.arrayOfChats addObject:chat];
                }
            }
        }
        [selfWeak chatSort];
        [selfWeak.tableView reloadData];
        
        // observe new messages
        [selfWeak observeChangesInChatsStartsFrom:allChatsInDict.lastObject.key];
    }];
}

- (void)observeChangesInChatsStartsFrom:(NSString*)lastChatKey {
    
    __weak ChatsListVC *selfWeak = self;
    
    FIRDatabaseQuery *query = selfWeak.allChats;
    if (lastChatKey) {
        query = [query.queryOrderedByKey queryStartingAtValue:lastChatKey];
    }
    else {
        selfWeak.isLastChat = YES;
    }
    
    selfWeak.addHandle = [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if (!selfWeak.isLastChat) {
            selfWeak.isLastChat = YES;
            return;
        }
        if([selfWeak chatIsAvalibleForMe:snapshot]) {
            Chat *chat = [[Chat alloc]initWithChatInfo:snapshot.value andSnapshotKey:snapshot.key];
            if (chat) {
                [selfWeak.arrayOfChats addObject:chat];
                [selfWeak.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selfWeak.arrayOfChats.count -1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        
    }];
    
    selfWeak.removeHandle = [selfWeak.allChats observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        Chat *foundChat;
        for (Chat *chat in selfWeak.arrayOfChats) {
            if([chat.chatID isEqualToString:snapshot.key]) {
                foundChat = chat;
            }
        }
        
        if (foundChat) {
            NSUInteger index = [selfWeak.arrayOfChats indexOfObject:foundChat];
            [selfWeak.arrayOfChats removeObjectAtIndex:index];
            [selfWeak.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    selfWeak.changeHandle = [selfWeak.allChats observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        Chat *foundChat;
        for (Chat *chat in selfWeak.arrayOfChats) {
            if([chat.chatID isEqualToString:snapshot.key]) {
                foundChat = chat;
                break;
            }
        }
        if (foundChat) {
            Chat *chat = [[Chat alloc]initWithChatInfo:snapshot.value andSnapshotKey:snapshot.key];
            if (chat) {
                NSUInteger index = [selfWeak.arrayOfChats indexOfObject:foundChat];
                [selfWeak.arrayOfChats replaceObjectAtIndex:index withObject:chat];
                [selfWeak chatSort];
                [selfWeak.tableView reloadData];
            }
        }
    }];
    
}


- (void)setupMyIDAndMyName {
    
    NSString *name = [FIRServerManager sharedManager].getMyName;
    NSString *myID = [FIRServerManager sharedManager].getMyId;
    BOOL isAuth = [FIRServerManager sharedManager].isAuth;
    
    if (isAuth) {
        self.myName = name;
        self.myID = myID;
    }
    else {
        self.myName = ANONIM_USER_NAME;
        self.myID = ANONIM_USER_ID;
    }
}



#pragma mark - Actions 

- (void)addNewChat: (UIBarButtonItem*) sender {
    
    UIAlertController *alertForCreateNewChat = [UIAlertController alertControllerWithTitle:@"Create New Chat" message:@"Please input name of chat" preferredStyle:UIAlertControllerStyleAlert];
    [alertForCreateNewChat addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Name";
    }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *name = alertForCreateNewChat.textFields.firstObject;
        if (name.text.length > 3) {
            [self createNewChatWithName:name.text];
        }
        else{
            [self presentViewController:alertForCreateNewChat animated:YES completion:nil];
        }
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertForCreateNewChat addAction:cancelAction];
    [alertForCreateNewChat addAction:okAction];
    
    [self presentViewController:alertForCreateNewChat animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.arrayOfChats.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    Chat *chat = [self.arrayOfChats objectAtIndex:indexPath.row];
    ChatListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    
    cell.chatName.text = chat.name;
    if(chat.lastMessage.isMediaMessage){
        cell.lastMessageText.text = @"Photo...";
    }else
    cell.lastMessageText.text = chat.lastMessage.text;
    cell.lastMessageSendTime.text = [self convertDateToString:chat.lastMessage.date];
    cell.chatMainImage.image = [UIImage imageNamed:@"default-avatar"];
    
    NSInteger row = indexPath.row;
    [chat loadChatImage:^(UIImage *image) {
        if (row == [tableView indexPathForCell:cell].row) {
            cell.chatMainImage.image = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(50,50)];
        }
    }];
    cell.currentRow = indexPath.row;
    if(chat.lastMessage){
        [cell loadLastMessageImage:chat];
    }
    [cell setUnreadMessages:[chat unreadMessage:self.myID]];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self chatDeleteApplied:indexPath];
        [tableView reloadData];

    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Chat *chat = [self.arrayOfChats objectAtIndex:indexPath.row];
    if (chat.isOwnChat) {
        return @"Delete Chat";
    }
    return @"Leave Chat";
}

#pragma mark - Data to string

-(NSString*)convertDateToString:(NSDate*)date{
    
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setDateFormat:@"MMM d, h:mm a"]; // Date formater
    NSString *finalDate = [dateformate stringFromDate:date];
    return  finalDate;
}

#pragma mark - Chat delete by swap

-(void)deleteChatByIndexPath:(NSIndexPath *)indexPath{
    
    Chat *chat = [self.arrayOfChats objectAtIndex:indexPath.row];
    [self.arrayOfChats removeObjectAtIndex:indexPath.row];
    [self.tableView reloadData];
    
    [chat leaveOrDelete];
}

-(void)chatDeleteApplied:(NSIndexPath *)indexPath{
    
    NSString *title= @"Leave", *actionTitle = @"Leave";
    NSString *message = @"Are u sure that u want to leave from this chat?";
    
    Chat *chat = [self.arrayOfChats objectAtIndex:indexPath.row];
    if (chat.isOwnChat) {
        title = @"Chat Delete";
        actionTitle = @"Delete";
        message = @"Are u sure that u want to delete this chat?";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:actionTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self deleteChatByIndexPath:indexPath];
                                                         }];
    UIAlertAction *cancelOk = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alertController addAction:deleteAction ];
    [alertController addAction:cancelOk];
    [self presentViewController:alertController animated:YES completion:nil];
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell*)sender {
   
    if ([segue.identifier isEqualToString:@"openChat"]) {
        Chat *chat = [self.arrayOfChats objectAtIndex:[self.tableView indexPathForCell:sender].row];
        
        MessagesVC *messageVC = segue.destinationViewController;
        [messageVC setChat:chat];
    }
    
}

#pragma mark - Chat sort

-(void)chatSort {
    
    [self.arrayOfChats sortUsingComparator:^NSComparisonResult(Chat *chat1, Chat *chat2) {
        
        NSInteger unreadUser1 = [chat1 unreadMessage:self.myID];
        NSInteger unreadUser2 = [chat2 unreadMessage:self.myID];
        
        if ((unreadUser1 > 0)&&(unreadUser2 <= 0)) {
            return NSOrderedAscending;
        }
        else if ((unreadUser1 <= 0)&&(unreadUser2 > 0)){
            return NSOrderedDescending;
        }
        else {
            if (!chat1.lastMessage) {
                return NSOrderedDescending;
            }
            if (!chat2.lastMessage) {
                return NSOrderedAscending;
            }
            
            return [chat2.lastMessage.date compare:chat1.lastMessage.date];
        }
    }];
}

@end
