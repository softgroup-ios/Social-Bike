//
//  GoogleManager.m
//  Social Bike
//
//  Created by sxsasha on 06.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "GoogleManager.h"

@import FirebaseAuth;
#import "FIRServerManager.h"
#import "User.h"

#import "constants.h"



@implementation GoogleManager

+(GoogleManager*) sharedManager
{
    static GoogleManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[GoogleManager alloc]init];
    });
    
    return  manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [GIDSignIn sharedInstance].delegate = self;
    }
    return self;
}

#pragma mark - GIDSignInDelegate

-     (void)signIn:(GIDSignIn *)signIn
  didSignInForUser:(GIDGoogleUser *)user
         withError:(NSError *)error {
    
    if (!self.successBlock) {
        return;
    }
    
    if (user && !error) {
        //auth to firebase
        GIDAuthentication *authentication = user.authentication;
        FIRAuthCredential *credential = [FIRGoogleAuthProvider credentialWithIDToken:authentication.idToken
                                         accessToken:authentication.accessToken];
        
        [[FIRServerManager sharedManager] socialAuthWithCredential:credential successBlock:^(BOOL status, NSError *error) {
            if (status && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.successBlock(YES, error);
                });
            }
            else {
                [self tryAuthWithCredential:credential andUser:user];
            }
        }];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.successBlock(NO, error);
        });
    }
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
}

#pragma mark - Try to auth and registration if fail

- (void)tryAuthWithCredential:(FIRAuthCredential*)credential andUser:(GIDGoogleUser*)user {
    
    [[FIRServerManager sharedManager] socialAuthWithCredential:credential successBlock:^(BOOL status, NSError *error) {
        if (status && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.successBlock(YES, nil);
            });
        }
        else {
            [self registrationWithCredential:credential andGoogleUser:user];
        }
    }];
}

- (void)registrationWithCredential:(FIRAuthCredential*)credential andGoogleUser:(GIDGoogleUser*)gUser {
    User *user = [self createUserFrom:gUser];
    [[FIRServerManager sharedManager] sociaRegistrationUser:user withCredential:credential successBlock:self.successBlock];
}

- (User*)createUserFrom:(GIDGoogleUser*)gUser {
    NSString *userId = gUser.userID;
    NSString *givenName = gUser.profile.givenName;
    NSString *familyName = gUser.profile.familyName;
    NSString *emailString = gUser.profile.email;
    
    NSString *imageURL;
    if(gUser.profile.hasImage) {
        imageURL = [gUser.profile imageURLWithDimension:((NSUInteger)500)].absoluteString;
    }
    
    User *user = [[User alloc] init];
    user.name = givenName;
    user.lastName = familyName;
    user.email = emailString;
    user.photo = imageURL;
    user.social = @{SOCIAL_NETWORK_ID[GP]:userId};
    
    return user;
}

@end
