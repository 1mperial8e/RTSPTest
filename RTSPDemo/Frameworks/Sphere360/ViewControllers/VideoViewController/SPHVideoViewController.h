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

@interface SPHVideoViewController : SPHBaseViewController <SPHVideoPlayerDelegate>

@property (strong, nonatomic) SPHVideoPlayer *videoPlayer;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) CGFloat playedProgress;
@property (assign, nonatomic) CGFloat downloadedProgress;

@property (strong, nonatomic) NSURL *streamURL;

- (void)playVideo;
- (void)pauseVideo;
- (void)stopVideo;

@end
