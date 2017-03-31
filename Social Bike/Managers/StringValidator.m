//
//  StringValidator.m
//  Social Bike
//
//  Created by Anton Hrabovskyi on 31.01.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "StringValidator.h"

@implementation StringValidator

+ (BOOL)emailValidation:(NSString*)email {

    NSArray<NSString*> *emailParts = [email componentsSeparatedByString:@"@"];
    return emailParts.count == 2 && [emailParts objectAtIndex:0].length > 2 && [emailParts objectAtIndex:1].length >= 2;
}

+ (BOOL)passwordValidation:(NSString*)password {
    
    return password.length >= 6;
}

+ (BOOL)nameValidation:(NSString*)name {
    
    return name.length >= 2 && name.length <= 10;
}

+ (BOOL)phoneValidator:(NSString *)phoneNumber
{
    if (phoneNumber == nil || ([phoneNumber length] < 2 ) )
        return NO;
    
    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    NSArray *matches = [detector matchesInString:phoneNumber options:0 range:NSMakeRange(0, [phoneNumber length])];
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypePhoneNumber) {
            NSString *phoneNumber = [match phoneNumber];
            if ([phoneNumber isEqualToString:phoneNumber]) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSString*) checkPhoneNumberWithNewString: (NSString*) decimalString
{
    NSCharacterSet* validationSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray* stringArray  = [decimalString componentsSeparatedByCharactersInSet:validationSet];
    decimalString = [stringArray componentsJoinedByString:@""];
    // +XX (XXX) XXX-XXXX
    
    static const int mainNumberLength = 7;
    static const int localAreaCodeLength = 3;
    static const int countryCodeLength = 3;
    
    NSInteger currentNumberLength = [decimalString length];
    NSInteger maxNumber = mainNumberLength + localAreaCodeLength + countryCodeLength;
    
    NSString* newString;
    if (currentNumberLength > maxNumber)
    {
        newString = [decimalString substringToIndex:maxNumber];
        currentNumberLength = [newString length];
    }
    else {
        newString = decimalString;
    }
    
    if (currentNumberLength > 3)
    {
        NSInteger currentMainNumber = MIN(currentNumberLength, mainNumberLength);
        NSRange firstMainRange = NSMakeRange(currentNumberLength - (currentMainNumber - 3) , 0);
        newString = [newString stringByReplacingCharactersInRange:firstMainRange withString:@"-"];
    }
    
    if (currentNumberLength > mainNumberLength)
    {
        NSInteger currentLocalAreaNumber = MIN(currentNumberLength-mainNumberLength,localAreaCodeLength);
        NSRange localAreaRange = NSMakeRange(currentNumberLength - mainNumberLength - currentLocalAreaNumber, currentLocalAreaNumber);
        NSString* localAreaCode = [newString substringWithRange:localAreaRange];
        newString = [newString stringByReplacingCharactersInRange:localAreaRange withString:[NSString stringWithFormat:@"(%@) ",localAreaCode]];
    }
    
    if (currentNumberLength > mainNumberLength + localAreaCodeLength)
    {
        NSInteger currentCountryCode = MIN(currentNumberLength-mainNumberLength - localAreaCodeLength,countryCodeLength);
        NSRange countryCodeRange = NSMakeRange(currentNumberLength - mainNumberLength - 3 - currentCountryCode, currentCountryCode);
        NSString* countryCode = [newString substringWithRange:countryCodeRange];
        newString = [newString stringByReplacingCharactersInRange:countryCodeRange withString:[NSString stringWithFormat:@"+%@ ",countryCode]];
    }
    
    return newString;
}


@end
