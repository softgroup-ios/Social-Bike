//
//  ChatManageVCViewController.m
//  Social Bike
//
//  Created by Tony Hrabovskyi on 2/15/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "constants.h"
#import "FIRServerManager.h"
#import "ChatManageVC.h"
#import "ChatUserCell.h"
#import "Chat.h"
#import "User.h"
#import "NewProfileVC.h"
#import "AddChatUsers.h"
#import "ChatPhotoEditVC.h"
#import "StringValidator.h"
#import "SWRevealViewController.h"

@interface ChatManageVC () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ChatEditingDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *chatImageButton;
@property (weak, nonatomic) IBOutlet UITextField *chatNameField;

@property (strong, nonatomic) NSArray<User *> *chatUsers;
@property (assign, nonatomic) BOOL isInitialize;

@property (strong, nonatomic) UIImage *chatImage;
@end

@implementation ChatManageVC

#pragma mark - LifeTime


- (void)viewDidLoad {
    [super viewDidLoad];
    _chatImageButton.clipsToBounds = YES;
    _chatImageButton.layer.cornerRadius = _chatImageButton.frame.size.height/2;
    [self closeRevealVC];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadedData];
}

- (void)setShowingChat:(Chat *)showingChat {
    _showingChat = showingChat;
    
    [self loadedData];
}

- (void)loadedData {
    if (_isInitialize) {
        _chatUsers = _showingChat.usersModel;
        self.chatNameField.text = self.showingChat.name;
        self.chatImage = self.chatImageButton.imageView.image;
        
        __weak ChatManageVC *weakSelf = self;
        [self.showingChat loadChatImage:^(UIImage *image) {
            weakSelf.chatImage = image;
            CGSize size = CGSizeMake(65,65);
            [weakSelf.chatImageButton setImage:[FIRServerManager imageWithImage:image scaledToSize:size] forState:UIControlStateNormal];
        }];
        [self.tableView reloadData];
    } else {
        _isInitialize = TRUE;
    }
}

-(void)closeRevealVC{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController tapGestureRecognizer];
    [revealController panGestureRecognizer];
}

#pragma mark - Actions

- (IBAction)changeButtonAction:(id)sender {
    if (!self.showingChat.isOwnChat)
        return;
    
    [self performSegueWithIdentifier:@"chatPhotoShow" sender:nil];
}

#pragma mark - ChatEditingDelegate

- (void)removeUserFromChat:(User *)user {
    [_showingChat removeUser:user];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _chatUsers.count + 1;
    } else {
        return 1;
    } 
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10.0F;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && indexPath.row > 0) {
        return 60.0F;
    } else {
        return 40.0F;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [self cellButtonReuseOrInitInTableView:tableView];
            
            //setup
            cell.textLabel.text = @"Add Users";
            cell.textLabel.textColor = MAIN_THEME_COLOR;
//            cell.imageView.image = [UIImage imageNamed:@"add_new"];
        } else {
            //setup
            ChatUserCell *userCell = (ChatUserCell*)[tableView dequeueReusableCellWithIdentifier:@"ChatUserCell"];
            User *userForCell = [_chatUsers objectAtIndex:indexPath.row - 1];
            [userCell setupCellForUser:userForCell andDelegate:self];
            cell = userCell;
        }
    } else if (indexPath.section == 1) {
        cell = [self cellButtonReuseOrInitInTableView:tableView];
        
        // setup
        cell.textLabel.text = _showingChat.isOwnChat ? @"Delete Chat" : @"Leave from Chat";
        cell.textLabel.textColor = WARNING_COLOR;
    }
    
    return cell;
}

- (UITableViewCell*)cellButtonReuseOrInitInTableView:(UITableView*)tableView {
    
    UITableViewCell *buttonCell = [tableView dequeueReusableCellWithIdentifier:@"ButtonCell"];
    
    if (!buttonCell) {
        buttonCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ButtonCell"];
    }
    
    return buttonCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = FALSE;
    
    if (indexPath.section == 0) { // users present and add users button
        
        if (indexPath.row == 0) {
            [self performSegueWithIdentifier:@"AddChatUsers" sender:nil];
        } else {
            [self performSegueWithIdentifier:@"showProfile" sender:[_chatUsers objectAtIndex:indexPath.row - 1]];
        }
        
    } else if (indexPath.section == 1) { // delete chat or leave from chat
        
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@"Are you sure?"
                                      message:@""
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [_showingChat leaveOrDelete];
                                 [self.navigationController popToRootViewControllerAnimated:YES];
                             }];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     //[alert dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Alerts

-(void)addNewChatName:(NSString*)name{
    
    if ([StringValidator nameValidation:name]) {
        [self.showingChat changeName:name];
        _chatNameField.text = name;
    } else {
        name = self.showingChat.name;
    }
}
- (IBAction)changeChatName:(id)sender {
    [self addAlertVC];
}

-(void)addAlertVC{
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"Please enter info"
                               message:@"Enter new chat name"
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
                                                   
                                                   UITextField *textField = alert.textFields[0];
                                                   [self addNewChatName:textField.text];
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Enter new chat name";
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showProfile"]) {
        NewProfileVC *profileVC = [segue destinationViewController];
        [profileVC setupProfileForUser:sender];
        
    } else if ([segue.identifier isEqualToString:@"AddChatUsers"]) {
        AddChatUsers *addChatUsersVC = [segue destinationViewController];
        addChatUsersVC.editingChat = _showingChat;
        
    } else if ([segue.identifier isEqualToString:@"chatPhotoShow"]){
        ChatPhotoEditVC *chatPhotoVC = [segue destinationViewController];
        chatPhotoVC.chat = _showingChat;
        chatPhotoVC.chatImage = self.chatImage;
    }
}

@end
