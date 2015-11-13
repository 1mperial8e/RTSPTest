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

#import "SPHPlanarModel.h"

static CGFloat const SPHPlanarAngle = 70.0f;
static CGFloat const SPHPlanarNear = 0.1f;

@interface SPHPlanarModel ()

@end

@implementation SPHPlanarModel {
    CGFloat xMove;
}

#pragma mark - Custom Accessors

- (void)setGyroscopeActive:(BOOL)gyroscopeActive
{
    [super setGyroscopeActive:NO];
}

- (CMMotionManager *)motionManager
{
    return nil;
}

#pragma mark - Override

- (void)setupDefaults
{
    self.currentProjectionMatrix = GLKMatrix4Identity;
    self.cameraProjectionMatrix = GLKMatrix4Identity;
    self.minZoomValue = 1.2f;
    self.maxZoomValue = 2.7f;
    self.defaultZoomValue = 1.1f;
    self.zoomValue = self.defaultZoomValue;
}

- (void)update
{
    [super update];
    [self updateMovement];
    
    CGFloat angle = [super normalizedAngle:SPHPlanarAngle];
    CGFloat near = [super normalizedNear:SPHPlanarNear];
    
    CGRect viewFrame = self.baseController.view.frame;
    
    CGFloat FOVY = GLKMathDegreesToRadians(angle) / self.defaultZoomValue;
    CGFloat aspect = fabs(viewFrame.size.width / viewFrame.size.height);

    CGFloat cameraDistanse = - (self.defaultZoomValue - 1.7f);
    
    GLKMatrix4 cameraTranslation = GLKMatrix4MakeTranslation(0, 0, -cameraDistanse / 1.4);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(FOVY, aspect, near, 2.4);
    projectionMatrix = GLKMatrix4Multiply(projectionMatrix, cameraTranslation);
    projectionMatrix = GLKMatrix4Multiply(projectionMatrix, self.cameraProjectionMatrix);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, self.currentProjectionMatrix);
    self.modelViewProjectionMatrixInfinite = self.modelViewProjectionMatrix;
    
    if (self.modelViewProjectionMatrix.m30 >= self.modelViewProjectionMatrix.m00 || self.modelViewProjectionMatrix.m30 <= self.modelViewProjectionMatrix.m00) {
        GLKMatrix4 projectionMatrix = self.modelViewProjectionMatrix;
        projectionMatrix.m30 = fmodf(self.modelViewProjectionMatrix.m30 , self.modelViewProjectionMatrix.m00);
        self.modelViewProjectionMatrix = projectionMatrix;
    }
    
    GLKMatrix4 modelProjectionMatrix2 = self.modelViewProjectionMatrix;
    if (self.modelViewProjectionMatrix.m30 > 0) {
        modelProjectionMatrix2.m30 = self.modelViewProjectionMatrix.m30 - self.modelViewProjectionMatrix.m00;
    } else {
        modelProjectionMatrix2.m30 = self.modelViewProjectionMatrix.m30 + self.modelViewProjectionMatrix.m00;
    }
    self.modelViewProjectionMatrixInfinite = modelProjectionMatrix2;
}

- (void)moveToPointX:(CGFloat)pointX andPointY:(CGFloat)pointY
{
    if (self.gyroscopeActive || [self isMoveDisabled]) {
        return;
    }
    pointX *= 0.0005;
    xMove += pointX;
    GLKMatrix4 newMatrix = self.currentProjectionMatrix;
    newMatrix.m30 = xMove;
    self.currentProjectionMatrix = newMatrix;
}

- (void)updateMovement
{
    if (CGPointEqualToPoint(self.velocity, CGPointZero) || [self isMoveDisabled]) {
        return;
    }
    self.velocity = CGPointMake(0.9 * self.velocity.x, 0.9 * self.velocity.y);
    CGPoint nextPoint = CGPointMake(SPHVelocityCoef * self.velocity.x, SPHVelocityCoef * self.velocity.y);
    if (fabs(nextPoint.x) < 0.1 && fabs(nextPoint.y) < 0.1) {
        self.velocity = CGPointZero;
    }
    [self moveToPointX:nextPoint.x andPointY:nextPoint.y];
}

#pragma mark - Private

- (BOOL)isMoveDisabled
{
    BOOL enabled = NO;
    CGRect viewFrame = self.baseController.view.frame;
    if (viewFrame.size.width > viewFrame.size.height) {
        enabled = YES;
    }
    return enabled;
}

@end