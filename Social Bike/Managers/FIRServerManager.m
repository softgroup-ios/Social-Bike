//
//  FIRServerManager.m
//  Social Bike
//
//  Created by sxsasha on 3/23/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "FIRServerManager.h"
#import "Reachability.h"
#import "User.h"
#import "constants.h"

@import FirebaseAuth;
@import FirebaseDatabase;

@interface FIRServerManager ()
@property (nonatomic, strong) Reachability *internetRech;
@property (nonatomic, strong) FIRDatabaseReference *mainRef;
@property (nonatomic, strong) FIRDatabaseReference *usersRef;
@end

@implementation FIRServerManager

+(FIRServerManager*)sharedManager {
    static FIRServerManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FIRServerManager alloc]init];
        manager.internetRech =  [Reachability reachabilityWithHostname:@"https://console.firebase.google.com"];
        manager.mainRef = [[FIRDatabase database] reference];
        manager.usersRef = [manager.mainRef child:ALL_USERS];
    });
    
    return  manager;
}

#pragma mark - check Internet Avilability

- (NSError*) isInternetAvalible {
    NSError *error;
    if (!self.internetRech.isReachable) {
        error = [NSError errorWithDomain:@"No Internet connection" code:1 userInfo:nil];
    }
    return error;
}

- (void)setStatusTo:(BOOL)status {
    NSString *myID = [[FIRServerManager sharedManager] getMyId];
    if (myID) {
        NSString *pathToUsersStatus = [NSString stringWithFormat:@"users/%@/online/",myID];
        FIRDatabaseReference *usersStatusRef = [[FIRDatabase database] referenceWithPath:pathToUsersStatus];
        if (status) {
            [usersStatusRef setValue:@(YES)];
        } else {
            [usersStatusRef removeValue];
        }
    }
}

#pragma mark - Requests to FIRAuth

- (void)authenticationWithLogin:(NSString*)login
                       password:(NSString*)password
                   successBlock: (SuccessAuthBlock) successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(NO,error);
        return;
    }
    
    [[FIRAuth auth] signInWithEmail:login password:password completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (user && !error) {
            [self setStatusTo:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(YES, nil);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO,error);
            });
        }
    }];
}

- (void)registrationUser:(User*)user
            successBlock:(SuccessAuthBlock) successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(NO,error);
        return;
    }
    
    [[FIRAuth auth] createUserWithEmail:user.email password:user.pass completion:^(FIRUser * _Nullable firUser, NSError * _Nullable error) {
        if (firUser && !error) {
            user.uid = firUser.uid;
            [self createNewUser:user successBlock:^(BOOL status, NSError *error) {
                [self updateDisplayName:user.displayName forUser:firUser];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setStatusTo:YES];
                    successBlock(YES,error);
                });
            }];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO,error);
            });
        }
    }];
}

- (void)socialAuthWithCredential:(FIRAuthCredential*)credential
                    successBlock:(SuccessAuthBlock)successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(NO,error);
        return;
    }
    
    [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (user && !error) {
            
            FIRDatabaseReference *userRef = [self.usersRef child:user.uid];
            [userRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                if (snapshot.hasChildren) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setStatusTo:YES];
                        successBlock(YES, nil);
                    });
                }
                else {
                    [[FIRAuth auth] signOut:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(NO, error);
                    });
                }
            }];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO,error);
            });
        }
    }];
}

- (void)sociaRegistrationUser:(User*)user
               withCredential:(FIRAuthCredential*)credential
                 successBlock:(SuccessAuthBlock) successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(NO,error);
        return;
    }
    
    [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser * _Nullable firUser, NSError * _Nullable error) {
        if (firUser && !error) {
            user.uid = firUser.uid;
            [self createNewUser:user successBlock:^(BOOL status, NSError *error) {
                [self updateDisplayName:user.displayName forUser:firUser];
                [self setStatusTo:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(YES,error);
                });
            }];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO,error);
            });
        }
    }];
}

#pragma mark - Requests to FIRDatabase

- (void)getAllUsersWithSuccessBlock:(SuccessUsers)successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(nil,error);
        return;
    }
    
    [self.usersRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSArray *users = [self getUsersFromSnapshot:snapshot];
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(users, nil);
        });
    }];
}

- (void)getUserWithID:(NSString*)userID successBlock:(SuccessUser)successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(nil,error);
        return;
    }
    
    FIRDatabaseReference *userRef = [self.usersRef child:userID];
    [userRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSError *error;
        User *user = [[User alloc] initWithDictionary:snapshot.value error:&error];
        user.uid = userID;
        
        if (!error && user) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(user,nil);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(nil, error);
            });
        }
    }];
}

- (void)getUsersWithIDs:(NSArray <NSString*> *)userIDs successBlock:(SuccessUsers)successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(nil,error);
        return;
    }
    
    [self.usersRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSError *error;
        NSDictionary *usersDict = snapshot.value;
        NSMutableArray *users = [NSMutableArray array];
        for (NSString *userID in userIDs) {
            User *user = [[User alloc] initWithDictionary:[usersDict objectForKey:userID] error:&error];
            user.uid = userID;
            if (user && !error) {
                [users addObject:user];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(users,nil);
        });
    }];
}

- (void)getUserWithProperty:(NSString*)property andValue:(id)value successBlock:(SuccessUsers)successBlock {
    
    NSError *error = [self isInternetAvalible];
    if (error) {
        successBlock(nil,error);
        return;
    }
    
    [[[self.usersRef queryOrderedByChild:property] queryEqualToValue:value] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSArray *users = [self getUsersFromSnapshot:snapshot];
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(users, nil);
        });
    }];
}

- (void)getMyProfileWithSuccessBlock:(SuccessUser)successBlock {
    NSString *myUID = [FIRAuth auth].currentUser.uid;
    [self getUserWithID:myUID successBlock:successBlock];
}

#pragma mark - Help methods work with FIRDatabase

- (NSArray <User*> *)getUsersFromSnapshot:(FIRDataSnapshot*)snapshot {
    NSError *error;
    NSMutableArray *users = [NSMutableArray array];
    for (FIRDataSnapshot* childSnapshot in snapshot.children) {
        User *user = [[User alloc] initWithDictionary:childSnapshot.value error:&error];
        user.uid = childSnapshot.key;
        if (!error && ![user.uid isEqualToString:[self getMyId]]) {
            [users addObject:user];
        }
    }
    return users;
}

- (void)updateDisplayName:(NSString*)displayName forUser:(FIRUser*)firUser {
    FIRUserProfileChangeRequest *changeRequest = [firUser profileChangeRequest];
    changeRequest.displayName = displayName;
    [changeRequest commitChangesWithCompletion:nil];
}

#pragma mark - Update FIRDatabase

-(void)createNewUser:(User*)user
        successBlock:(SuccessAuthBlock)successBlock {
    
    NSDictionary *dict = user.toDictionary;
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/%@/",user.uid]: dict};
    
    [self.usersRef updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (!error) {
            successBlock(YES,error);
        }
        else {
            successBlock(NO,error);
        }
    }];
}

- (void)editProfile:(User*)user
       successBlock:(SuccessAuthBlock)successBlock {
    
    NSString *myUID = [FIRAuth auth].currentUser.uid;
    NSDictionary *dict = user.toDictionary;
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/%@/",myUID]: dict};
    
    [self.usersRef updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (!error) {
            [self updateDisplayName:user.displayName forUser:[FIRAuth auth].currentUser];
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(YES,error);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO,error);
            });
        }
    }];
}

- (void)deleteProfileWithSuccessBlock:(SuccessAuthBlock)successBlock {
    
    FIRUser *user = [FIRAuth auth].currentUser;
    NSString *myUID = [FIRAuth auth].currentUser.uid;
    
    [[self.usersRef child:myUID] removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (!error) {
            [user deleteWithCompletion:^(NSError * _Nullable error) {
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(YES, error);
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(NO, error);
                    });
                }
            }];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO, error);
            });
        }
    }];
}

- (void)changePassword:(NSString*)password withSuccessBlock:(SuccessAuthBlock)successBlock {
    [[FIRAuth auth].currentUser updatePassword:password completion:^(NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(YES, error);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO, error);
            });
        }
    }];
}

- (void)changeEmail:(NSString*)email withSuccessBlock:(SuccessAuthBlock)successBlock {
    [[FIRAuth auth].currentUser updateEmail:email completion:^(NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(YES, error);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(NO, error);
            });
        }
    }];
}


- (void)saveProfilePhoto:(UIImage*)image successBlock:(CompletionUploadBlock)successBlock {
    
    NSString *myUID = [FIRAuth auth].currentUser.uid;
    [[CloudinaryManager sharedManager] uploadImage:image withName:myUID completionBlock:^(NSString *url, NSError *error) {
        if (url && !error) {
            [self setPhotoURL:url];
        }
        successBlock(url, error);
    }];
}

- (void)setPhotoURL:(NSString*)url {
    NSString *myUID = [FIRAuth auth].currentUser.uid;
    [[[self.usersRef child:myUID] child:@"photo"] setValue:url];
}


- (void)loadProfilePhotoForUser:(User*)user successBlock:(SuccessProfilePhoto)successBlock {
    if (!user.photo) {
        successBlock(nil);
    }
    else {
        [[CloudinaryManager sharedManager] downloadImage:user.photo completionBlock:successBlock];
    }
}

- (BOOL)isAuth {
    return [FIRAuth auth].currentUser &&  [FIRAuth auth].currentUser.uid && [FIRAuth auth].currentUser.displayName ? YES : NO;
}

- (NSString*)getMyId{
    return [FIRAuth auth].currentUser.uid;
}

- (NSString*)getMyName{
    return [FIRAuth auth].currentUser.displayName;
}

#pragma mark - Resize image method

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)toSize {
    
    CGFloat imageScale = image.size.height/image.size.width;
    CGFloat toSizeScale = toSize.height/toSize.width;
    
    CGSize newSize = toSize;
    if (imageScale != toSizeScale) {
        if (toSize.height > toSize.width) {
            newSize = CGSizeMake(toSize.height / imageScale, toSize.height);
        }
        else {
            newSize = CGSizeMake(toSize.width, toSize.width * imageScale);
        }
    }
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


@end
