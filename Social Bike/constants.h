//
//  constants.h
//  Social Bike
//
//  Created by sxsasha on 30.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#ifndef constants_h
#define constants_h


//@interface Singleton : NSObject
//
//+ (UIColor*)main_theme_color;
//
//@end
//
//
//
//@implementation Singleton
//
//+ (UIColor*)main_theme_color {
//    static UIColor *main_theme_color;
//    if (!main_theme_color) {
//        main_theme_color = MAIN_THEME_COLOR;
//    }
//    return main_theme_color;
//}
//
//- (void)test {
//
//    [Singleton main_theme_color];
//}
//
//@end


#define baseServerURL @"http://192.168.11.150:8443" //not used

#define SOCIAL_NETWORK_ID @[@"GP", @"FB", @"VK", @"SKYPE"]
#define USER_POSITION @[@"Administrator", @"Manager", @"Developer", @"Sale", @"HR", @"User", @"SA"]
#define DEFAULT_DATE_FORMAT @"yyyy-MM-dd"
#define CHAT_DATE_FORMAT @"dd.MM.yyyy HH:mm:ss"
#define BIRTHDAY_DATE_FORMAT @"d MMMM yyyy"
#define GENDER @[@"male", @"female"]
#define IDENTIFICATE_PHONE @"Additional phone"
#define IDENTIFICATE_MAIN_EMAIL @"Main e-mail"
#define IDENTIFICATE_ADD_EMAIL @"Additional e-mail"

#define ALL_USERS @"users"
#define ALL_CHATS_INFO @"chats_info"
#define ALL_CHATS @"chats_source"
#define ANONIM_USER_NAME @"anonim"
#define ANONIM_USER_ID @"-1"
#define ALL_IMAGES @"images"
#define ALL_PROFILE_IMAGES @"profile"

// COLOR DATA
#define UIColorFromRGB(rgbValue) \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                    green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                     blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                    alpha:1.0]

#define DARKER_GREY_COLOR UIColorFromRGB(0x5C5C5C)
#define GREY_THEME_COLOR  UIColorFromRGB(0xDEDEDE)
#define MAIN_THEME_COLOR  UIColorFromRGB(0x6EB111)
#define BACKGROUND_COLOR  UIColorFromRGB(0xFFFFFF)
#define WARNING_COLOR     UIColorFromRGB(0xFF1328)
#define TEST_COLOR        UIColorFromRGB(0xABD86D)
#define GREY_BACKGROUND_COLOR UIColorFromRGB(0xEFEFF4)

typedef enum
{
   GP,
   FB,
   VK,
   SKYPE
}SocialNetworkID;





#endif /* constants_h */
