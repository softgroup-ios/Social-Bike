//
//  User.h
//  Social Bike
//
//  Created by sxsasha on 3/23/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"

@interface User : JSONModel

typedef enum {
    NOSET,
    MALE,
    FEMALE
}SEX;


@property (nonatomic, strong, nullable) NSString <Optional> *email;
@property (nonatomic, strong, nullable) NSString <Ignore> *pass;
@property (nonatomic, strong, nullable) NSString <Ignore> *uid;

@property (nonatomic, strong, nonnull) NSString <Optional> *name;
@property (nonatomic, strong, nonnull) NSString <Optional> *lastName;
@property (nonatomic, strong, nullable) NSString <Optional> *position; //Administrator Manager Developer Sale HR User SA
@property (nonatomic, strong, nullable) NSString <Optional> *date; //1992-05-14
@property (nonatomic, strong, nullable) NSString <Optional> *photo;
@property (nonatomic, assign) SEX sex;
@property (nonatomic, assign) BOOL online;
@property (nonatomic, strong, nullable) NSArray  <NSString*> <Optional> *phones;
@property (nonatomic, strong, nullable) NSArray  <NSString*> <Optional> *emails;
@property (nonatomic, strong, nullable) NSDictionary  <NSString*,NSString*> <Optional> *social; //VK FB GP

- (nullable NSDate*)birthdate;
- (nullable NSString*)displayName;
@end
