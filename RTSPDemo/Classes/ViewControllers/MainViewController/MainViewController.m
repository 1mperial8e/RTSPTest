//
//  MainViewController.m
//  RTSPDemo
//
//  Created by Kirill Gorbushko on 09.06.15.
//  Copyright (c) 2015 Kirill Gorbushko. All rights reserved.
//

#import "MainViewController.h"
#import "GiropticPhotoPreviewVC.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UITextField *linkTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation MainViewController

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupNotification];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeNotification];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    GiropticPhotoPreviewVC *photoRTSP = (GiropticPhotoPreviewVC *)segue.destinationViewController;
    photoRTSP.mode = PreviewModeRTSPPlayer;

    if ([segue.identifier isEqualToString:@"rtsp7"]) {
        photoRTSP.rtspUri = @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov";
    } else {
        photoRTSP.rtspUri = @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov";
    }
}

#pragma mark - Keyboard

- (void)setupNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeNotification
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    } @catch (NSException *ex){
        NSLog(@"Cant remove observer for keyboard - %@",ex.description);
    }
}

- (void)keyboardOnScreen:(NSNotification *)notification
{
    CGFloat offset = 150;
    self.scrollView.contentOffset = CGPointMake(0, offset);
}

- (void)keyboardHide:(NSNotification *)notification
{
    self.scrollView.contentOffset = CGPointZero;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyDone) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.scrollView.contentOffset = CGPointZero;
            [textField endEditing:YES];
        }];
        return YES;
    }
    return YES;
}

@end
