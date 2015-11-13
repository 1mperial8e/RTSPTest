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

#import "SPHTextureProvider.h"
#import <CoreImage/CoreImage.h>

@implementation SPHTextureProvider

+ (CGImageRef)imageWithCVPixelBufferUsingUIGraphicsContext:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int hight = (int)CVPixelBufferGetHeight(pixelBuffer);
    int rows = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int bytesPerPixel = rows/width;
    
    unsigned char *bufferPointer = CVPixelBufferGetBaseAddress(pixelBuffer);
    UIGraphicsBeginImageContext(CGSizeMake(width, hight));
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    unsigned char* data = CGBitmapContextGetData(context);
    if (data) {
        int maxY = hight;
        for(int y = 0; y < maxY; y++) {
            for(int x = 0; x < width; x++) {
                int offset = bytesPerPixel*((width*y)+x);
                data[offset] = bufferPointer[offset];     // R
                data[offset+1] = bufferPointer[offset+1]; // G
                data[offset+2] = bufferPointer[offset+2]; // B
                data[offset+3] = bufferPointer[offset+3]; // A
            }
        }
    }
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVBufferRelease(pixelBuffer);
    
    return cgImage;
}

@end
