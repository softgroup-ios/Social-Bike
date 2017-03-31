//
//  AddChatUsers.m
//  Social Bike
//
//  Created by Tony Hrabovskyi on 2/20/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "AddChatUsers.h"
#import "AddingUserCell.h"
#import "FIRServerManager.h"
#import "User.h"
#import "Chat.h"

@interface AddChatUsers ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray<User *> *showingUsers;
@property (strong, nonatomic) __block NSArray<User *> *allUsers;
@property (assign, nonatomic) CFMutableBitVectorRef bitFielder;

@end

@implementation AddChatUsers

#pragma mark - LifeTime

- (void)viewDidLoad {
    [super viewDidLoad];
    _showingUsers = [NSMutableArray array];
    [[FIRServerManager sharedManager]getAllUsersWithSuccessBlock:^(NSArray<User *> *users, NSError *error) {
        if (!error) {
            self.allUsers = users;
        }
    }];    
}

#pragma mark - Actions

- (IBAction)doneAction:(id)sender {
    [self updateChatPermision];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Setter/Getter

- (void)setAllUsers:(NSArray<User *> *)allUsers {
    // users loaded from server
    _allUsers = allUsers;

    for (User* user in allUsers) {
        
        BOOL isSameUser = FALSE;
        for (User* showingUser in _editingChat.usersModel) {
            if ([user.uid isEqualToString:showingUser.uid])
                isSameUser = TRUE;
        }
        
        if (!isSameUser){
            [_showingUsers addObject:user];
        }
    }

    _bitFielder = CFBitVectorCreateMutable(kCFAllocatorDefault, _showingUsers.count);
    CFBitVectorSetCount(_bitFielder, _showingUsers.count);

    [self.tableView reloadData];
}

#pragma mark - ChatUpdate

- (void)updateChatPermision {
    
    for (int i = 0; i < _showingUsers.count; i++) {
        if (CFBitVectorGetBitAtIndex(_bitFielder, i)) {
            User *user = [_showingUsers objectAtIndex:i];
            [_editingChat addUser:user];
        }
    }
    
    [self.editingChat updatePermissions];
}

#pragma mark - UITableViewDelegete

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return _showingUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AddingUserCell *userCell = [tableView dequeueReusableCellWithIdentifier:@"AddUserCell"];
    [userCell setupCellForUser:[_showingUsers objectAtIndex:indexPath.row ]];
    userCell.accessoryType = CFBitVectorGetBitAtIndex(_bitFielder, indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return userCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CFBitVectorFlipBitAtIndex(_bitFielder, indexPath.row);
    
    cell.selected = FALSE;
    cell.accessoryType = CFBitVectorGetBitAtIndex(_bitFielder, indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    
}



@end
