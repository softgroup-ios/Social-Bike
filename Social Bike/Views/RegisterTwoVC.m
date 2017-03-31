//
//  RegisterTwoVC.m
//  Social Bike
//
//  Created by Anton Hrabovskyi on 24.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "RegisterTwoVC.h"
#import "constants.h"
#import "StringValidator.h"
#import "FIRServerManager.h"
#import "User.h"

@import FirebaseAuth;

@interface RegisterTwoVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPassField;

@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UIView *emailSeperator;
@property (weak, nonatomic) IBOutlet UIView *passSeperator;
@property (weak, nonatomic) IBOutlet UIView *confirmPassSeperator;

@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIView *viewForCloseScreen;

@property (weak, nonatomic) UITextField *currentTextField;

@property (strong, nonatomic) User *userModel;

@end

@implementation RegisterTwoVC

#pragma mark - life time
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _doneButton.layer.cornerRadius = 5.0f;
    _doneButton.clipsToBounds = YES;
}

#pragma mark - Actions

- (IBAction)doneAction:(id)sender {
    
    [self toggleScreenByView:TRUE];
    [_currentTextField resignFirstResponder];
    
    NSString *email = _emailField.text;
    NSString *pass = _passField.text;
    NSString *confirmPass = _confirmPassField.text;
    
    BOOL isEmailValid = [StringValidator emailValidation:email];
    BOOL isPassValid = [StringValidator passwordValidation:pass];
    BOOL isConfirmPassValid = [pass isEqualToString:confirmPass];
    
    if (!isEmailValid)
        _emailSeperator.backgroundColor = WARNING_COLOR;
    
    if (!isPassValid)
        _passSeperator.backgroundColor = WARNING_COLOR;
    
    if (!isConfirmPassValid)
        _confirmPassSeperator.backgroundColor = WARNING_COLOR;
    
    if (isEmailValid && isPassValid && isConfirmPassValid) {
        
        _userModel.email = email;
        _userModel.pass = pass;
        
        [[FIRServerManager sharedManager] registrationUser:_userModel successBlock:^(BOOL status, NSError *error) {
            if (!error && status) {
                [self performSegueAfterRegistration];
            } else {
                [self errorWithMessage:error.localizedDescription];
            }
        }];
    } else {
        [self errorWithMessage:@"Email or password are not valid, try again."];
    }
}

-(void)errorWithMessage:(NSString*)message {
    [self toggleScreenByView:FALSE];
    [self showErrorMessage:message];
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

#pragma mark - Segues

- (void)performSegueAfterRegistration {
    [self.currentTextField resignFirstResponder];
    [self performSegueWithIdentifier:@"afterRegisteration" sender:nil];
}

#pragma mark - NavigationToNextPart

- (void)receiveUserModel:(User*)userModel {
    _userModel = userModel;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _currentTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField isEqual:_emailField]) {
        if ([StringValidator emailValidation:_emailField.text]) {
            _emailSeperator.backgroundColor = GREY_THEME_COLOR;
            
        } else {
            _emailSeperator.backgroundColor = WARNING_COLOR;
        }
        
    } else if ([textField isEqual:_passField]) {
        if ([StringValidator passwordValidation:_passField.text]) {
            _passSeperator.backgroundColor = GREY_THEME_COLOR;
            
        } else {
            _passSeperator.backgroundColor = WARNING_COLOR;
        }
    } else if ([textField isEqual:_confirmPassField]) {
        if (_passField.text == _confirmPassField.text) {
            _confirmPassSeperator.backgroundColor = GREY_THEME_COLOR;
            
        } else {
            _confirmPassSeperator.backgroundColor = WARNING_COLOR;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField isEqual:_emailField]){
        [_passField becomeFirstResponder];
    } else if ([textField isEqual:_passField]) {
        [_confirmPassField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}


@end
