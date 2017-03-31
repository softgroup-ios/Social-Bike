//
//  UsersTVC.m
//  Social Bike
//
//  Created by Anton Hrabovskyi on 25.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "UsersTVC.h"
#import "SWRevealViewController.h"
#import "NewProfileVC.h"
#import "FIRServerManager.h"
#import "User.h"
#import "constants.h"
#import "PeopleListCell.h"
#import "MessagesVC.h"

@interface UsersTVC () <UISearchBarDelegate>
@property (strong, nonatomic) UIImage *userImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UISearchBar *usersSearchBar;

@property (strong, nonatomic) NSArray <User*> *allUsers;
@property (strong, nonatomic) NSArray <User*> *searchedUsers;
@end

@implementation UsersTVC

#pragma mark - life time


- (void)viewDidLoad {
    [super viewDidLoad];
    self.userImage = [UIImage imageNamed:@"default-avatar"];
    
    if ([self revealViewController]) {
        
        self.menuButton.target = [self revealViewController];
        self.menuButton.action = @selector(revealToggle:);
        [self.view addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
    [[FIRServerManager sharedManager]getAllUsersWithSuccessBlock:^(NSArray<User *> *users, NSError *error) {
        if (!error && users) {
            self.allUsers = self.searchedUsers = users;
            [self.tableView reloadData];
        }
    }];
    [self closeRevealVC];
}

-(void)closeRevealVC{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController tapGestureRecognizer];
    [revealController panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    for (NSUInteger i = 0; i < 5; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.imageView.layer.cornerRadius = cell.imageView.frame.size.height / 2.0f;
        cell.imageView.clipsToBounds = YES;
    }
}

#pragma mark - NSPredicate

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    if ([searchText isEqualToString:@""]) {
        self.searchedUsers = self.allUsers;
        [self.tableView reloadData];
        return;
    }
    
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"displayName contains[cd] %@ OR email contains[cd] %@ OR position contains[cd] %@ OR date contains[cd] %@ OR ANY emails contains[cd] %@ OR ANY phones contains[cd] %@",
                                    searchText,searchText,searchText,searchText,searchText,searchText,searchText];
    
    self.searchedUsers = [self.allUsers filteredArrayUsingPredicate:resultPredicate];
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = TRUE;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = FALSE;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    self.searchedUsers = self.allUsers;
    [self.tableView reloadData];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Table view data source

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.usersSearchBar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
        return self.searchedUsers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    User *user = [self.searchedUsers objectAtIndex:indexPath.row];
    
    PeopleListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    
    cell.profileNameTextField.text = [NSString stringWithFormat:@"%@ %@",user.name,user.lastName];
    cell.profilePosition.text = user.position;
    
    cell.sendMsgBtn.tag = indexPath.row;
    [cell.sendMsgBtn addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.currentRow = indexPath.row;
    
    [cell configurateImageView:cell.profilePhoto];
    [cell loadImageForUser:user];
    cell.onlineLabel.hidden = !user.online;
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.usersSearchBar resignFirstResponder];
    [self performSegueWithIdentifier:@"showProfile" sender:indexPath];
}

-(void) sendMessage:(UIButton*)button{
    
    [self performSegueWithIdentifier:@"sendMessageFromPeopleList" sender:[NSIndexPath indexPathForRow:button.tag inSection:0]];
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath*)sender {
    
    User *user = self.searchedUsers[sender.row];
    if ([segue.identifier isEqualToString:@"showProfile"]) {
        NewProfileVC *profileVC = [segue destinationViewController];
        [profileVC setupProfileForUser:user];
    }else
    if ([segue.identifier isEqualToString:@"sendMessageFromPeopleList"]) {
        MessagesVC *messageVC = segue.destinationViewController;
        [messageVC setAnotherUser:user];
    }
}



@end
