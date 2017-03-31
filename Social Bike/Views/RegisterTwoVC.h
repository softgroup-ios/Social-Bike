//
//  RegisterTwoVC.h
//  Social Bike
//
//  Created by Anton Hrabovskyi on 24.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@protocol NavigationToNextPart <NSObject>

- (void)receiveUserModel:(User*)userModel;
@end


@interface RegisterTwoVC : UIViewController <NavigationToNextPart>

@end
