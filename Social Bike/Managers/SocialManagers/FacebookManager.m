//
//  FacebookManager.m
//  Social Bike
//
//  Created by sxsasha on 24.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "FacebookManager.h"

@import FirebaseAuth;
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "User.h"
#import "FIRServerManager.h"

#import "constants.h"

@implementation FacebookManager

+(FacebookManager*) sharedManager
{
    static FacebookManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[FacebookManager alloc]init];
    });
    
    return  manager;
}

- (void)loginToFacebook:(SuccessLoginFB)successBlock {
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    login.loginBehavior = FBSDKLoginBehaviorNative;
    
    [login logInWithReadPermissions:@[@"public_profile",@"email",@"user_friends",@"user_birthday"]
                 fromViewController:nil
                            handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                
        if (!error && !result.isCancelled && result.token) {
            //success auth
            FIRAuthCredential *credential = [FIRFacebookAuthProvider credentialWithAccessToken:[FBSDKAccessToken currentAccessToken].tokenString];
            [self successfulAuth:credential successBlock:successBlock];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO,error);
            });
        }
    }];
}

- (void)successfulAuth:(FIRAuthCredential*)credential successBlock:(SuccessLoginFB)successBlock {
    
    [[FIRServerManager sharedManager] socialAuthWithCredential:credential successBlock:^(BOOL status, NSError *error) {
        if (status && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(status,error);
            });
        }
        else {
            [self getFacebookInfoAndRegistration:(FIRAuthCredential*)credential successBlock:(SuccessLoginFB)successBlock];
        }
    }];
}


- (void)getFacebookInfoAndRegistration:(FIRAuthCredential*)credential successBlock:(SuccessLoginFB)successBlock {
    
    FBSDKGraphRequest *graphRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                        parameters:@{@"fields":@"id,name,email,picture.type(large),birthday,first_name,last_name,gender"}];
    
    [graphRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error&&result) {
            User *user = [self createUserWithResult:result];
            [[FIRServerManager sharedManager] sociaRegistrationUser:user withCredential:credential successBlock:successBlock];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock (NO,error);
            });
        }
    }];
}
        
- (User*) createUserWithResult:(NSDictionary*)result {
    
    NSString *firstName = [result objectForKey:@"first_name"];
    NSString *lastName = [result objectForKey:@"last_name"];
    NSString *gender = [result objectForKey:@"gender"];
    NSString *emailString = [result objectForKey:@"email"];
    NSString *idString = [result objectForKey:@"id"];
    NSString *birthday = [result objectForKey:@"birthday"];
    
    //get fb picture
    NSString *imageURL;
    NSDictionary *picture = [result objectForKey:@"picture"];
    NSDictionary *pictureData = [picture objectForKey:@"data"];
    if (![[pictureData objectForKey:@"is_silhouette"] boolValue]) {
        imageURL = [pictureData objectForKey:@"url"];
    }
    
    NSDateFormatter *defaultDateFormat = [[NSDateFormatter alloc]init];
    defaultDateFormat.dateFormat = DEFAULT_DATE_FORMAT;
    NSDateFormatter *fcDateFormat = [[NSDateFormatter alloc]init];
    fcDateFormat.dateFormat = @"MM/dd/yyyy";
    NSDate *date = [fcDateFormat dateFromString:birthday];
    
    User *user = [[User alloc] init];
    user.name = firstName;
    user.lastName = lastName;
    user.sex = [gender isEqualToString:@"male"] ? MALE:[gender isEqualToString:@"female"] ? FEMALE : NOSET;
    user.date = [defaultDateFormat stringFromDate:date];
    user.email = emailString;
    user.photo = imageURL;
    user.social = @{SOCIAL_NETWORK_ID[FB]:idString};
    
    return user;
}

@end
