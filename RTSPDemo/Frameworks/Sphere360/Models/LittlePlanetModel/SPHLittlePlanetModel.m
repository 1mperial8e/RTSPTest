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

#import "SPHLittlePlanetModel.h"

static CGFloat const SPHLittlePlanetAngle = 110.0f;
static CGFloat const SPHLittlePlanetNear = 0.01f;

@implementation SPHLittlePlanetModel

- (void)setupDefaults
{
    self.currentProjectionMatrix = GLKMatrix4Identity;
    self.cameraProjectionMatrix = GLKMatrix4MakeRotation(M_PI_2, 1, 0, 0);
    self.minZoomValue = 0.77f;
    self.maxZoomValue = 1.5f;
    self.defaultZoomValue = 0.77f;
    self.zoomValue = self.defaultZoomValue;
}

- (void)moveToPointX:(CGFloat)pointX andPointY:(CGFloat)pointY
{
    if (self.gyroscopeActive) {
        return;
    }
    pointX *= 0.005;
    
    GLKMatrix4 rotatedMatrix = GLKMatrix4MakeRotation(-pointX / self.zoomValue, 0, 1, 0);
    self.currentProjectionMatrix = GLKMatrix4Multiply(self.currentProjectionMatrix, rotatedMatrix);
}

- (void)update
{
    [super update];
    [self updateMovement];
    CGFloat angle = [super normalizedAngle:SPHLittlePlanetAngle];
    CGFloat near = [super normalizedNear:SPHLittlePlanetNear];

    CGRect viewFrame = self.baseController.view.frame;
    CGFloat aspect = fabs(viewFrame.size.width / viewFrame.size.height);
    
    CGFloat cameraDistanse = - (self.zoomValue - self.maxZoomValue);
    if (self.baseController.interfaceOrientation == UIInterfaceOrientationPortrait) {
        angle += 7; // fix aspect difference in portrait & landscape
    }
    CGFloat FOVY = GLKMathDegreesToRadians(angle) / self.zoomValue;

    GLKMatrix4 cameraTranslation = GLKMatrix4MakeTranslation(0, 0, -cameraDistanse / 2.0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(FOVY, aspect, near, 2.4);
    projectionMatrix = GLKMatrix4Multiply(projectionMatrix, cameraTranslation);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;

    projectionMatrix = GLKMatrix4Multiply(projectionMatrix, self.cameraProjectionMatrix);
    modelViewMatrix = self.currentProjectionMatrix;
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

#pragma mark - Private

- (void)updateMovement
{
    if (CGPointEqualToPoint(self.velocity, CGPointZero)) {
        return;
    }
    self.velocity = CGPointMake(0.9 * self.velocity.x, 0.9 * self.velocity.y);
    CGPoint nextPoint = CGPointMake(SPHVelocityCoef * self.velocity.x, SPHVelocityCoef * self.velocity.y);
    if (fabs(nextPoint.x) < 0.1 && fabs(nextPoint.y) < 0.1) {
        self.velocity = CGPointZero;
    }
    [self moveToPointX:nextPoint.x andPointY:nextPoint.y];
}

@end
