//
//  AsyncPhotoMediaItem.m
//  Social Bike
//
//  Created by sxsasha on 14.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "AsyncPhotoMediaItem.h"
#import "CloudinaryManager.h"


#import <JSQMessagesViewController/JSQMessagesMediaPlaceholderView.h>
#import "UIColor+JSQMessages.h"


@implementation JSQMessagesMediaPlaceholderView (ActivityIndicator)

+ (instancetype)viewWithAlwaysActivityIndicator {
    UIColor *lightGrayColor = [UIColor jsq_messageBubbleLightGrayColor];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.color = [lightGrayColor jsq_colorByDarkeningColorWithValue:0.4f];
    spinner.hidesWhenStopped = NO;
    
    JSQMessagesMediaPlaceholderView *view = [[JSQMessagesMediaPlaceholderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 120.0f)
                                                                                   backgroundColor:lightGrayColor
                                                                             activityIndicatorView:spinner];
    return view;
}

@end


@implementation AsyncPhotoMediaItem

- (instancetype)init
{
    return [self initWithMaskAsOutgoing:YES];
}

- (instancetype)initWithURL:(NSString*)photoURL {
    self = [super init];
    if (self) {
        CGSize size = [self mediaViewDisplaySize];
        
        self.asyncImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        self.asyncImageView.contentMode = UIViewContentModeScaleToFill;
        self.asyncImageView.clipsToBounds = YES;
        self.asyncImageView.layer.cornerRadius = 20;
        self.asyncImageView.backgroundColor = [UIColor jsq_messageBubbleLightGrayColor];
        
        UIView *activityIndicator = [JSQMessagesMediaPlaceholderView viewWithAlwaysActivityIndicator];
        activityIndicator.frame = self.asyncImageView.frame;
        
        [self.asyncImageView addSubview:activityIndicator];
        
        __weak AsyncPhotoMediaItem *selfWeak = self;
        __weak UIView *weakActivityIndicator = activityIndicator;
        [[CloudinaryManager sharedManager] downloadImage:photoURL completionBlock:^(UIImage *image) {
            if (image) {
                [selfWeak.asyncImageView setImage:image];
                [weakActivityIndicator removeFromSuperview];
            }
        }];
    }
    return self;
}

#pragma mark - JSQMessageMediaData protocol
- (UIView *)mediaView {
    return self.asyncImageView;
}


@end
