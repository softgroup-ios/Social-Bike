//
//  FacebookManager.h
//  Social Bike
//
//  Created by sxsasha on 24.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SocialAuthenticationModel;

typedef void (^SuccessLoginFB)(BOOL status, NSError* error);


@interface FacebookManager : NSObject

+(FacebookManager*) sharedManager;
- (void)loginToFacebook :(SuccessLoginFB) successBlock;

@end
