//
//  GoogleManager.h
//  Social Bike
//
//  Created by sxsasha on 06.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Google/SignIn.h>

typedef void (^SuccessLoginGP)(BOOL status, NSError* error);





@interface GoogleManager : NSObject <GIDSignInDelegate>

@property (nonatomic, copy) SuccessLoginGP successBlock;
+(GoogleManager*) sharedManager;

@end
