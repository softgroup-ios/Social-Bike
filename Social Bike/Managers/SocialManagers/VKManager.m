//
//  VKManager.m
//  Social Bike
//
//  Created by sxsasha on 07.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "VKManager.h"
#import "constants.h"

#import "User.h"
#import "FIRServerManager.h"
@import FirebaseAuth;



@interface VKManager ()
@property (strong, nonatomic) NSString *imageURL;
@end

@implementation VKManager

+(VKManager*) sharedManager
{
    static VKManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VKManager alloc] init];
    });
    
    return  manager;
}

#pragma mark - VKSdkDelegate

- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result {
    
    if (!self.successBlock) {
        return;
    }
    if(result.state != VKAuthorizationError && result.token) {
        [self tryAuthWithToken:result.token];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.successBlock(NO,result.error);
        });
    }
}

- (void)vkSdkUserAuthorizationFailed {
    if (!self.successBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.successBlock(NO,nil);
        });
    }
}

#pragma mark - Try to auth and registration if fail

- (void)tryAuthWithToken:(VKAccessToken*)token{
    
    NSString *email = token.email;
    NSString *pass = [token.userId stringByReplacingOccurrencesOfString:@"1" withString:@"228"];
    
    [[FIRServerManager sharedManager] authenticationWithLogin:email password:pass successBlock:^(BOOL status, NSError *error) {
        if (status && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.successBlock(YES, error);
            });
        }
        else {
            [self registrationWithID:token.userId andEmail:email pass:pass];
        }
    }];
}

- (void)registrationWithID:(NSString*)idString andEmail:(NSString*)email pass:(NSString*)pass {
    
    __weak VKManager *selfWeak = self;
    VKRequest *requestPhoto = [VKApi requestWithMethod:@"users.get" andParameters:@{@"user_ids": idString, @"fields": @[@"photo_max",@"sex", @"bdate", @"contacts"]}];
    
    [requestPhoto executeWithResultBlock:^(VKResponse *response) {
        User *user = [selfWeak createUserFromResult:((NSArray*)response.json).firstObject withID:idString email:email pass:pass];
        [[FIRServerManager sharedManager] registrationUser:user successBlock:selfWeak.successBlock];
    } errorBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            selfWeak.successBlock(NO, error);
        });
    }];
}

- (User*)createUserFromResult:(NSDictionary*)vkUserDict
                            withID:(NSString*)userID
                             email:(NSString*)emailString
                              pass:(NSString*)pass {
    
    NSString *firstName = [vkUserDict objectForKey:@"first_name"];
    NSString *lastName = [vkUserDict objectForKey:@"last_name"];
    
    NSString *mobile_phone = [vkUserDict objectForKey:@"mobile_phone"];
    NSString *home_phone = [vkUserDict objectForKey:@"home_phone"];
    NSString *phone = ![mobile_phone isEqualToString:@""] ? mobile_phone : ![home_phone isEqualToString:@""] ? home_phone : nil;
    NSArray *phones = phone ? @[phone] : nil;
    
    int sexInt = [[vkUserDict objectForKey:@"sex"] intValue];
    sexInt = sexInt == 1 ? 2 : sexInt == 2 ? 1 : 0;

    NSString *birthdateString = [vkUserDict objectForKey:@"bdate"];
    NSDateFormatter *defaultDateFormat = [[NSDateFormatter alloc]init];
    defaultDateFormat.dateFormat = DEFAULT_DATE_FORMAT;
    NSDateFormatter *fcDateFormat = [[NSDateFormatter alloc]init];
    fcDateFormat.dateFormat = @"dd.M.yyyy";
    NSDate *birthdate = [fcDateFormat dateFromString:birthdateString];
    birthdateString = birthdate ? [defaultDateFormat stringFromDate:birthdate] : nil;

    NSString *imgURL;
    NSString *urlString = [vkUserDict objectForKey:@"photo_max"];
    if (urlString && ![urlString containsString:@"camera"]) {
        imgURL = urlString;
    }
    
    User *user = [[User alloc] init];
    user.pass = pass;
    user.name = firstName;
    user.lastName = lastName;
    user.sex = sexInt;
    user.date = birthdateString;
    user.photo = imgURL;
    
    user.email = emailString;
    user.social = @{SOCIAL_NETWORK_ID[VK] : userID};
    user.phones = phones;
    
    return user;
}


@end
