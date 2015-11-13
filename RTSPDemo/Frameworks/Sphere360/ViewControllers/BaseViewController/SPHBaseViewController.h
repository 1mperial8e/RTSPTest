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

#import "SPHVideoPlayer.h"

typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypePhoto,
    MediaTypeVideo,
    MediaTypeLive
};

typedef NS_ENUM(NSInteger, SPHViewModel) {
    SphericalModel,
    PlanarModel,
    LittlePlanetModel,
    CubicModel
};

@interface SPHBaseViewController : UIViewController

@property (strong, nonatomic) NSString *sourceVideoURL;
@property (strong, nonatomic) UIImage *sourceImage;

@property (assign, nonatomic, readonly) MediaType mediaType;

// Spherical by default
@property (assign, nonatomic, readonly) SPHViewModel viewModel;

- (instancetype)initWithMediaType:(MediaType)mediaType;
- (instancetype)initWithCoder:(NSCoder *)aDecoder MediaType:(MediaType)mediaType;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MediaType:(MediaType)mediaType;

- (void)setupTextureWithImage:(CGImageRef)image;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)setGyroscopeActive:(BOOL)active;
- (BOOL)isGyroscopeActive;
- (BOOL)isGyroscopeEnabled;

- (void)switchToModel:(SPHViewModel)model;

- (void)applyImageTexture;
- (void)drawArraysGL;
- (void)update;

@end
