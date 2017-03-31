//
//  FIRServerManager.h
//  Social Bike
//
//  Created by sxsasha on 3/23/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CloudinaryManager.h"
#import <UIKit/UIKit.h>

@class User, FIRAuthCredential, UIImage;

typedef void (^SuccessAuthBlock)(BOOL status, NSError *error);
typedef void (^SuccessUser)(User* user, NSError* error);
typedef void (^SuccessUsers)(NSArray<User*>* users, NSError* error);
typedef void (^SuccessProfilePhoto)(UIImage* image);

@interface FIRServerManager : NSObject

+(FIRServerManager*)sharedManager;

- (void)authenticationWithLogin:(NSString*)login password:(NSString*)password successBlock:(SuccessAuthBlock)successBlock;
- (void)registrationUser:(User*)user successBlock:(SuccessAuthBlock)successBlock;
- (void)socialAuthWithCredential:(FIRAuthCredential*)credential successBlock:(SuccessAuthBlock)successBlock;
- (void)sociaRegistrationUser:(User*)user withCredential:(FIRAuthCredential*)credential successBlock:(SuccessAuthBlock)successBlock;

- (void)getAllUsersWithSuccessBlock:(SuccessUsers)successBlock;
- (void)getUserWithProperty:(NSString*)property andValue:(id)value successBlock:(SuccessUsers)successBlock;
- (void)getUserWithID:(NSString*)userID successBlock:(SuccessUser)successBlock;
- (void)getUsersWithIDs:(NSArray <NSString*> *)userIDs successBlock:(SuccessUsers)successBlock;
- (void)editProfile:(User*)user successBlock:(SuccessAuthBlock)successBlock;
- (void)getMyProfileWithSuccessBlock:(SuccessUser)successBlock;
- (void)saveProfilePhoto:(UIImage*)image successBlock:(CompletionUploadBlock)successBlock;
- (void)loadProfilePhotoForUser:(User*)user successBlock:(SuccessProfilePhoto)successBlock;
- (void)setPhotoURL:(NSString*)url;

- (void)changeEmail:(NSString*)email withSuccessBlock:(SuccessAuthBlock)successBlock;
- (void)changePassword:(NSString*)password withSuccessBlock:(SuccessAuthBlock)successBlock;
- (void)deleteProfileWithSuccessBlock:(SuccessAuthBlock)successBlock;

- (NSString*)getMyId;
- (NSString*)getMyName;
- (BOOL)isAuth;

//rescale image
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)toSize;

@end
