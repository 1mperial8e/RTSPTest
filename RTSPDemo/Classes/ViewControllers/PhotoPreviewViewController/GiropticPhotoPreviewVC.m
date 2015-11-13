//  iOS 360° Player
//  Copyright (C) 2015  Giroptic
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

#import "GiropticPhotoPreviewVC.h"
#import "RTSPPlayer.h"

static NSInteger const TopBarInitialHeight = 64;
static NSInteger const BottomBarInitialHeight = 49;
static NSInteger const TopBarHeightLandscape = 44;

@interface GiropticPhotoPreviewVC ()

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomOffcetForCloseButtonConstraint;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *gyroButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *littlePlanetButtonTralingConstraint;

@property (assign, nonatomic) NSInteger topBarHeight;

@property (assign, nonatomic) BOOL isShown;

@property (strong, nonatomic) NSTimer *rtspNextFrameTimer;
@property (strong, nonatomic) RTSPPlayer *rtspPlayer;

@end

@implementation GiropticPhotoPreviewVC

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addTapGesture];
    [self prepareUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareNotification];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.mode) {
        [self prepareRTSPPlayer];
        [self startDisplayRTSPPlayer];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.isShown) {
        self.isShown = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    [self releaseRTSPPlayer];
    [self forceRotation];
    self.isShown = NO;
}

#pragma mark - Public

- (void)updateRTSPPlayerWithUri:(NSString *)uri
{
    if (uri.length) {
        self.rtspUri = uri;
    }
    [self prepareRTSPPlayer];
}

- (void)startDisplayRTSPPlayer
{
    if (self.rtspPlayer) {
        self.rtspNextFrameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/25. target:self selector:@selector(displayNextFrame:) userInfo:nil repeats:YES];
    }
}

- (void)stopDisplayRTSPPlayer
{
    [self.rtspNextFrameTimer invalidate];
}

#pragma mark - Notifications

- (void)prepareNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeNotifications
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
        NSLog(@"Cant remove observers %@", exception.debugDescription);
    }
}

- (void)adjustViewsForOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: {
            self.topBarHeight = TopBarInitialHeight;
            [self animatedChangeHeightOfTopBar:orientation];
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight: {
            self.topBarHeight = TopBarHeightLandscape;
            [self animatedChangeHeightOfTopBar:orientation];
            break;
        }
        case UIInterfaceOrientationUnknown:{
            break;
        }
    }
}

#pragma mark - Rotation

- (void)canRotate
{
    //dummy
}

- (void)forceRotation
{
    [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
}

- (void)orientationChanged:(NSNotification *)notification
{
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void)animatedChangeHeightOfTopBar:(UIInterfaceOrientation)orientation
{
    if (self.topViewHeightConstraint.constant) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.topViewHeightConstraint.constant = weakSelf.topBarHeight;
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                weakSelf.bottomOffcetForCloseButtonConstraint.constant = (weakSelf.topBarHeight - weakSelf.closeButton.frame.size.height) / 2;
            } else if (UIInterfaceOrientationIsPortrait(orientation)) {
                weakSelf.bottomOffcetForCloseButtonConstraint.constant = (weakSelf.topBarHeight - 20 - weakSelf.closeButton.frame.size.height) / 2;
            }

            [weakSelf.topView layoutIfNeeded];
        }];
    }
}

#pragma mark - RTSP player

- (void)prepareRTSPPlayer
{
    if (!self.rtspUri.length) {
        return;
    }
    
    self.rtspPlayer = [[RTSPPlayer alloc] initWithVideo:self.rtspUri usesTcp:YES];
    //optional
//    self.rtspPlayer.outputWidth = 426;
//    self.rtspPlayer.outputHeight = 320;
}

- (void)displayNextFrame:(NSTimer *)timer
{
    if (![self.rtspPlayer stepFrame]) {
        [self releaseRTSPPlayer];
        return;
    }
    [super setupTextureWithImage:self.rtspPlayer.currentCGImage];
}

- (void)releaseRTSPPlayer
{
    if (self.rtspPlayer) {
        [self.rtspNextFrameTimer invalidate];
        self.self.rtspNextFrameTimer = nil;
        [self.rtspPlayer closeAudio];
        self.rtspPlayer = nil;
    }
}

#pragma mark - Private

- (void)prepareUI
{
    self.topBarHeight = TopBarInitialHeight;
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)hideBottomBar
{
    BOOL hidden = self.bottomViewHeightConstraint.constant;
    CGFloat newHeight = hidden ? 0.0f : BottomBarInitialHeight;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        weakSelf.bottomViewHeightConstraint.constant = newHeight;
        [weakSelf.bottomView layoutIfNeeded];
    }];
}

- (void)hideTopBar
{
    BOOL hidden = self.topViewHeightConstraint.constant;
    CGFloat newHeight = hidden ? 0.0f : self.topBarHeight;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        weakSelf.topViewHeightConstraint.constant = newHeight;
        [weakSelf.topView layoutIfNeeded];
    }];
}

- (void)addTapGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
    [self.navigationController.view addGestureRecognizer:tapGesture];
}

#pragma mark - AnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (anim == [self.sphereWindow.rootViewController.view.layer animationForKey:@"fadeAnim"]) {
        [self.sphereWindow.rootViewController.view.layer removeAllAnimations];
        self.sphereWindow = nil;
    }
}

#pragma mark - IBActions

- (IBAction)gyroscopeButtonPress:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self setGyroscopeActive:sender.selected];
}

- (IBAction)switchModeButtonPress:(id)sender
{
    if (self.viewModel == LittlePlanetModel) {
        [self switchToModel:SphericalModel];
    } else {
        [self switchToModel:LittlePlanetModel];
    }
}

- (IBAction)panoramaButtonPress:(id)sender
{
    __weak typeof(self) weakSelf = self;
    if (self.viewModel == PlanarModel) {
        [self switchToModel:SphericalModel];
        
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.gyroButton.hidden = NO;
            weakSelf.littlePlanetButtonTralingConstraint.constant = 42;
        }];
    } else {
        [self switchToModel:PlanarModel];
        
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.gyroButton.hidden = YES;
            weakSelf.littlePlanetButtonTralingConstraint.constant = 8;
        }];
    }
}

- (IBAction)backButtonPress:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)tapGesture
{
    [self hideBottomBar];
    [self hideTopBar];
}

@end