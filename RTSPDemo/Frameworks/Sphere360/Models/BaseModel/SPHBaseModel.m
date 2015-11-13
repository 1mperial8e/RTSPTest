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

#import "SPHBaseModel.h"

@implementation SPHBaseModel

#pragma mark - Init

- (instancetype)initWithViewController:(SPHBaseViewController *)viewController
                                GLView:(GLKView *)glView;
{
    self = [super init];
    if (self) {
        self.baseController = viewController;
        self.glView = glView;
        [self setupDefaults];
    }
    return self;
}

#pragma mark - Custom Accessors

- (void)setGyroscopeActive:(BOOL)gyroscopeActive
{
    _gyroscopeActive = gyroscopeActive;
}

- (CMMotionManager *)motionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

#pragma mark - Zoom

- (void)updateZoomValue
{
    if (self.zoomValue > self.maxZoomValue) {
        self.isUpdatingZoom = YES;
        self.zoomValue *= 0.99;
    } else if (self.zoomValue <  self.minZoomValue) {
        self.isUpdatingZoom = YES;
        self.zoomValue *= 1.01;
    } else {
        self.isUpdatingZoom = NO;
    }
}

#pragma mark - Gyroscope

- (BOOL)isGyroscopeEnabled
{
    return NO;
}

#pragma mark - Override

- (void)setupDefaults
{
    // for subclassing
}

- (void)moveToPointX:(CGFloat)pointX andPointY:(CGFloat)pointY
{
    // for subclassing
}

- (void)update
{
    if (!self.isZooming) {
        [self updateZoomValue];
    }
}

#pragma mark - Projection

- (CGFloat)normalizedAngle:(CGFloat)normalAngle
{
    if (!self.angle) {
        self.angle = normalAngle;
        return normalAngle;
    }
    switch (self.baseController.viewModel) {
        case SphericalModel: {
            if (self.angle > normalAngle) {
                self.angle--;
            }
            break;
        }
        case LittlePlanetModel: {
            if (self.angle < normalAngle) {
                self.angle++;
            }
            break;
        }
        default: {
            self.angle = normalAngle;
            break;
        }
    }
    return self.angle;
}

- (CGFloat)normalizedNear:(CGFloat)normalNear
{
    if (!self.near) {
        self.near = normalNear;
        return normalNear;
    }
    switch (self.baseController.viewModel) {
        case SphericalModel: {
            if (self.near < normalNear) {
                self.near+=0.005;
            }
            break;
        }
        case LittlePlanetModel: {
            if (self.near > normalNear) {
                self.near-=0.005;
            }
            break;
        }
        default: {
            self.near = normalNear;
            break;
        }
    }
    return self.near;
}

@end
