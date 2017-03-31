//
//  VKManager.h
//  Social Bike
//
//  Created by sxsasha on 07.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VKSdk.h>

typedef void (^SuccessLoginVK)(BOOL status,NSError *error);


@interface VKManager : NSObject <VKSdkDelegate>

+(VKManager*) sharedManager;

@property (nonatomic, strong) VKSdk *sdkInstance;
@property (nonatomic, copy) SuccessLoginVK successBlock;

@end
