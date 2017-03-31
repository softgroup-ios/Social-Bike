//
//  LeftSideMenuTVC.m
//  Social Bike
//
//  Created by Anton Hrabovskyi on 28.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "LeftSideMenuTVC.h"
#import "NewProfileVC.h"
#import "LeftSideMenuCell.h"

#import "FIRServerManager.h"
#import "User.h"

#import <Google/SignIn.h>
#import <VKSdk.h>
#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>
@import FirebaseAuth;
@import Firebase;

#import "constants.h"

@interface LeftSideMenuTVC () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) NSArray<NSString *> *categoryNames;
@property (strong, nonatomic) NSArray<NSString *> *imagesNames;
@property (strong, nonatomic) NSArray<NSString *> *segueIdentifiers;

@property (nonatomic, strong) User *user;

@end


@implementation LeftSideMenuTVC


- (void)viewDidLoad {
    [super viewDidLoad];

    _categoryNames = @[@"Profile", @"Messages", @"People", @"Sign Out"];
    _imagesNames = @[@"default-avatar", @"leftmenu_messages", @"leftmenu_people", @"leftmenu_signout"];
    _segueIdentifiers = @[@"ShowOwnProfile", @"Messages", @"Users", @"LogOut"];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return _categoryNames.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *segueIdentifier = [_segueIdentifiers objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:segueIdentifier sender:nil];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    LeftSideMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
    
    cell.cellLabel.text = [_categoryNames objectAtIndex:indexPath.row];
    if(indexPath.row == 0){
        NSArray *subStrings = [[[FIRServerManager sharedManager]getMyName] componentsSeparatedByString:@" "];
        NSString *name = [subStrings objectAtIndex:0];
        cell.cellLabel.text = name;
    }
    
    // change selected color
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = DARKER_GREY_COLOR;
    [cell setSelectedBackgroundView:bgColorView];
    
    if(indexPath.row == 0){

        [[FIRServerManager sharedManager] getMyProfileWithSuccessBlock:^(User *user, NSError *error) {
            if(user.photo){
                [[FIRServerManager sharedManager] loadProfilePhotoForUser:user successBlock:^(UIImage *image) {
                    if(image)
                        cell.cellImageView.image = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(50,50)];
                    else
                        cell.cellImageView.image = [UIImage imageNamed:@"default-avatar"];
                }];
            }
        }];
    }else
        cell.cellImageView.image = [UIImage imageNamed:[_imagesNames objectAtIndex:indexPath.row ]];
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"LogOut"]) {
        
        //logOut from GP
        [[GIDSignIn sharedInstance] signOut];
        
        //logOut from FB
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logOut];
        [FBSDKAccessToken setCurrentAccessToken:nil];
        
        //logOut from VK
        [VKSdk forceLogout];
        
        // set status offline on firebase
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [[UIApplication sharedApplication] performSelector:@selector(setStatusTo:) withObject:@(NO)];
#pragma clang diagnostic pop
        
        //logOut from firebase
        [[FIRAuth auth]signOut:nil];
        
    } else if ([segue.identifier isEqualToString:@"ShowOwnProfile"]) {
        
        UINavigationController *navigation = (UINavigationController*)[segue destinationViewController];
        NewProfileVC *profileVC = navigation.viewControllers[0];
        [profileVC setupOwnProfile];
    }
    
}

-(void)logOut{
    [self performSegueWithIdentifier:@"LogOut" sender:nil];
}


@end
