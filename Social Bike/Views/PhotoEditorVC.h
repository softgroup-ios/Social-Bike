//
//  PhotoEditorVC.h
//  Social Bike
//
//  Created by Max Ostapchuk on 2/14/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TOCropViewController/TOCropViewController.h>

@protocol sendDataProtocol <NSObject>

-(void)updatePhoto:(UIImage*)updatePhoto;

@end

@interface PhotoEditorVC : UIViewController

@property (nonatomic, strong) UIImage *profileImage;
@property(nonatomic,assign)id delegate;

@end

