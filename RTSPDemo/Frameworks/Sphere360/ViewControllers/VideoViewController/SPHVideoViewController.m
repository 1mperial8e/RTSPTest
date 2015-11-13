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

#import "SPHVideoViewController.h"

@interface SPHVideoViewController () 

@end

@implementation SPHVideoViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super initWithMediaType:MediaTypeVideo];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder MediaType:MediaTypeVideo];
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil MediaType:MediaTypeVideo];
    return self;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupVideoPlayer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //tbd
    [self clearPlayer];
}

#pragma mark - Draw & update methods

- (void)update
{
    if (self.videoPlayer) {
        [self setNewTextureFromVideoPlayer];
    }
}

#pragma mark - Video

- (void)setupVideoPlayer
{
    if (self.mediaType == MediaTypeVideo) {
        NSURL *urlToFile;
        if (self.streamURL) {
            urlToFile = self.streamURL;
        } else {
            urlToFile = [NSURL URLWithString:self.sourceVideoURL];
        }
        self.videoPlayer = [[SPHVideoPlayer alloc] initVideoPlayerWithURL:urlToFile];
        [self.videoPlayer prepareToPlay];
        self.videoPlayer.delegate = self;
    }
}

- (void)setNewTextureFromVideoPlayer
{
    if (self.videoPlayer) {
        if ([self.videoPlayer canProvideFrame]) {
            [self displayPixelBuffer:[self.videoPlayer getCurrentFramePicture]];
        }
    }
}

#pragma mark - SPHVideoPlayerDelegate

- (void)isReadyToPlay
{
    
}

- (void)progressDidUpdate:(CGFloat)progress
{
    self.playedProgress = progress;
}

- (void)progressTimeChanged:(CMTime)time
{
    
}

- (void)downloadingProgress:(CGFloat)progress
{
    NSLog(@"Downloaded - %f percentage", progress * 100);
    self.downloadedProgress = progress;
}

- (void)playerDidChangeProgressTime:(CGFloat)time totalTime:(CGFloat)totalDuration
{
    
}

#pragma mark - Player

- (void)playVideo
{
    if (![self isPlaying]) {
        [self.videoPlayer play];
        self.isPlaying = YES;
    }
}

- (void)pauseVideo
{
    if ([self isPlaying]) {
        [self.videoPlayer pause];
        self.isPlaying = NO;
    }
}

- (void)stopVideo
{
    if ([self isPlaying]) {
        [self.videoPlayer stop];
        self.isPlaying = NO;
    }
}

#pragma mark - Cleanup

- (void)clearPlayer
{
    [self.videoPlayer stop];
    self.videoPlayer.delegate = nil;
    self.videoPlayer = nil;
}

@end
