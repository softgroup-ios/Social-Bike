//
//  FIRStorageManager.h
//  Social Bike
//
//  Created by sxsasha on 16.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>



@class UIImage;

@interface FIRStorageManager : NSObject

+(FIRStorageManager*) sharedManager;

- (void)loadMediaMessage: (NSString*) imageName
             successBlock:(void (^)(UIImage* image))successBlock;

- (void)saveMediaMessage: (UIImage*)photo
                 withName: (NSString*)name
             successBlock:(void (^)(BOOL))successBlock;

//- (void)deleteImage: (NSString*)name
//        successBlock:(void (^)(BOOL status))successBlock;

//- (void)saveProfileImage:(UIImage*)image
//                withName:(NSString*)name
//            successBlock:(void (^)(BOOL status, NSError *error))successBlock;

//- (void)loadProfileImage:(NSString*)imageName
//            successBlock:(void (^)(UIImage* image))successBlock;


@end
