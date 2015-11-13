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

#import "SPHPhotoViewController.h"

typedef NS_ENUM(NSUInteger, PreviewMode) {
    PreviewModePhoto,
    PreviewModeRTSPPlayer
};

@interface GiropticPhotoPreviewVC : SPHPhotoViewController

@property (copy, nonatomic) NSString *imageName;
@property (strong, nonatomic) UIWindow *sphereWindow;

@property (assign, nonatomic) PreviewMode mode;
@property (copy, nonatomic) NSString *rtspUri;

- (void)updateRTSPPlayerWithUri:(NSString *)uri;
- (void)startDisplayRTSPPlayer;
- (void)stopDisplayRTSPPlayer;
- (void)releaseRTSPPlayer;

@end
