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

#import "SPHBaseViewController.h"
#import <GLKit/GLKit.h>
#import <CoreMotion/CoreMotion.h>

static CGFloat SPHVelocityCoef = 0.01f;

@interface SPHBaseModel : NSObject

- (instancetype)initWithViewController:(SPHBaseViewController *)viewController
                                GLView:(GLKView *)glView;

@property (weak, nonatomic) SPHBaseViewController *baseController;
@property (weak, nonatomic) GLKView *glView;

// zoom properties
@property (assign, nonatomic) CGFloat maxZoomValue;
@property (assign, nonatomic) CGFloat minZoomValue;
@property (assign, nonatomic) CGFloat defaultZoomValue;
@property (assign, nonatomic) CGFloat zoomValue;

@property (assign, nonatomic) BOOL isZooming;
@property (assign, nonatomic) BOOL isUpdatingZoom;

// projection matrix
@property (assign, nonatomic) CGFloat angle;
@property (assign, nonatomic) CGFloat near;

@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrixInfinite;

@property (assign, nonatomic) GLKMatrix4 currentProjectionMatrix;
@property (assign, nonatomic) GLKMatrix4 cameraProjectionMatrix;

// gyroscope
@property (assign, nonatomic) BOOL gyroscopeActive;
@property (strong, nonatomic) CMMotionManager *motionManager;

// velocity
@property (assign, nonatomic) CGPoint velocity;

- (BOOL)isGyroscopeEnabled;

- (void)setupDefaults;
- (void)update;

- (void)moveToPointX:(CGFloat)pointX andPointY:(CGFloat)pointY;

- (CGFloat)normalizedAngle:(CGFloat)normalAngle;
- (CGFloat)normalizedNear:(CGFloat)normalNear;

@end
