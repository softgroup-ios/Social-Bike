//
//  RegisterVC.m
//  Social Bike
//
//  Created by Anton Hrabovskyi on 24.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "RegisterOneVC.h"
#import "constants.h"
#import "StringValidator.h"
#import "User.h"
#import "RegisterTwoVC.h"

@interface RegisterOneVC () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UIDatePicker *dateOfBirth;

@property (weak, nonatomic) IBOutlet UIView *firstNameSeperator;
@property (weak, nonatomic) IBOutlet UIView *lastNameSeperator;
@property (weak, nonatomic) IBOutlet UIView *dateOfBirthSeperator;
@property (weak, nonatomic) IBOutlet UIView *datePickerSeperator;
@property (weak, nonatomic) IBOutlet UIPickerView *positionPicker;

@property (weak, nonatomic) UITextField *currentTextField;

@property (strong, nonatomic) User *userModel;
@property (assign, nonatomic) BOOL isNextButtonValid;
@property (strong, nonatomic) NSArray<NSString *> *positions;

@end

@implementation RegisterOneVC

#pragma mark - life time

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _positions = USER_POSITION;
    _isNextButtonValid = TRUE;
    
    [_dateOfBirth setValue:DARKER_GREY_COLOR forKey:@"textColor"];
//    [_dateOfBirth setValue:@0.8 forKey:@"alpha"];
    [_positionPicker setValue:DARKER_GREY_COLOR forKey:@"textColor"];
//    [_positionPicker setValue:@0.8 forKey:@"alpha"];

    // Create down swipe for hide keyboard
    UISwipeGestureRecognizer *swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
    swipeGestureDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeGestureDown];
}


#pragma mark - Actions

- (IBAction)nextAction:(id)sender {
    
    if (!_isNextButtonValid)
        return;
    
    _isNextButtonValid = FALSE;
    
    [_currentTextField resignFirstResponder];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    NSString *dateOfBirth = [formatter stringFromDate:_dateOfBirth.date];
    NSString *position = [_positions objectAtIndex:[_positionPicker selectedRowInComponent:0]];
    NSString *firstName = _firstNameField.text;
    NSString *lastName = _lastNameField.text;
    
    BOOL isFirstNameValid = [StringValidator nameValidation:firstName];
    BOOL isLastNameValid = [StringValidator nameValidation:lastName];
    
    if (!isFirstNameValid)
        _firstNameSeperator.backgroundColor = WARNING_COLOR;
    
    if (!isLastNameValid)
        _lastNameSeperator.backgroundColor = WARNING_COLOR;
    
    if (isFirstNameValid && isLastNameValid) {
        
        _userModel = [User new];
        _userModel.name = firstName;
        _userModel.lastName = lastName;
        _userModel.date = dateOfBirth;
        _userModel.position = position;
        
        [self performSegueNext];
    }
    
    _isNextButtonValid = TRUE;
    
}

#pragma mark - Segues

- (void)performSegueNext {
    [self.currentTextField resignFirstResponder];
    [self performSegueWithIdentifier:@"NextRegisteration" sender:nil];
}

#pragma mark - Action for SwipeGesture

- (void)handleSwipeGesture:(id)sender {
    [_currentTextField resignFirstResponder];
}

#pragma mark - UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return _positions.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [_positions objectAtIndex:row];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _currentTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField isEqual:_firstNameField]) {
        if ([StringValidator nameValidation:_firstNameField.text]) {
            _firstNameSeperator.backgroundColor = GREY_THEME_COLOR;
            
        } else {
            _firstNameSeperator.backgroundColor = WARNING_COLOR;
        }
        
    } else if ([textField isEqual:_lastNameField]) {
        if ([StringValidator nameValidation:_lastNameField.text]) {
            _lastNameSeperator.backgroundColor = GREY_THEME_COLOR;
            
        } else {
            _lastNameSeperator.backgroundColor = WARNING_COLOR;
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    id<NavigationToNextPart> nextVC = segue.destinationViewController;
    [nextVC receiveUserModel:_userModel];
}


@end
