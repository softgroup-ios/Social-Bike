//
//  ViewController.m
//  Social Bike
//
//  Created by sxsasha on 24.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "LoginVC.h"

#import "GoogleManager.h"
#import "FacebookManager.h"
#import "VKManager.h"

#import <Google/SignIn.h>
#import <VKSdk.h>
@import FirebaseAuth;
#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>

#import "StringValidator.h"
#import "constants.h"


#import "FIRServerManager.h"
#import "User.h"


@interface LoginVC () <UITextFieldDelegate,GIDSignInUIDelegate,VKSdkUIDelegate>

@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passField;

@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

@property (weak, nonatomic) IBOutlet UIButton *VKButton;
@property (weak, nonatomic) IBOutlet UIButton *FBButton;
@property (weak, nonatomic) IBOutlet UIButton *GButton;


@property (weak, nonatomic) IBOutlet UIView *loginSeperator;
@property (weak, nonatomic) IBOutlet UIView *passwordSeperator;

@property (weak, nonatomic) IBOutlet UIView *viewForCloseScreen;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@property (weak, nonatomic) UITextField *currentTextField;

@end

@implementation LoginVC

#pragma mark - life time

- (void)viewDidLoad {
    [super viewDidLoad];

//    _VKButton.layer.cornerRadius = 25.0f;
//    _VKButton.clipsToBounds = YES;
//    
//    _FBButton.layer.cornerRadius = 25.0f;
//    _FBButton.clipsToBounds = YES;
//    
//    _GButton.layer.cornerRadius = 25.0f;
//    _GButton.clipsToBounds = YES;
    
    _signInButton.layer.cornerRadius = 5.0f;
    _signInButton.clipsToBounds = YES;
    
    _signUpButton.layer.cornerRadius = 5.0f;
    _signUpButton.clipsToBounds = YES;
    
    // Create down swipe for hide keyboard
    UISwipeGestureRecognizer *swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeGestureDown];
    
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[VKManager sharedManager].sdkInstance setUiDelegate:self];
}

#pragma ToggleScreen

- (void)toggleScreenByView:(BOOL)toggle {
    
    _viewForCloseScreen.hidden = !toggle;
}

- (void)showErrorMessage:(NSString*)error {
    _errorLabel.hidden = FALSE;
    _errorLabel.text = error;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _errorLabel.hidden = TRUE;
    });
}


#pragma mark - Actions

- (IBAction)signInAction:(id)sender {
    
    [self toggleScreenByView:TRUE];
    [_currentTextField resignFirstResponder];
    
    NSString *email = _loginField.text;
    NSString *pass = _passField.text;
    BOOL isEmailValid = [StringValidator emailValidation:email];
    BOOL isPassValid = [StringValidator passwordValidation:pass];
    
    if (!isEmailValid)
        _loginSeperator.backgroundColor = WARNING_COLOR;
    
    if (!isPassValid)
        _passwordSeperator.backgroundColor = WARNING_COLOR;
    
    if (isEmailValid && isPassValid) {
        [[FIRServerManager sharedManager] authenticationWithLogin:email password:pass successBlock:^(BOOL status, NSError *error) {
            if (!error && status) {
                [self performSegueAfterLogin];
            } else {
                [self toggleScreenByView:FALSE];
                [self showErrorMessage:error.description];
            }
        }];
    } else {
        [self toggleScreenByView:FALSE];
        [self showErrorMessage:@"Email or password are not valid, try again."];
    }
}

- (IBAction)signUpAction:(id)sender {
    [self.currentTextField resignFirstResponder];
    [self performSegueWithIdentifier:@"Registration" sender:nil];
}

// Social network authorizations actions

- (IBAction)VKAction:(id)sender {
    
    __weak id weakSelf = self;
    [self toggleScreenByView:TRUE];
    [VKManager sharedManager].successBlock = ^(BOOL status, NSError *error){
        //logOut from VK
        [VKSdk forceLogout];
        
        [self toggleScreenByView:FALSE];
        if (!error && status) {
            [weakSelf performSegueAfterLogin];
        }
        else {
            [weakSelf showErrorMessage:error.localizedDescription];
        }
    };

    [VKSdk authorize:@[VK_PER_NOTIFY,VK_PER_FRIENDS,VK_PER_MESSAGES,VK_PER_EMAIL]];
}

- (IBAction)FBAction:(id)sender {
    
    __weak id weakSelf = self;
    [self toggleScreenByView:TRUE];
    [[FacebookManager sharedManager] loginToFacebook:^(BOOL status, NSError *error) {
        
        //logOut from FB
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login logOut];
        [FBSDKAccessToken setCurrentAccessToken:nil];
        
        [weakSelf toggleScreenByView:FALSE];
        if (!error && status) {
            [weakSelf performSegueAfterLogin];
        }
        else {
            [weakSelf showErrorMessage:error.localizedDescription];
        }
    }];
    
}

- (IBAction)GAction:(id)sender {

    __weak id weakSelf = self;
    [GoogleManager sharedManager].successBlock = ^(BOOL status, NSError *error){
        //logOut from GP
        [[GIDSignIn sharedInstance] signOut];
        [weakSelf toggleScreenByView:FALSE];
        if (!error && status) {
            [weakSelf performSegueAfterLogin];
        }
        else {
            [weakSelf showErrorMessage:error.localizedDescription];
        }
    };
    
    [self toggleScreenByView:TRUE];
    [GIDSignIn sharedInstance].delegate = [GoogleManager sharedManager];
    [[GIDSignIn sharedInstance] signIn];
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
    //[self dismissViewControllerAnimated:YES completion:nil];
}
- (void)vkSdkDidDismissViewController:(UIViewController *)controller {
    
}

#pragma mark - GIDSignInUIDelegate

- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    //[self toggleScreenByView:FALSE];
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

#pragma mark - Segues

- (void)performSegueAfterLogin {
    [self.currentTextField resignFirstResponder];
    [self performSegueWithIdentifier:@"afterAuthorization" sender:nil];
}



#pragma mark - Action for SwipeGesture

- (void)handleSwipeGesture:(id)sender {
    [_currentTextField resignFirstResponder];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _currentTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField isEqual:_loginField]) {
        if ([StringValidator emailValidation:_loginField.text]) {
            _loginSeperator.backgroundColor = GREY_THEME_COLOR;
        } else {
            _loginSeperator.backgroundColor = WARNING_COLOR;
        }
    } else if ([textField isEqual:_passField]) {
        if ([StringValidator passwordValidation:_passField.text]) {
            _passwordSeperator.backgroundColor = GREY_THEME_COLOR;
        } else {
            _passwordSeperator.backgroundColor = WARNING_COLOR;
        }
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:_loginField]) {
        
        [_passField becomeFirstResponder];
    } else {
        
        [textField resignFirstResponder];
    }
    return YES;
}


@end
