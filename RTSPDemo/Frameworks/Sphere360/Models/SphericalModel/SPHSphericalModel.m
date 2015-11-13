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

#import "SPHSphericalModel.h"

static CGFloat const SPHSphericalAngle = 90.0f;
static CGFloat const SPHSphericalNear = 0.1f;

@implementation SPHSphericalModel

#pragma mark - LifeCycle

- (void)dealloc
{
    if (self.motionManager.isDeviceMotionActive) {
        [self.motionManager stopDeviceMotionUpdates];
    }
}

#pragma mark - Custom Accessors

- (void)setGyroscopeActive:(BOOL)gyroscopeActive
{
    if (![self.motionManager isDeviceMotionAvailable]) {
        [self showAlertNoGyroscopeAvaliable];
        [super setGyroscopeActive:NO];
        return;
    }
    if (gyroscopeActive && !self.motionManager.isDeviceMotionActive) {
        [super setGyroscopeActive:YES];
        self.motionManager.gyroUpdateInterval = 1 / 60;
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXMagneticNorthZVertical];
    } else if (!gyroscopeActive && self.motionManager.isDeviceMotionActive) {
        [self.motionManager stopDeviceMotionUpdates];
        [super setGyroscopeActive:NO];
    } else {
        [super setGyroscopeActive:gyroscopeActive];
    }
}

#pragma mark - Override

- (BOOL)isGyroscopeEnabled
{
    return YES;
}

- (void)setupDefaults
{
    self.currentProjectionMatrix = GLKMatrix4Identity;
    self.cameraProjectionMatrix = GLKMatrix4Identity;
    self.minZoomValue = 1.086f;
    self.maxZoomValue = 1.5f;
    self.defaultZoomValue = 1.2f;
    self.zoomValue = self.defaultZoomValue;
}

- (void)moveToPointX:(CGFloat)pointX andPointY:(CGFloat)pointY
{
    if (self.gyroscopeActive) {
        return;
    }
    pointX *= 0.005;
    pointY *= 0.005;
    
    GLKMatrix4 rotatedMatrix = GLKMatrix4MakeRotation(-pointX / self.zoomValue, 0, 1, 0);
    self.currentProjectionMatrix = GLKMatrix4Multiply(self.currentProjectionMatrix, rotatedMatrix);
    GLKMatrix4 cameraMatrix = GLKMatrix4MakeRotation(-pointY / self.zoomValue, 1, 0, 0);
    self.cameraProjectionMatrix = GLKMatrix4Multiply(self.cameraProjectionMatrix, cameraMatrix);
}

- (void)update
{
    [super update];
    [self updateMovement];
    
    CGFloat angle = [super normalizedAngle:SPHSphericalAngle];
    CGFloat near = [super normalizedNear:SPHSphericalNear];
    
    CGFloat cameraDistanse = - (self.zoomValue - self.maxZoomValue);
    if (self.baseController.interfaceOrientation == UIInterfaceOrientationPortrait) {
        angle += 10;
        cameraDistanse += 0.62f; // fix aspect difference in portrait & landscape
    }
    CGRect viewFrame = self.baseController.view.frame;
    CGFloat FOVY = GLKMathDegreesToRadians(angle) / self.zoomValue;
    CGFloat aspect = fabs(viewFrame.size.width / viewFrame.size.height);
    
    GLKMatrix4 cameraTranslation = GLKMatrix4MakeTranslation(0, 0, -cameraDistanse / 2.0);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(FOVY, aspect, near, 2.4);
    projectionMatrix = GLKMatrix4Multiply(projectionMatrix, cameraTranslation);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    
    if (self.gyroscopeActive) {
        CMQuaternion quat = self.motionManager.deviceMotion.attitude.quaternion;
        GLKQuaternion glQuat = GLKQuaternionMake(-quat.y, -quat.z, -quat.x, quat.w);
        if (self.baseController.interfaceOrientation == UIInterfaceOrientationPortrait) {
            projectionMatrix = GLKMatrix4Rotate(projectionMatrix, M_PI / 2, 0, 0, 1);
        } else if (self.baseController.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            projectionMatrix = GLKMatrix4Rotate(projectionMatrix, M_PI, 0, 0, 1);
        }
        modelViewMatrix = GLKMatrix4MakeWithQuaternion(glQuat);
        projectionMatrix = GLKMatrix4Rotate(projectionMatrix, M_PI / 2, 1, 0, 0);
        self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    } else {
        projectionMatrix = GLKMatrix4Multiply(projectionMatrix, self.cameraProjectionMatrix);
        modelViewMatrix = self.currentProjectionMatrix;
        self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    }
}

#pragma mark - Private

- (void)showAlertNoGyroscopeAvaliable
{
    NSString *title = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    [[[UIAlertView alloc] initWithTitle:title message:@"Gyroscope is not avaliable on your device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

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
