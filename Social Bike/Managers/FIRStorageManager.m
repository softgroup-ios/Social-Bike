//
//  FIRStorageManager.m
//  Social Bike
//
//  Created by sxsasha on 16.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "FIRStorageManager.h"
#import <Firebase/Firebase.h>
#import "FIRServerManager.h"

#import "constants.h"


@interface FIRStorageManager ()
@property (strong, nonatomic) FIRStorageReference *imagesPathRef;
@property (strong, nonatomic) FIRStorageReference *profileImgRef;
@end




@implementation FIRStorageManager

+(FIRStorageManager*) sharedManager {
    static FIRStorageManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FIRStorageManager alloc] init];
    });
    
    return  manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initStorageReference];
    }
    return self;
}

- (void)initStorageReference {
    
    NSString *path = [[NSBundle mainBundle] pathForResource: @"GoogleService-Info" ofType: @"plist"];
    NSDictionary *googlePlist =[[NSDictionary alloc] initWithContentsOfFile:path];
    NSString *firstStorageBucket = [NSString stringWithFormat:@"gs://%@",[googlePlist objectForKey:@"STORAGE_BUCKET"]];
    
    FIRStorage *storage = [FIRStorage storage];
    FIRStorageReference *storageRef = [storage referenceForURL:firstStorageBucket];
    self.imagesPathRef = [storageRef child:ALL_IMAGES];
    self.profileImgRef = [self.imagesPathRef child:ALL_PROFILE_IMAGES];
}


- (void)loadMediaMessage: (NSString*) imageName
             successBlock:(void (^)(UIImage* image))successBlock {
    
    FIRStorageReference *photoRef = [self.imagesPathRef child:imageName];
    
    
    [photoRef metadataWithCompletion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
        [photoRef dataWithMaxSize:metadata.size completion:^(NSData *data, NSError *error){
            if (!error && data) {
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(image);
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(nil);
                });
            }
        }];
    }];
}


- (void)saveMediaMessage: (UIImage*)photo
                 withName: (NSString*)name
             successBlock:(void (^)(BOOL status))successBlock{
    
    FIRStorageReference *imagesRef = [self.imagesPathRef child:name];
    
    NSData *imageData = UIImageJPEGRepresentation(photo, 0.5f);
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc]init];
    metadata.contentType = @"image/jpeg";
    
    [imagesRef putData:imageData
              metadata:metadata
            completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                
                if (!successBlock) {
                    return;
                }
                
                if (!error) {
                    successBlock(YES);
                }
                else {
                    successBlock(NO);
                }
            }];
}

- (void)saveProfileImage:(UIImage*)image
                withName:(NSString*)name
            successBlock:(void (^)(BOOL status, NSError *error))successBlock {
    
    FIRStorageReference *imagesRef = [self.profileImgRef child:name];
    
    NSData *imageData = UIImagePNGRepresentation(image);
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc]init];
    metadata.contentType = @"image/png";
    
    [imagesRef putData:imageData
              metadata:metadata
            completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                if (!error) {
                    successBlock(YES,error);
                }
                else {
                    successBlock(NO,error);
                }
            }];
}

- (void)loadProfileImage:(NSString*)imageName
            successBlock:(void (^)(UIImage* image))successBlock {
    
    FIRStorageReference *photoRef = [self.profileImgRef child:imageName];
    [photoRef metadataWithCompletion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
        if (!metadata || error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(nil);
            });
        }
        [photoRef dataWithMaxSize:metadata.size completion:^(NSData *data, NSError *error){
            if (!error && data) {
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(image);
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successBlock(nil);
                });
            }
        }];
    }];
}

- (void)deleteImage: (NSString*)name
        successBlock:(void (^)(BOOL status))successBlock {
    
    FIRStorageReference *imagesRef = [self.imagesPathRef child:name];
    [imagesRef deleteWithCompletion:^(NSError * _Nullable error) {
        
        if (!successBlock) {
            return;
        }
        if (!error) {
            successBlock(YES);
        }
        else {
            successBlock(NO);
        }
    }];
}

@end
