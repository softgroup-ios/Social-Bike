//
//  ChatPhotoEditVC.m
//  Social Bike
//
//  Created by Max Ostapchuk on 2/21/17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "ChatPhotoEditVC.h"
#import "PhotoEditorVC.h"

@interface ChatPhotoEditVC () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *chatPhotoImageView;

@end

@implementation ChatPhotoEditVC

- (void)viewDidLoad {
    
    [super viewDidLoad];

    _chatPhotoImageView.image = _chatImage;
    _chatPhotoImageView.contentMode = UIViewContentModeScaleAspectFit;
}

# pragma mark - PhotoEditor Delegate

-(void)updatePhoto:(UIImage*)updatePhoto{
    
    self.chatPhotoImageView.image = updatePhoto;
    [_chat setPhoto:updatePhoto];
}


#pragma mark - ImagePicker Action

- (IBAction)editButtonAction:(id)sender {
    UIAlertController *alertWithChoice = [UIAlertController alertControllerWithTitle:@"Choose Image From:"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *editAction = [UIAlertAction actionWithTitle:@"Edit Current Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        [self performSegueWithIdentifier:@"chatPhotoEdit" sender:nil];
    }];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSourceType:UIImagePickerControllerSourceTypeCamera];
    }];
    UIAlertAction *galleryAction = [UIAlertAction actionWithTitle:@"Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertWithChoice addAction:editAction];
    [alertWithChoice addAction:cameraAction];
    [alertWithChoice addAction:galleryAction];
    [alertWithChoice addAction:cancelAction];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alertWithChoice animated:YES completion:nil];
    }
    else {
        alertWithChoice.modalPresentationStyle = UIModalPresentationPopover;
        alertWithChoice.popoverPresentationController.sourceView = _chatPhotoImageView;
        alertWithChoice.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self presentViewController:alertWithChoice animated:YES completion:nil];
    }
}

- (void)showSourceType: (UIImagePickerControllerSourceType) sourceType {
    if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    self.chatImage = image;
    
    [self performSegueWithIdentifier:@"chatPhotoEdit" sender:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"chatPhotoEdit"]) {
           PhotoEditorVC *photoCropVC = segue.destinationViewController;
           photoCropVC.profileImage = _chatImage;
           photoCropVC.delegate=self;
    }
}

@end
