//
//  CloudinaryManager.m
//  Social Bike
//
//  Created by sxsasha on 3/27/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "CloudinaryManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

@interface CloudinaryManager ()
@property (nonatomic, strong) NSString *cloudinaryApiKey;
@property (nonatomic, strong) NSString *cloudinarySecretKey;
@property (nonatomic, strong) NSString *cloudinaryName;
@end

@implementation CloudinaryManager

+ (CloudinaryManager*)sharedManager {
    static CloudinaryManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CloudinaryManager alloc]init];
    });
    
    return  manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cloudinaryApiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CloudinaryApiKey"];
        _cloudinarySecretKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CloudinarySecretKey"];
        _cloudinaryName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CloudinaryName"];
    }
    return self;
}

#pragma mark - Download

- (void)downloadImage:(NSString*)imageURL completionBlock:(CompletionDownloadBlock)completionBlock {
    
    NSURL *url = [NSURL URLWithString:imageURL];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        UIImage *image = [UIImage imageWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image);
        });
    }] resume];
}

#pragma mark - Upload

- (void)uploadImage:(UIImage*)image withName:(NSString*)name completionBlock:(CompletionUploadBlock)completionBlock {
    
    NSString *public_id = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    if (![public_id isEqualToString:name]) {
        return;
    }
    
    NSString *base64 = [self dataURLFrom:image];
    
    NSNumber *timestamp = [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];
    NSString *timestampString = [NSString stringWithFormat:@"%@",timestamp];
    
    NSString *needToCreateSHA1 = [[NSString stringWithFormat:@"public_id=%@&timestamp=%@",public_id,timestampString] stringByAppendingString:self.cloudinarySecretKey];
    NSString *signature = [self sha1FromString:needToCreateSHA1];
    
    NSDictionary *parameter = @{@"timestamp":timestamp,
                                @"public_id":public_id,
                                @"api_key":self.cloudinaryApiKey,
                                @"signature":signature,
                                @"file":base64};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameter
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (jsonData && !error) {
        [self upload:jsonData completionBlock:completionBlock];
    }
}

- (void)upload:(NSData*)body completionBlock:(CompletionUploadBlock)completionBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.cloudinary.com/v1_1/%@/image/upload", self.cloudinaryName];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSError *errorWithDeser;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&errorWithDeser];
        if (!error && data && !errorWithDeser) {
            NSString *url = [jsonResponse objectForKey:@"secure_url"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(url, nil);
            }); 
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, error);
            });
        }
    }] resume];
}

#pragma mark - Upload help methods

- (NSString*)sha1FromString:(NSString*)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (uint32_t)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

- (NSString *)dataURLFrom:(UIImage *)image {
    if(image.size.width > 1280 || image.size.height > 1280) {
        image = [self imageWithImage:image scaledToSize:CGSizeMake(1280, 1280)];
    }
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *mimeType = @"image/jpeg";
    
    return [NSString stringWithFormat:@"data:%@;base64,%@", mimeType, [imageData base64EncodedStringWithOptions:0]];
}

-(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)toSize {
    
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
