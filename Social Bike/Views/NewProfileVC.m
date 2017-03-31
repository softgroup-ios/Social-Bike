//
//  NewProfileVC.m
//  Social Bike
//
//  Created by Max Ostapchuk on 3/13/17.
//  Copyright © 2017 sasha. All rights reserved.
//
@import FirebaseAuth;
#import "constants.h"
#import "SWRevealViewController.h"
#import "NewProfileVC.h"
#import "PhotoEditorVC.h"
#import "MessagesVC.h"
#import "FIRServerManager.h"
#import "CloudinaryManager.h"
#import "FullScreenVC.h"

#import "NewProfileInfoCell.h"
#import "AddProfileInfoCell.h"

#import "StringValidator.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <Google/SignIn.h>
#import <VKSdk.h>

@interface NewProfileVC () <UITableViewDelegate, UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate,VKSdkDelegate,VKSdkUIDelegate,GIDSignInDelegate,GIDSignInUIDelegate,UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) User *user;
@property (strong, nonatomic) NSMutableArray *userPhones;
@property (strong, nonatomic) NSMutableArray *userEmails;

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL isOwnProfile;

@property (strong, nonatomic) UIImage  *userAvatar;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UILabel *profilePositionLabel;
@property (weak, nonatomic) IBOutlet UILabel *profileBirdthdayLabel;

@property (weak, nonatomic) IBOutlet UIView *viewWithPicker;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIPickerView *positionPickerView;
@property (strong, nonatomic) NSArray <NSString *> *positions;

@property (strong, nonatomic) NSString *mainMail;
@property (strong, nonatomic) NSString *date;
@property (weak, nonatomic) UITextField *currentTextField;

- (IBAction)sendMessageBtnClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;

@property (strong, nonatomic) NSString *fbID;
@property (strong, nonatomic) NSString *vkID;
@property (strong, nonatomic) NSString *gpID;
@property (nonatomic, strong) NSMutableDictionary <NSString*,NSString*> *socialNetworks;

@property (weak, nonatomic) IBOutlet UIButton *fbButton;
@property (weak, nonatomic) IBOutlet UIButton *vkButton;
@property (weak, nonatomic) IBOutlet UIButton *gpButton;
@property (weak, nonatomic) IBOutlet UIView *onlineView;

@end

@implementation NewProfileVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isEditing = NO;
    _positions = USER_POSITION;
    [self addRecognizerTo:_profileImageView];
    [self addRecognizerToPositionAndBirthdayLabel];
    _tableView.allowsSelectionDuringEditing = YES;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (_isOwnProfile) {
        
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftmenu_icon"] style:UIBarButtonItemStylePlain target:self.revealViewController action:@selector(revealToggle:)];
        self.navigationItem.leftBarButtonItem = menuButton;
        [self.view addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
        
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(editAction:)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
    
    [VKSdk.instance setUiDelegate:self];
    [VKSdk.instance registerDelegate:self];
    [GIDSignIn sharedInstance].delegate = self;
    [GIDSignIn sharedInstance].uiDelegate = self;
    
    if(!_isOwnProfile){
        [self setButtonsEnable];
    }
    [self closeRevealVC];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self tapDone];
}

-(void)closeRevealVC{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController tapGestureRecognizer];
    [revealController panGestureRecognizer];
}

#pragma mark - Get user

-(void)defaultUserConfig{
    if([_user.position isEqualToString:@""] || !_user.position)
        _profilePositionLabel.text = @"No position";
    if([_user.date isEqualToString:@""] || !_user.date)
        _profileBirdthdayLabel.text = @"11-11-2011";
}

-(void)phonesAndMailsUserArrays{
    _userPhones = [NSMutableArray arrayWithArray:_user.phones];
    _userEmails = [NSMutableArray arrayWithArray:_user.emails];
    if(_user.email)
        [_userEmails insertObject:_user.email atIndex:0];
}

- (void)setupOwnProfile {
    _isOwnProfile = TRUE;
    [[FIRServerManager sharedManager]getMyProfileWithSuccessBlock:^(User *user, NSError *error) {
        if (!error) {
            _user = user;
            [self phonesAndMailsUserArrays];
            [self setSocialIDs];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setButtonsEnable];
                [self configurateMainView];
                [_tableView reloadData];
            });
        }
    }];
}

- (void)setupProfileForUser:(User *)user {
    _isOwnProfile = FALSE;
    self.user = user;
    [self phonesAndMailsUserArrays];
    [self setSocialIDs];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configurateMainView];
        [_tableView reloadData];
    });
}

#pragma mark - Setup User Info

-(void)configurateMainView{
    [self downloadAndConfigAvatar];
    _firstNameField.text = _user.name;
    _lastNameField.text = _user.lastName;
    _profilePositionLabel.text = _user.position;
    _profileBirdthdayLabel.text = [self convertDateToString:[_user birthdate]];
    _onlineView.hidden = !_user.online;
    [self defaultUserConfig];
}

-(NSString*)convertDateToString:(NSDate*)date{
    
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setDateFormat:BIRTHDAY_DATE_FORMAT];
    NSString *finalDate = [dateformate stringFromDate:date];
    return  finalDate;
}

-(void)setButtonsEnable{
    if(!_vkID)
        [_vkButton setEnabled:NO];
    if(!_fbID)
        [_fbButton setEnabled:NO];
    if(!_gpID)
        [_gpButton setEnabled:NO];
}

#pragma mark - Edit Profile

- (void)editAction: (UIBarButtonItem*) sender {
    
    NSString *rightBarButtonItemTitle;
    if (_isEditing == NO) {
        _isEditing = YES;
        rightBarButtonItemTitle = @"Done";
        [self tapEdit];
        [self configurateEditView:rightBarButtonItemTitle];
    }
    else
    if([self tapDone] && _isEditing == YES){
        [self setButtonsEnable];
        rightBarButtonItemTitle = @"Edit";
        _isEditing = NO;
        [self configurateEditView:rightBarButtonItemTitle];
        [self refreshUser];
        [self sendUserModelOnServer];
    }
}

-(void)configurateEditView:(NSString*)rightBarButtonItemTitle{
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithTitle:rightBarButtonItemTitle style:UIBarButtonItemStylePlain target:self action:@selector(editAction:)];
    self.navigationItem.rightBarButtonItem = editButton;
    [self.tableView setEditing:_isEditing animated:YES];
    
    [_tableView reloadData];
}

-(void)tapEdit{
    _lastNameField.enabled = YES;
    _firstNameField.enabled = YES;
    _gpButton.enabled = YES;
    _fbButton.enabled = YES;
    _vkButton.enabled = YES;
    _sendMessageButton.enabled = NO;
}

-(BOOL)tapDone{
    [_currentTextField resignFirstResponder];
    _sendMessageButton.enabled = YES;
    
    NSString *firstName = _firstNameField.text;
    NSString *lastName = _lastNameField.text;
    
    BOOL isFirstNameValid = [StringValidator nameValidation:firstName];
    BOOL isLastNameValid = [StringValidator nameValidation:lastName];
    
    if (!isFirstNameValid || !isLastNameValid)
        [self editingErrorVC];
    
    if (isFirstNameValid && isLastNameValid) {
        _lastNameField.enabled = NO;
        _firstNameField.enabled = NO;
        _viewWithPicker.hidden = YES;
        [_user setName:firstName];
        [_user setLastName:lastName];
        return YES;
    }
    return NO;
}

-(void)setNewDate{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:DEFAULT_DATE_FORMAT];
    _date = [dateFormatter stringFromDate:_datePicker.date];
    [_user setDate:_date];
    _profileBirdthdayLabel.text = [self convertDateToString:[_user birthdate]];
}

#pragma mark - TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0){
        if(_isEditing)
            return _userPhones.count+1;
        return _userPhones.count;
    }
    else
    if(section == 1){
        if(_isEditing){
            return _userEmails.count+2;
        }
            return _userEmails.count;
    }else
        return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger section = indexPath.section;
    if(section == 0){
        if(indexPath.row == _userPhones.count){
            AddProfileInfoCell *addInfoCell = [tableView dequeueReusableCellWithIdentifier:@"addUserInfo"];
            addInfoCell.addInfoLabel.text = @"Add phone number";
            return addInfoCell;
        }else
        {
            NewProfileInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoCell"];
            [cell configurateInfoCell:[_userPhones objectAtIndex:indexPath.row] andSection:YES];
            return cell;
        }
    }else
        if(section == 1){
            if(indexPath.row == _userEmails.count){
                AddProfileInfoCell *addInfoCell = [tableView dequeueReusableCellWithIdentifier:@"addUserInfo"];
                addInfoCell.addInfoLabel.text = @"Add email";
                return addInfoCell;
            }else
            if(indexPath.row == _userEmails.count+1){
                UITableViewCell *deleteCell = [tableView dequeueReusableCellWithIdentifier:@"deleteProfile"];
                return deleteCell;
            }else
            if(indexPath.row == 0 && _user.email){
                NewProfileInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoCell"];
                [cell configurateInfoCell:_user.email andSection:NO];
                return cell;
            }else
            {
                NewProfileInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoCell"];
                [cell configurateInfoCell:[_userEmails objectAtIndex:indexPath.row] andSection:NO];
                return cell;
            }
        }
    return nil;
}

#pragma mark - TableView header

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 20.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40.f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    view.tintColor = GREY_BACKGROUND_COLOR;
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont systemFontOfSize:14];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.textLabel.textAlignment = NSTextAlignmentLeft;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger numOfRows = [tableView numberOfRowsInSection:section];
    if(section == 0)
    {
        if(numOfRows == 0)
            return  @"";
        return @"Phones";
    }
    else
    {
        if(numOfRows == 0)
            return  @"";
        return @"Emails";
    }
}

-(void)reloadTableViewSections:(NSInteger)section{
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    [set addIndex:section];
    [_tableView reloadSections:set withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - TableViewEditing

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if(_isEditing){
        NSInteger numOfRows = [tableView numberOfRowsInSection:indexPath.section];
        if(indexPath.row == numOfRows-1)
            return NO;
        if(indexPath.section == 1){
            if((indexPath.row == 0 && _user.email) || indexPath.row == numOfRows-2)
                return NO;
        }
        return YES;
    }
    else
        return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
    {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if(indexPath.section == 0){
            [self.userPhones removeObjectAtIndex:indexPath.row];
            [self reloadTableViewSections:0];
        }else
        if(indexPath.section == 1){
            [self.userEmails removeObjectAtIndex:indexPath.row];
            [self reloadTableViewSections:1];
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSInteger section = indexPath.section;
    cell.selected = NO;
    
    if(tableView.isEditing){
        if(section == 0){
            if(indexPath.row == _userPhones.count) {
                [self addInfoCellClick:section];
            }
        }
        else
        if(section == 1){
            if(indexPath.row == _userEmails.count) {
                [self addInfoCellClick:section];
            }
            else
            if(indexPath.row == _userEmails.count+1) {
                [[FIRServerManager sharedManager]deleteProfileWithSuccessBlock:^(BOOL status, NSError *error) {
                    if(status == YES && !error){
                        [self performSegueWithIdentifier:@"logOut" sender:nil];
                    }else
                    {
                        [self showMessage:error.localizedDescription withTitle:@"Ops"];
                    }
                }];
            }
        }
    }
    else
    {
        if(section == 0){
            NSString *phNo = _userPhones[indexPath.row];
            NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",phNo]];
            
            if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
                [[UIApplication sharedApplication] openURL:phoneUrl];
            } else
            {
                [self showMessage:@"Calls are not available!" withTitle:@"Ops"];
            }
        }
        else
        if(section == 1){
            NSString *subject = [NSString stringWithFormat:@"Subject"];
            NSString *mail = _userEmails[indexPath.row];
            NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
            NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"mailto:?to=%@&subject=%@",
                                                        [mail stringByAddingPercentEncodingWithAllowedCharacters:set],
                                                        [subject stringByAddingPercentEncodingWithAllowedCharacters:set]]];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            } else
            {
                [self showMessage:@"Email sending is not available!" withTitle:@"Ops"];
            }
        }
    }
}

#pragma mark - Buttons actions

- (IBAction)sendMessageBtnClick:(id)sender {
    [self performSegueWithIdentifier:@"sendMessage" sender:nil];
}

- (void)addInfoCellClick:(NSInteger)section {
    if(section == 0){
        [self addAlertVCWith:@"phone" and:section];
    }else
    {
        [self addAlertVCWith:@"email" and:section];
    }
}

#pragma mark - Alerts

-(void)addNewInfoSection:(NSString*)info inSection:(NSInteger)section{
    
    BOOL isInfoValid = NO;
    if(section == 0)
        isInfoValid = [StringValidator phoneValidator:info];
    if(section == 1)
        isInfoValid = [StringValidator emailValidation:info];
    
    if (!isInfoValid)
        [self editingErrorVC];
    else
    if (isInfoValid) {
        
        if(section == 0){
            [_userPhones addObject:info];
            [self reloadTableViewSections:0];
        }else
        if(section == 1){
            [_userEmails addObject:info];
            [self reloadTableViewSections:1];
        }
    }
}

-(void)addAlertVCWith:(NSString*)title and:(NSInteger)section{
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"Please enter info"
                               message:[NSString stringWithFormat:@"Enter %@",title]
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
                                                   
                                                   UITextField *textField = alert.textFields[0];
                                                   [self addNewInfoSection:textField.text inSection:section];
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
  
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = title;
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)editingErrorVC{
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Invalid Input"
                                message:@"Incorrect editing. Check input text."
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction
                         actionWithTitle:@"Continue"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Refresh model

-(void)refreshUser{
    if(_user.email){
        [_user setEmail:_userEmails[0]];
        [_user setEmails:[_userEmails objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,_userEmails.count-1)]]];
    }
    else
        [_user setEmails:_userEmails];
    [_user setPhones:_userPhones];
    [_user setSocial:_socialNetworks];
}
-(void)sendUserModelOnServer{
    [[FIRServerManager sharedManager]editProfile:_user successBlock:^(BOOL status, NSError *error) {
        
    }];
}
#pragma mark - Social buttons

-(void)setSocialIDs{
    _socialNetworks = [NSMutableDictionary dictionaryWithDictionary:_user.social];
    NSString *vk = [_socialNetworks objectForKey:@"VK"];
    NSString *fb = [_socialNetworks objectForKey:@"FB"];
    NSString *gp = [_socialNetworks objectForKey:@"GP"];
    if(gp){
        _gpID = [_socialNetworks objectForKey:@"GP"];
    }
    if(vk){
        _vkID = [_socialNetworks objectForKey:@"VK"];
    }
    if(fb){
        _fbID = [_socialNetworks objectForKey:@"FB"];
    }
}

- (IBAction)VKAction:(id)sender {
    if(_isEditing){
        [VKSdk authorize:@[VK_PER_NOTIFY,VK_PER_FRIENDS,VK_PER_MESSAGES,VK_PER_EMAIL]];
    }
    else
    {
        NSURL *appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"vk://vk.com/id%@",_vkID]];
        NSURL *safariUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.vk.com/id%@",_vkID]];
        if ([[UIApplication sharedApplication] canOpenURL:appUrl]){
            [[UIApplication sharedApplication] openURL:appUrl];
        }else
        {
            [[UIApplication sharedApplication] openURL:safariUrl];
        }
    }
}

- (IBAction)FBAction:(id)sender {
    if(_isEditing){
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        login.loginBehavior = FBSDKLoginBehaviorNative;
        
        [login logInWithReadPermissions:@[@"public_profile",@"email",@"user_friends",@"user_birthday"]
                     fromViewController:nil
                                handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                    
                                    if (!error && !result.isCancelled && result.token) {
                                        _fbID = result.token.userID;
                                        [_socialNetworks setObject:_fbID forKey:@"FB"];
                                        [login logOut];
                                    }
                                }];
    }
    else
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.fb.com/%@",_fbID]];
        if ([[UIApplication sharedApplication] canOpenURL:url]){
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (IBAction)GAction:(id)sender {
    if(_isEditing){
        [[GIDSignIn sharedInstance] signIn];
    }else
    {
        if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"gplus://plus.google.com/%@",_gpID]]]) {
            if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://plus.google.com/%@",_gpID]]]) {
                
            }
        }
    }
}


#pragma mark - VKSdkUIDelegate

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
    [self presentViewController:controller animated:YES completion:nil];
}
- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    VKCaptchaViewController *vc = [VKCaptchaViewController captchaControllerWithError:captchaError];
    [vc presentIn:self];
}

- (void)vkSdkWillDismissViewController:(UIViewController *)controller {
    
}
- (void)vkSdkDidDismissViewController:(UIViewController *)controller {

}

#pragma mark - VKSdkDelegate

- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result {
    
    if(result.state != VKAuthorizationError && result.token) {
        _vkID = result.token.userId;
        [_socialNetworks setObject:_vkID forKey:@"VK"];
        [VKSdk forceLogout];
    }
}
- (void)vkSdkUserAuthorizationFailed {
    
}

- (void)vkSdkAuthorizationStateUpdatedWithResult:(VKAuthorizationResult *)result {
    
}

#pragma mark - GIDSignInDelegate

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {

    if (user && !error) {
        _gpID = user.userID;
        [_socialNetworks setObject:_gpID forKey:@"GP"];
        [signIn signOut];
    }
}

#pragma mark - GIDSignInUIDelegate

- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    
}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn
presentViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn
dismissViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Config Image

-(void)downloadAndConfigAvatar{
    _profileImageView.image = [UIImage imageNamed:@"default-avatar"];
    [[FIRServerManager sharedManager] loadProfilePhotoForUser:_user successBlock:^(UIImage *image) {
        if(image){
            _profileImageView.image = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(100,100)];
            _userAvatar = image;
        }           
    }];
    _profileImageView.layer.cornerRadius = _profileImageView.frame.size.width / 2;
    _profileImageView.clipsToBounds = YES;
}

#pragma mark - Tap recognizers

-(void)addRecognizerTo:(UIImageView*)imageView{
    UITapGestureRecognizer *usdTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageClick)];
    usdTap.numberOfTapsRequired = 1;
    [imageView setUserInteractionEnabled:YES];
    [imageView addGestureRecognizer:usdTap];
}

-(void)addRecognizerToPositionAndBirthdayLabel{
    UITapGestureRecognizer *positionGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(posotionLabelTapped:)];
    positionGestureRecognizer.numberOfTapsRequired = 1;
    [_profilePositionLabel addGestureRecognizer:positionGestureRecognizer];
    _profilePositionLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *birthdayGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(posotionLabelTapped:)];
    birthdayGestureRecognizer.numberOfTapsRequired = 1;
    [_profileBirdthdayLabel addGestureRecognizer:birthdayGestureRecognizer];
    _profileBirdthdayLabel.userInteractionEnabled = YES;
    
    [_datePicker addTarget:self action:@selector(updateLabelFromPicker:) forControlEvents:UIControlEventValueChanged];
    
    UITapGestureRecognizer *hidePositionPicker = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidePicker)];
    hidePositionPicker.numberOfTapsRequired = 1;
    [self.mainView addGestureRecognizer:hidePositionPicker];
    self.mainView.userInteractionEnabled = YES;
}

-(void)posotionLabelTapped:(UITapGestureRecognizer*)sender{
    if(_user.date)
        _datePicker.date = [_user birthdate];
    __block BOOL isPositionPicker;
    if(sender.view.tag == 111){
        isPositionPicker = TRUE;
    }else
    if(sender.view.tag == 222){
        isPositionPicker = FALSE;
    }
    
    if(_isEditing){
        _positionPickerView.alpha = 0.f;
        _datePicker.alpha = 0.f;
        if(_viewWithPicker.hidden){
            _viewWithPicker.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                _viewWithPicker.alpha = 1.f;
                if(isPositionPicker)
                    _positionPickerView.alpha = 1.f;
                else
                    _datePicker.alpha = 1.f;
            }];
        }
        else
        {
            [UIView animateWithDuration:0.3 animations:^{
                _viewWithPicker.alpha = 0.f;
                if(isPositionPicker)
                    _positionPickerView.alpha = 0.f;
                else
                    _datePicker.alpha = 0.f;
            } completion:^(BOOL finished) {
                _viewWithPicker.hidden = YES;
            }];
        }
    }
}

-(void)hidePicker{
    if(_isEditing){
            [UIView animateWithDuration:0.3 animations:^{
                self.viewWithPicker.alpha = 0.f;
                _positionPickerView.alpha = 0.f;
                _datePicker.alpha = 0.f;
            } completion:^(BOOL finished) {
                _viewWithPicker.hidden = YES;
            }];
    }
}

-(void)profileImageClick{
    if (_isEditing) {
        [self imagePickerClicked:self.view];
    }else
        if (_userAvatar) {
            UINavigationController *nav = [FullScreenVC returnFromStorybord];
            FullScreenVC *fullScreen = nav.viewControllers.firstObject;
            fullScreen.image = _userAvatar;
            [self presentViewController:nav animated:YES completion:nil];
        }
}

- (IBAction)updateLabelFromPicker:(id)sender {
    [self setNewDate];
}

#pragma mark - Picker Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    return _positions.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    
    return _positions[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    self.profilePositionLabel.text = _positions[row];
    _user.position = _positions[row];
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component{
    
    NSAttributedString *styledString = [[NSAttributedString alloc] initWithString:_positions[row] attributes:@{NSForegroundColorAttributeName:[UIColor grayColor]}];
    return styledString;
}

#pragma mark - PhotoEditor Delegate

-(void)updatePhoto:(UIImage*)updatePhoto{
    self.profileImageView.image = [FIRServerManager imageWithImage:updatePhoto scaledToSize:CGSizeMake(100,100)];
    _userAvatar = updatePhoto;
    
    [[FIRServerManager sharedManager] saveProfilePhoto:updatePhoto successBlock:^(NSString *url, NSError *error) {
        self.user.photo = url;
    }];
}


#pragma mark - ImagePicker Action

-(void)showMessage:(NSString*)message withTitle:(NSString *)title
{
    UIAlertController * alert =  [UIAlertController
                                  alertControllerWithTitle:title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)imagePickerClicked: (UIView*) from {
    UIAlertController *alertWithChoice = [UIAlertController alertControllerWithTitle:@"Choose Image From:"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *editAction = [UIAlertAction actionWithTitle:@"Edit Current Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if(_user.photo){
            [self performSegueWithIdentifier:@"cropVC" sender:nil];
        }else{
            [self showMessage:@"You have no photo. Please add any photo first" withTitle:@"Wait"];
        }
    }];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSourceType:UIImagePickerControllerSourceTypeCamera];
    }];
    UIAlertAction *galleryAction = [UIAlertAction actionWithTitle:@"Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertWithChoice addAction:editAction];
    [alertWithChoice addAction:cameraAction];
    [alertWithChoice addAction:galleryAction];
    [alertWithChoice addAction:cancelAction];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alertWithChoice animated:YES completion:nil];
    }
    else {
        alertWithChoice.modalPresentationStyle = UIModalPresentationPopover;
        alertWithChoice.popoverPresentationController.sourceView = from;
        alertWithChoice.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self presentViewController:alertWithChoice animated:YES completion:nil];
    }
}

- (void)showSourceType: (UIImagePickerControllerSourceType) sourceType {
    if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    self.profileImageView.image = image;
    
    [self performSegueWithIdentifier:@"cropVC" sender:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _currentTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField isEqual:_firstNameField]) {
        if ([StringValidator nameValidation:_firstNameField.text]) {
            
            
        } else {
            [self editingErrorVC];
        }
        
    } else if ([textField isEqual:_lastNameField]) {
        if ([StringValidator nameValidation:_lastNameField.text]) {
            
            
        } else {
            [self editingErrorVC];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:_firstNameField]) {
        [_lastNameField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - Navigations

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"sendMessage"]) {
        MessagesVC *messageVC = segue.destinationViewController;
        [messageVC setAnotherUser:self.user];
    }
    else
    if ([segue.identifier isEqualToString:@"cropVC"]) {
        PhotoEditorVC *photoCropVC = segue.destinationViewController;
        photoCropVC.profileImage = self.profileImageView.image;
        photoCropVC.delegate=self;
    }
    else
    if ([segue.identifier isEqualToString:@"logOut"]) {
        [[GIDSignIn sharedInstance] signOut];
        
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logOut];
        [FBSDKAccessToken setCurrentAccessToken:nil];
        
        [VKSdk forceLogout];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        [[UIApplication sharedApplication] performSelector:@selector(setStatusTo:) withObject:@(NO)];
#pragma clang diagnostic pop
        
        [[FIRAuth auth]signOut:nil];
    }
    
}

@end
