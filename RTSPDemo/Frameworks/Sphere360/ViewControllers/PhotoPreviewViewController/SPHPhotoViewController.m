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

#import "SPHPhotoViewController.h"

@interface SPHPhotoViewController ()

@end

@implementation SPHPhotoViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super initWithMediaType:MediaTypePhoto];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder MediaType:MediaTypePhoto];
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil MediaType:MediaTypePhoto];
    return self;
}

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self applyImageTexture];
}

#pragma mark - Override

- (void)applyImageTexture
{
    [super applyImageTexture];
    [self setupTextureWithImage:self.sourceImage.CGImage];
}

@end