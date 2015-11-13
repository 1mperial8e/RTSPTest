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

#import <AVFoundation/AVFoundation.h>

@protocol SPHVideoPlayerDelegate <NSObject>

@optional
- (void)progressDidUpdate:(CGFloat)progress;
- (void)downloadingProgress:(CGFloat)progress;
- (void)progressTimeChanged:(CMTime)time;
- (void)isReadyToPlay;
- (void)playerDidChangeProgressTime:(CGFloat)time totalTime:(CGFloat)totalDuration;

@end

@interface SPHVideoPlayer : NSObject

@property (weak, nonatomic) id <SPHVideoPlayerDelegate> delegate;
@property (assign, nonatomic) CGFloat volume;
@property (assign, nonatomic) CGFloat assetDuration;

- (instancetype)initVideoPlayerWithURL:(NSURL *)urlAsset;
- (void)prepareToPlay;

- (void)play;
- (void)pause;
- (void)stop;
- (void)seekPositionAtProgress:(CGFloat)progressValue withPlayingStatus:(BOOL)isPlaying;
- (void)setPlayerVolume:(CGFloat)volume;
- (void)setPlayerRate:(CGFloat)rate;

- (BOOL)canProvideFrame;
- (CVImageBufferRef)getCurrentFramePicture;

- (void)removeObserversFromPlayer;

@end
