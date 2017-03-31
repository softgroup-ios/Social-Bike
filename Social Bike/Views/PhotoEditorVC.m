//
//  CropVC.m
//  Social Bike
//
//  Created by Max Ostapchuk on 2/14/17.
//  Copyright © 2017 sasha. All rights reserved.
//


#import "PhotoEditorVC.h"



@interface PhotoEditorVC () <UINavigationControllerDelegate,TOCropViewControllerDelegate>

@property (nonatomic, assign) TOCropViewCroppingStyle croppingStyle;
@property (nonatomic, strong) UIImageView *imageView;   // The image view to present the cropped image

//The cropping style
@property (nonatomic, assign) CGRect croppedFrame;
@property (nonatomic, assign) NSInteger angle;

@property(assign,nonatomic) BOOL photoIsCropped;

- (void)layoutImageView;

- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(TOCropViewController *)cropViewController;

@end

@implementation PhotoEditorVC


#pragma mark - Cropper Delegate


- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    
    self.croppedFrame = cropRect;
    self.angle = angle;
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}


- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(TOCropViewController *)cropViewController
{
    self.imageView.image = image;
    [self layoutImageView];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    if (cropViewController.croppingStyle != TOCropViewCroppingStyleCircular) {
        self.imageView.hidden = YES;
        [cropViewController dismissAnimatedFromParentViewController:self
                                                   withCroppedImage:image
                                                             toView:self.imageView
                                                            toFrame:CGRectZero
                                                              setup:^{ [self layoutImageView]; }
                                                         completion:
         ^{
             self.imageView.hidden = NO;
         }];
    }
    else {
        self.imageView.hidden = NO;
        [cropViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    [_delegate updatePhoto:image];
}



#pragma mark - Image Layout -

- (void)layoutImageView
{
    if (self.imageView.image == nil)
        return;
    
    CGFloat padding = 60.0f;
    
    CGRect viewFrame = self.view.bounds;
    viewFrame.size.width -= (padding * 2.0f);
    viewFrame.size.height -= ((padding * 2.0f));
    
    CGRect imageFrame = CGRectZero;
    imageFrame.size = self.imageView.image.size;
    
    if (self.imageView.image.size.width > viewFrame.size.width ||
        self.imageView.image.size.height > viewFrame.size.height)
    {
        CGFloat scale = MIN(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height);
        imageFrame.size.width *= scale;
        imageFrame.size.height *= scale;
        imageFrame.origin.x = (CGRectGetWidth(self.view.bounds) - imageFrame.size.width) * 0.5f;
        imageFrame.origin.y = (CGRectGetHeight(self.view.bounds) - imageFrame.size.height) * 0.5f;
        self.imageView.frame = imageFrame;
    }
    else {
        self.imageView.frame = imageFrame;
        self.imageView.center = (CGPoint){CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)};
    }
}

#pragma mark - View Creation/Lifecycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Photo Edit";
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:_profileImage];
    cropViewController.delegate = self;
    [cropViewController setAspectRatioPreset:TOCropViewControllerAspectRatioPresetSquare animated:YES];
    [cropViewController setAspectRatioLockEnabled:YES];
    [cropViewController setAspectRatioPickerButtonHidden:YES];
    [cropViewController setResetAspectRatioEnabled:NO];
    [self presentViewController:cropViewController animated:YES completion:nil];
}

- (void)viewDidLayoutSubviews
{
    self.photoIsCropped = YES;
    [super viewDidLayoutSubviews];
    [self layoutImageView];
}

-(void)viewWillAppear:(BOOL)animated{
    if(self.photoIsCropped){
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
