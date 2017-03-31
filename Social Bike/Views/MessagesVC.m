//
//  MessagesVC.m
//  Social Bike
//
//  Created by sxsasha on 07.02.17.
//  Copyright © 2017 sasha. All rights reserved.
//

#import "MessagesVC.h"

#import "NewProfileVC.h"
#import "SWRevealViewController.h"
#import "MessagesData.h"
#import "User.h"
#import "ChatsListVC.h"
#import "ChatManageVC.h"
#import "Chat.h"
#import "FIRServerManager.h"
#import "CloudinaryManager.h"
#import "FullScreenVC.h"
#import "AsyncPhotoMediaItem.h"

#import <SVPullToRefresh/SVPullToRefresh.h>

#import "constants.h"

// Avatar Model
@interface UserAvatar : NSObject <JSQMessageAvatarImageDataSource>
@property (strong, nonatomic) UIImage *avatarImage;
@property (strong, nonatomic) UIImage *avatarHighlightedImage;
@property (strong, nonatomic) UIImage *avatarPlaceholderImage;

// for update when download finished
@property (strong, nonatomic) NSMutableArray *indexPaths;
@property (weak, nonatomic) UICollectionView *collectionView;


@end

@implementation UserAvatar
- (instancetype)initAvatarWithImageURL:(NSString*)imageURL
{
    self = [super init];
    if (self) {
        self.avatarPlaceholderImage = [JSQMessagesAvatarImageFactory circularAvatarImage:[UIImage imageNamed:@"default-avatar"] withDiameter:30];
        self.indexPaths = [NSMutableArray array];
        
        if (!imageURL) {
            return self;
        }
        
        __weak UserAvatar *selfID = self;
        [[CloudinaryManager sharedManager] downloadImage:imageURL completionBlock:^(UIImage *image) {
            if (image) {
                selfID.avatarImage = [JSQMessagesAvatarImageFactory circularAvatarImage:image withDiameter:30];
                selfID.avatarHighlightedImage = [JSQMessagesAvatarImageFactory circularAvatarHighlightedImage:image withDiameter:30];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [selfID.collectionView reloadItemsAtIndexPaths:selfID.indexPaths];
                });
            }
        }];
    }
    return self;
}
@end






@interface MessagesVC () <JSQMessagesCollectionViewDataSource, JSQMessagesCollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, JSQMessagesComposerTextViewPasteDelegate, UpdateChatDelegate>

@property (nonatomic, strong) MessagesData *messagesData;
@property (nonatomic, strong) NSMutableDictionary *IDAvatar;
@property (nonatomic, strong) NSMutableDictionary *IDAvatarURL;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (assign, nonatomic) BOOL isDialog;

@property (strong, nonatomic) NSString *myName;
@property (strong, nonatomic) NSString *myID;

@end

@implementation MessagesVC

#pragma mark - Main methods overriden

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initAll];
    if (self.chat) {
        self.messagesData = [[MessagesData alloc]initWithChat:self.chat updateChatDelegate:self];
    }
    else if (self.anotherUser) {
        self.messagesData = [[MessagesData alloc] initChatWithUser:self.anotherUser updateChatDelegate:self];
    }
    [self setupPullToRefresh];
    [self closeRevealVC];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.chat) {
        self.navigationItem.title = self.chat.name;
    }
    else if (self.anotherUser) {
        self.navigationItem.title = self.anotherUser.displayName;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if(self.inputToolbar.contentView.textView.isFirstResponder) {
        [self.inputToolbar.contentView.textView resignFirstResponder];
    }
}

- (void)dealloc {
    self.messagesData = nil;
}

-(void)closeRevealVC{
    SWRevealViewController *revealController = [self revealViewController];
    [revealController tapGestureRecognizer];
    [revealController panGestureRecognizer];
}

#pragma mark - Initilization

- (void)initAll {
    
    //set delegates
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    [self setupTextField];
    [self setupMyIDAndMyName];
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    
    //setup bubble
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    // check if it is group chat or dialog
    if (self.anotherUser || self.chat.isDialog) {
        self.isDialog = YES;
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        self.navigationItem.rightBarButtonItem = nil;
        
        if (self.chat.isDialog) {
            _anotherUser = _chat.usersModel[0];
        }
        [self addRightBarButtonWithImage];
    }
    else if (self.chat) {
        self.isDialog = NO;
        [self initAvatarURL];
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    }
}

- (void)setupTextField {
    self.inputToolbar.contentView.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.inputToolbar.contentView.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputToolbar.contentView.textView.spellCheckingType = UITextSpellCheckingTypeNo;
}

- (void)setupPullToRefresh {
    
    __weak MessagesVC *selfWeak = self;
    [selfWeak.collectionView addPullToRefreshWithActionHandler:^{
        [selfWeak.collectionView.pullToRefreshView stopAnimating];
        [selfWeak.messagesData loadNewMessagesPortion];
    }];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIView *triggeredView = [[UIView alloc]init];
    [triggeredView addSubview:indicator];
    [indicator startAnimating];
    [self.collectionView.pullToRefreshView setCustomView:indicator forState:SVPullToRefreshStateTriggered];
    [self.collectionView.pullToRefreshView setCustomView:[[UIView alloc]init] forState:SVPullToRefreshStateStopped];
    [self.collectionView.pullToRefreshView setCustomView:[[UIView alloc]init] forState:SVPullToRefreshStateLoading];
}

- (void)setupMyIDAndMyName {
    
    NSString *name = [FIRServerManager sharedManager].getMyName;
    NSString *myID = [FIRServerManager sharedManager].getMyId;
    BOOL isAuth = [FIRServerManager sharedManager].isAuth;
    
    if (isAuth) {
        self.myName = name;
        self.myID = myID;
    }
    else {
        self.myName = ANONIM_USER_NAME;
        self.myID = ANONIM_USER_ID;
    }
}

- (void)addRightBarButtonWithImage{
    UIImage *btnImage = [UIImage imageNamed:@"default-avatar"];
    [self setupDialogAvatar:btnImage];
    [[FIRServerManager sharedManager] loadProfilePhotoForUser:_anotherUser successBlock:^(UIImage *image) {
        if(image) {
            UIImage *btnImage = [FIRServerManager imageWithImage:image scaledToSize:CGSizeMake(35,35)];
            [self setupDialogAvatar:btnImage];
        }
    }];
}

- (void)setupDialogAvatar:(UIImage *)image {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.bounds = CGRectMake( 0, 0, 35, 35);
    btn.layer.cornerRadius = btn.frame.size.width / 2;
    btn.clipsToBounds = YES;
    [btn addTarget:self action:@selector(showUserProfile) forControlEvents:UIControlEventTouchDown];
    [btn setImage:image forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
}

#pragma mark - Init && Load Avatars


- (void)initAvatarURL {
    self.IDAvatar = [NSMutableDictionary dictionary];
    self.IDAvatarURL = [NSMutableDictionary dictionary];
    for (User *user in self.chat.usersModel) {
        if (user.photo) {
            [self.IDAvatarURL setObject:user.photo forKey:user.uid];
        }
    }
    UserAvatar *avatar = [[UserAvatar alloc] initAvatarWithImageURL:nil];
    [self.IDAvatar setObject:avatar forKey:@"-1"];
}

- (void)loadAvatarFromUserID:(NSString*)userID {
    UserAvatar *avatar = [self.IDAvatar objectForKey:userID];
    if (!avatar) {
        NSString *imageURL = [self.IDAvatarURL objectForKey:userID];
        if (imageURL) {
            UserAvatar *avatar = [[UserAvatar alloc] initAvatarWithImageURL:imageURL];
            avatar.collectionView = self.collectionView;
            [self.IDAvatar setObject:avatar forKey:userID];
        }
    }
}

#pragma mark - UpdateChatDelegate

- (void)updateWhenComming {
    if (!self.isDialog) {
        for (JSQMessage *msg in self.messagesData.messages) {
            [self loadAvatarFromUserID:msg.senderId];
        }
    }
    [self finishReceivingMessageAnimated:NO];
}

- (void)updateWhenGetNewMessage {
    if (!self.isDialog) {
        JSQMessage *newMessages = [self.messagesData.messages lastObject];
        [self loadAvatarFromUserID:newMessages.senderId];
    }
    [self finishReceivingMessageAnimated:YES];
    [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
}

- (void)updateWhenGetMyMessage {
    [self finishSendingMessageAnimated:YES];
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
}

- (void)updateWhenGetNewMessagesPortion {
    if (!self.isDialog) {
        for (JSQMessage *msg in self.messagesData.messages) {
            [self loadAvatarFromUserID:msg.senderId];
        }
    }
    self.collectionView.collectionViewLayout.isInsertingCellsToTop = YES;
    self.collectionView.collectionViewLayout.contentSizeWhenInsertingToTop = self.collectionView.collectionViewLayout.collectionViewContentSize;
    [self.collectionView reloadData];
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"ChatEditing"]) {
        ChatManageVC *chatManageVC = [segue destinationViewController];
        chatManageVC.showingChat = self.chat;
    }else
    if ([segue.identifier isEqualToString:@"showUser"]) {
        NewProfileVC *profileVC = [segue destinationViewController];
        [profileVC setupProfileForUser:_anotherUser];
    }
}

- (void)showUserProfile{
    [self performSegueWithIdentifier:@"showUser" sender:self];
}

#pragma mark - Messages view controller Actions

- (void)didPressSendButton:(UIButton *)button
            withMessageText:(NSString *)text
                   senderId:(NSString *)senderId
          senderDisplayName:(NSString *)senderDisplayName
                       date:(NSDate *)date{
    
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
    [self.messagesData sendMessage:message];
    //[self.messagesData.messages addObject:message];
    //[self finishSendingMessageAnimated:YES];
    //[JSQSystemSoundPlayer jsq_playMessageSentSound];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [self.messagesData.messages objectAtIndex:indexPath.item];
    if(message.isMediaMessage) {
        UIImage *image;
        if ([message.media isKindOfClass:[AsyncPhotoMediaItem class]]) {
            AsyncPhotoMediaItem *media = (AsyncPhotoMediaItem*)message.media;
            image = media.asyncImageView.image;
        }
        else if([message.media isKindOfClass:[JSQPhotoMediaItem class]]) {
            JSQPhotoMediaItem *media = (JSQPhotoMediaItem*)message.media;
            image = media.image;
        }
        if (image) {
            UINavigationController *nav = [FullScreenVC returnFromStorybord];
            FullScreenVC *fullScreen = nav.viewControllers.firstObject;
            fullScreen.image = image;
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}


#pragma mark - JSQMessagesCollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    JSQMessage *message = [self.messagesData.messages objectAtIndex:indexPath.item];
    JSQMessage *previousMessage = [self.messagesData.messages objectAtIndex:indexPath.item -1];
    
    NSDateComponents *dayComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:message.date];
    NSDateComponents *previousDayComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:previousMessage.date];
    
    if (previousDayComponents.day != dayComponents.day) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [self.messagesData.messages objectAtIndex:indexPath.item];
    
    if (indexPath.item == 0) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampOnlyDayForDate:message.date];
    }
    
    JSQMessage *previousMessage = [self.messagesData.messages objectAtIndex:indexPath.item -1];
    
    NSDateComponents *dayComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:message.date];
    NSDateComponents *previousDayComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:previousMessage.date];
    
    if (previousDayComponents.day != dayComponents.day) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampOnlyDayForDate:message.date];
    }
    
    return nil;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *currentMessage = [self.messagesData.messages objectAtIndex:indexPath.item];
    
    if (indexPath.item - 1 >= 0) {
        JSQMessage *previousMessage = [self.messagesData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            double time = [currentMessage.date timeIntervalSinceDate:previousMessage.date];
            if (time < 60*60) {
                return 0.0f;
            }
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault + 5;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messagesData.messages objectAtIndex:indexPath.item];
    NSAttributedString *dateString = [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampOnlyTimeForDate:message.date];
    
    if (indexPath.item - 1 >= 0) {
        JSQMessage *previousMessage = [self.messagesData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            //if time diff behind comment more then 1 hour show date
            double time = [message.date timeIntervalSinceDate:previousMessage.date];
            if (time >= 60*60) {
                return dateString;
            }
            else {
                return nil;
            }
        }
    }
    
    if (self.isDialog) {
        return dateString;
    }
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName : DARKER_GREY_COLOR };
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:message.senderDisplayName attributes:attributes];
    [string appendAttributedString:dateString];
    if ([message.senderId isEqualToString:self.senderId]) {
        return dateString;
    }
    
    return string;
}


- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - JSQMessagesCollectionViewDataSource

- (NSString *)senderDisplayName {
    return self.myName;
}

- (NSString *)senderId {
    return self.myID;
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.messagesData.messages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
     [self.messagesData.messages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [self.messagesData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessage *message = [self.messagesData.messages objectAtIndex:indexPath.item];
    UserAvatar *avatar =  [self.IDAvatar objectForKey:message.senderId];
    [avatar.indexPaths addObject:indexPath];
    avatar = avatar ? avatar : [self.IDAvatar objectForKey:@"-1"];
    return avatar;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.messagesData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    JSQMessage *msg = [self.messagesData.messages objectAtIndex:indexPath.item];
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        //send media message
        [self.messagesData.messages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}


#pragma mark - Work with Accessory button

- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    UIAlertController *choseMediaType = [UIAlertController alertControllerWithTitle:@"Add Media" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *addPhotoFromLibrary = [UIAlertAction actionWithTitle:@"Add Photo From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    UIAlertAction *addPhotoFromCamera = [UIAlertAction actionWithTitle:@"Add Photo From Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSourceType:UIImagePickerControllerSourceTypeCamera];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [choseMediaType addAction:addPhotoFromLibrary];
    [choseMediaType addAction:addPhotoFromCamera];
    [choseMediaType addAction:cancel];
    
    [self presentViewController:choseMediaType animated:YES completion:nil];
}

- (void)showSourceType: (UIImagePickerControllerSourceType) sourceType {
    if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    JSQPhotoMediaItem *photo = [[JSQPhotoMediaItem alloc]initWithImage:image];
    
    JSQMessage *mediaMessage = [JSQMessage messageWithSenderId:self.senderId displayName:self.senderDisplayName media:photo];
    
    [self.messagesData sendMessage:mediaMessage];
    
    //[self.messagesData.messages addObject:mediaMessage];
    //[self finishSendingMessageAnimated:YES];
    //[JSQSystemSoundPlayer jsq_playMessageSentSound];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}




@end
