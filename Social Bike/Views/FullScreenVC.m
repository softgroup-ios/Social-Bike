//
//  FullScreenVC.m
//  BreedFinder
//
//  Created by sxsasha on 23.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "FullScreenVC.h"

@interface FullScreenVC () <UINavigationControllerDelegate,UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageConstraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageConstraintRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageConstraintLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageConstraintBottom;

@property (assign, nonatomic) CGFloat lastZoomScale;
@property (assign, nonatomic) BOOL hideStatusBar;

@end

@implementation FullScreenVC


+ (UINavigationController*)returnFromStorybord {

    NSString *className =  NSStringFromClass([self class]);
    UIStoryboard *storybord = [UIStoryboard storyboardWithName:className bundle:nil];
    UINavigationController *nav = [storybord instantiateInitialViewController];
    
    return nav; // nav.viewControllers.firstObject;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.navigationController.delegate = self;
    self.lastZoomScale = -1;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupTitle:self.name];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.hidesBarsOnTap = YES;
    [self.navigationController.barHideOnTapGestureRecognizer addTarget:self action:@selector(tapAction:)];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipe];
    
    self.imageView.image = self.image;
    self.scrollView.delegate = self;
    [self updateZoomAnimate:NO];
    [self updateConstraintsWithAnimate:NO];
}

- (void) setFullSizeImage:(UIImage *)image {
    _image = image;
    self.imageView.image = image;
    [self updateZoomAnimate:YES];
    [self updateConstraintsWithAnimate:YES];
}

- (void) setupTitle: (NSString*)text {
    
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    titleLabel.text = text;
    titleLabel.font = [UIFont fontWithName:@"Kailasa" size:18.f];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.numberOfLines = 1;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = titleLabel;
}

#pragma mark - Status Bar hidden

- (BOOL)prefersStatusBarHidden {
    return self.hideStatusBar;
}

#pragma mark - Zoom Image

- (void)updateZoomAnimate:(BOOL)animate {
    if (self.image) {
        CGFloat viewWidth = self.scrollView.bounds.size.width;
        CGFloat viewHeight = self.scrollView.bounds.size.height;
        CGFloat minZoom = MIN(viewWidth / self.image.size.width, viewHeight / self.image.size.height);
        //if (minZoom > 1) { minZoom = 1; }
        
        if (minZoom > 3.f) {
            self.scrollView.maximumZoomScale = minZoom;
        }
        self.scrollView.minimumZoomScale = minZoom;
        
        if (minZoom == self.lastZoomScale) { minZoom += 0.000001;}
        
        [self.scrollView setZoomScale:minZoom animated:animate];
        self.lastZoomScale = minZoom;
    }
}

- (void)updateZoomPreload {
    if (self.image) {
        CGFloat viewWidth = [UIApplication sharedApplication].keyWindow.bounds.size.width; //self.scrollView.bounds.size.width
        CGFloat viewHeight = [UIApplication sharedApplication].keyWindow.bounds.size.height; //self.scrollView.bounds.size.height
        CGFloat minZoom = MIN(viewWidth / self.image.size.width, viewHeight / self.image.size.height);
        //if (minZoom > 1) { minZoom = 1; }
        
        if (minZoom > 3.f) {
            self.scrollView.maximumZoomScale = minZoom;
        }
        self.scrollView.minimumZoomScale = minZoom;
        
        if (minZoom == self.lastZoomScale) { minZoom += 0.000001;}
        
        [self.scrollView setZoomScale:minZoom animated:NO];
        self.lastZoomScale = minZoom;
    }
}

- (void) updateConstraintsWithAnimate: (BOOL)animate {
    
    if (self.image) {
        CGFloat imageWidth = self.image.size.width;
        CGFloat imageHeight = self.image.size.height;
        CGFloat viewWidth = self.scrollView.bounds.size.width;
        CGFloat viewHeight = self.scrollView.bounds.size.height;
        
        CGFloat hPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
        if (hPadding < 0) { hPadding = 0;}
        
        CGFloat vPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
        if (vPadding < 0) { vPadding = 0;}
        
        self.imageConstraintLeft.constant = hPadding;
        self.imageConstraintRight.constant = hPadding;
        
        self.imageConstraintTop.constant = vPadding;
        self.imageConstraintBottom.constant = vPadding;
        
        if (animate) {
            [UIView animateWithDuration:0.25 animations:^{
                [self.view layoutIfNeeded];
            }];
        } else {
            [self.view layoutIfNeeded];
        }
    }
}

#pragma mark - Landscape mode

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateZoomAnimate:YES];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    return [self supportedInterfaceOrientations];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView NS_AVAILABLE_IOS(3_2) {
    [self updateConstraintsWithAnimate:NO];
}


#pragma mark - Actions

- (void) tapAction: (UITapGestureRecognizer*)sender {
    BOOL shouldHideStatusBar = self.navigationController.navigationBar.frame.origin.y < 0;
    self.hideStatusBar = shouldHideStatusBar;
    
    [UIView animateWithDuration:0.2 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateZoomAnimate:YES];
        [self updateConstraintsWithAnimate:YES];
    });
}

- (void) swipeDown: (UITapGestureRecognizer*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) cancelFullImage: (UIBarButtonItem*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) saveToGallery: (UIBarButtonItem*)sender {
    UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:savedWithError:contextInfo:), nil);
}

- (void)image:(UIImage*)image savedWithError:(NSError*)error contextInfo:(void *)contextInfo {
    
    if (error || !image) {
        return;
    }
    
    //Info View
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 150.f, 100.f)];
    view.center = self.view.center;
    view.backgroundColor = [UIColor whiteColor];
    [view setAlpha:0.0f];
    view.layer.cornerRadius = 8.f;
    [self.view addSubview:view];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Saved";
    label.font = [UIFont systemFontOfSize:32.f];
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    [label sizeToFit];
    
    float xpos = (view.frame.size.width/2.0f) - (label.frame.size.width/2.0f);
    float ypos = (view.frame.size.height/2.0f) - (label.frame.size.height/2.0f);
    [label setFrame:CGRectMake(xpos, ypos, label.frame.size.width, label.frame.size.height)];
    [view addSubview:label];
    
    [UIView animateWithDuration:1.3f animations:^{
        [view setAlpha:0.95f];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.6 animations:^{
            [view setAlpha:0.0f];
        }];
    }];
}

@end

