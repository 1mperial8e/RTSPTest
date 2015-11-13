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
#import "SPHGLProgram.h"
#import "SPHTextureProvider.h"

//models
#import "SPHSphericalModel.h"
#import "SPHPlanarModel.h"
#import "SPHLittlePlanetModel.h"
#import "SPHCubicModel.h"

#import "Sphere.h"
#import "PanoramaView.h"
#import "CubicModel.h"

// libraries
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

enum {
    UNIFORM_MVPMATRIX,
    UNIFORM_MVPMATRIX_INFINITE,
    UNIFORM_SAMPLER,
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

static const GLfloat kColorConversion709[] = {
    1.1643,  0.0000,  1.2802,
    1.1643, -0.2148, -0.3806,
    1.1643,  2.1280,  0.0000
};

@interface SPHBaseViewController ()<AVAssetResourceLoaderDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate> {
    GLuint _vertexArrayID;
    GLuint _vertexBufferID;
    GLuint _vertexTexCoordID;
    
    GLuint _vertexTexCoordAttributeIndex;
    GLuint texturePointer;
    
    const GLfloat *_preferredConversion;

    // for video
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
}

@property (strong, nonatomic) GLKView *glView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIPinchGestureRecognizer *zoomGesture;

@property (strong, nonatomic) SPHGLProgram *program;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, atomic) GLKTextureInfo *texture;
@property (strong, atomic) GLKTextureLoader *textureloader;

@property (assign, nonatomic) CGPoint prevTouchPoint;

@property (strong, nonatomic) NSTimer *updateTimer;

@property (strong, nonatomic) SPHBaseModel *model;

@end

@implementation SPHBaseViewController

#pragma mark - Init

- (instancetype)initWithCoder:(NSCoder *)aDecoder MediaType:(MediaType)mediaType
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _mediaType = mediaType;
    }
    return self;
}

- (instancetype)initWithMediaType:(MediaType)mediaType
{
    self = [super init];
    if (self) {
        _mediaType = mediaType;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MediaType:(MediaType)mediaType
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mediaType = mediaType;
    }
    return self;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupContext];
    [self setupGlView];
    
    _viewModel = SphericalModel;
    [self loadModel:self.viewModel];
    [self addGestures];
    
    [self setupTextureLoader];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self setupGL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startUpdatesTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.viewModel != PlanarModel) {
        self.zoomGesture.enabled = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.updateTimer invalidate];
}

- (void)dealloc
{
    [self tearDownGL];
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    __block CGRect frame = self.view.bounds;
    __block CGFloat scale = self.scrollView.zoomScale;
    __weak typeof(self) weakSelf = self;
    
    if (!(UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation))) {
        frame.size = CGSizeMake(frame.size.height, frame.size.width);
    }
    self.scrollView.zoomScale = 1.0f;
    [UIView animateWithDuration:0.3f animations:^{
        weakSelf.glView.frame = frame;
    } completion:^(BOOL finished) {
        if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            [weakSelf.scrollView setZoomScale:scale animated:YES];
        } else if (finished) {
            [weakSelf.scrollView setZoomScale:scale animated:YES];
        }
    }];
}

#pragma mark - Model

- (void)switchToModel:(SPHViewModel)model
{
    if (_viewModel != model) {
        _viewModel = model;
        [self loadModel:model];
    }
}

- (void)loadModel:(SPHViewModel)model
{
    self.scrollView.zoomScale = 1.0f;
    self.scrollView.scrollEnabled = NO;
    self.zoomGesture.enabled = NO;
    
    CGFloat angle = self.model.angle;
    CGFloat near = self.model.near;

    switch (model) {
        case SphericalModel: {
            self.model = [[SPHSphericalModel alloc] initWithViewController:self GLView:self.glView];
            break;
        }
        case PlanarModel: {
//            self.scrollView.scrollEnabled = YES;
//            self.zoomGesture.enabled = YES;
            self.model = [[SPHPlanarModel alloc] initWithViewController:self GLView:self.glView];
            break;
        }
        case LittlePlanetModel: {
            self.model = [[SPHLittlePlanetModel alloc] initWithViewController:self GLView:self.glView];
            break;
        }
        case CubicModel: {
            self.model = [[SPHCubicModel alloc] initWithViewController:self GLView:self.glView];
            break;
        }
    }
    
    self.model.angle = angle;
    self.model.near = near;
    
    [self bindBuffer];
}

#pragma mark - Gyroscope

- (void)setGyroscopeActive:(BOOL)active
{
    self.model.gyroscopeActive = active;
}

- (BOOL)isGyroscopeActive
{
    return self.model.gyroscopeActive;
}

- (BOOL)isGyroscopeEnabled
{
    return [self.model isGyroscopeEnabled];
}

#pragma mark - OpenGL Setup

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    [self buildProgram];
    
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    glDisable(GL_CULL_FACE);
    glGenVertexArraysOES(1, &_vertexArrayID);
    glBindVertexArrayOES(_vertexArrayID);
    
    [self bindBuffer];
    
    if (self.mediaType == MediaTypeVideo && !_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

- (void)bindBuffer
{
    if (self.viewModel == PlanarModel) {
        [self bindPlanarBuffer];
    } else if (self.viewModel == CubicModel) {
        [self bindCubicBuffer];

    } else {
        [self bindSphericalBuffer];
    }
}

- (void)bindSphericalBuffer
{
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SphereVerts), SphereVerts, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 3, NULL);
    
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SphereTexCoords), SphereTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(_vertexTexCoordAttributeIndex);
    glVertexAttribPointer(_vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, NULL);
}

- (void)bindPlanarBuffer
{
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(PanoramaViewVerts), PanoramaViewVerts, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 3, NULL);
    
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(PanoramaViewTexCoords), PanoramaViewTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(_vertexTexCoordAttributeIndex);
    glVertexAttribPointer(_vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, NULL);
}

- (void)bindCubicBuffer
{
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(CubicModelVerts), CubicModelVerts, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 3, NULL);
    
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, sizeof(CubicModelTexCoords), CubicModelTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(_vertexTexCoordAttributeIndex);
    glVertexAttribPointer(_vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, NULL);
}

- (void)buildProgram
{
    if (self.mediaType == MediaTypePhoto) {
        _program = [[SPHGLProgram alloc] initWithVertexShaderFilename:@"Shader" fragmentShaderFilename:@"Shader"];
    } else if (self.mediaType == MediaTypeVideo) {
        _program = [[SPHGLProgram alloc] initWithVertexShaderFilename:@"Shader" fragmentShaderFilename:@"ShaderVideo"];
    }
    [_program addAttribute:@"a_position"];
    [_program addAttribute:@"a_textureCoord"];
    if (![_program link])
    {
        NSString *programLog = [_program programLog];
        NSLog(@"Program link log: %@", programLog);
        NSString *fragmentLog = [_program fragmentShaderLog];
        NSLog(@"Fragment shader compile log: %@", fragmentLog);
        NSString *vertexLog = [_program vertexShaderLog];
        NSLog(@"Vertex shader compile log: %@", vertexLog);
        _program = nil;
        NSAssert(NO, @"Falied to link Spherical shaders");
    }
    _vertexTexCoordAttributeIndex = [_program attributeIndex:@"a_textureCoord"];
    
    uniforms[UNIFORM_MVPMATRIX_INFINITE] = [_program uniformIndex:@"u_modelViewProjectionMatrix"];

    uniforms[UNIFORM_MVPMATRIX] = [_program uniformIndex:@"u_modelViewProjectionMatrix"];
    if (self.mediaType == MediaTypePhoto) {
        uniforms[UNIFORM_SAMPLER] = [_program uniformIndex:@"u_Sampler"];
    } else if (self.mediaType == MediaTypeVideo) {
        uniforms[UNIFORM_UV] = [_program uniformIndex:@"SamplerUV"];
        uniforms[UNIFORM_Y] = [_program uniformIndex:@"SamplerY"];
        uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = [_program uniformIndex:@"colorConversionMatrix"];
    }
}

- (void)setupContext
{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    _preferredConversion = kColorConversion709;
}

- (void)setupTextureLoader
{
    self.textureloader = [[GLKTextureLoader alloc] initWithSharegroup:self.context.sharegroup];
}

- (void)startUpdatesTimer
{
    // 60 times per second call updates
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.f
                                                        target:self
                                                      selector:@selector(updateView:)
                                                      userInfo:nil
                                                       repeats:YES];
}

#pragma mark - Textures

- (void)applyImageTexture
{
    //dummy
}

- (void)setupTextureWithImage:(CGImageRef)image
{
    if (!image) {
        return;
    }
    
    [self.textureloader textureWithCGImage:image options:nil queue:NULL completionHandler:^(GLKTextureInfo *textureInfo, NSError *outError) {
        if (outError){
            NSLog(@"GL Error = %u", glGetError());
        } else {
            if (_texture.name) {
                GLuint textureName = _texture.name;
                glDeleteTextures(1, &textureName);
            }
            _texture = textureInfo;
            if (!self.sourceImage) {
                CFRelease(image);
            }
        }
    }];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self update];
    [self.model update];
    [_program use];
    [self drawArraysGL];
    [self.glView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

#pragma mark - GLUpdates

- (void)updateView:(NSTimer *)timer
{
    [self.glView display];
}

- (void)update
{
    // for subclassing
}

- (void)drawArraysGL
{
    if (self.mediaType == MediaTypePhoto) {
        glBindVertexArrayOES(_vertexArrayID);
    }
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBlendFunc(GL_ONE, GL_ZERO);
    glUniformMatrix4fv(uniforms[UNIFORM_MVPMATRIX], 1, 0, self.model.modelViewProjectionMatrix.m);

    if (self.mediaType == MediaTypePhoto && _texture) {
        glBindTexture(GL_TEXTURE_2D, _texture.name);
    } else {
        glUniform1i(uniforms[UNIFORM_Y], 0);
        glUniform1i(uniforms[UNIFORM_UV], 1);
    }
    if (self.viewModel == PlanarModel) {
        glDrawArrays(GL_TRIANGLES, 0, PanoramaViewNumVerts);
        
        glUniformMatrix4fv(uniforms[UNIFORM_MVPMATRIX], 1, 0, self.model.modelViewProjectionMatrixInfinite.m);
        glDrawArrays(GL_TRIANGLES, 0, PanoramaViewNumVerts);

    } else if (self.viewModel == CubicModel) {
        glDrawArrays(GL_TRIANGLES, 0, CubicModelNumVerts);
    } else {
        glDrawArrays(GL_TRIANGLES, 0, SphereNumVerts);
    }
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVReturn err;
    if (pixelBuffer != NULL) {
        int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!_videoTextureCache) {
            NSLog(@"No video texture cache");
            return;
        }
        [self cleanUpTextures];
        
        //Create Y and UV textures from the pixel buffer. These textures will be drawn on the frame buffer
        
        //Y-plane.
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL,  GL_TEXTURE_2D, GL_LUMINANCE, frameWidth, frameHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &_lumaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, frameWidth / 2, frameHeight / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glEnableVertexAttribArray(_vertexBufferID);
        glBindFramebuffer(GL_FRAMEBUFFER, _vertexBufferID);
        
        CFRelease(pixelBuffer);
        
        glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    }
}

#pragma mark - GestureActions

- (void)pinchForZoom:(UIPinchGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.model.isZooming = YES;
        gesture.scale = self.model.zoomValue;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat zoom = gesture.scale;
        zoom = MAX(MIN(zoom, self.model.maxZoomValue * 1.1), self.model.minZoomValue * 0.9);
        self.model.zoomValue = zoom;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.model.isZooming = NO;
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)panGesture
{
    CGPoint currentPoint = [panGesture locationInView:panGesture.view];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateEnded: {
            self.model.velocity = [panGesture velocityInView:panGesture.view];
            break;
        }
        case UIGestureRecognizerStateBegan: {
            self.prevTouchPoint = currentPoint;
            [self disableExtraMovement];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self.model moveToPointX:(currentPoint.x - self.prevTouchPoint.x)
                           andPointY:(currentPoint.y - self.prevTouchPoint.y)];
            self.prevTouchPoint = currentPoint;
            break;
        }
        default:
            break;
    }
}

#pragma mark - Velocity

- (void)disableExtraMovement
{
    self.model.velocity = CGPointZero;
}

#pragma mark - Private

- (void)setupGlView
{
    CGRect viewFrame = self.view.frame;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && [[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        viewFrame.size = CGSizeMake(viewFrame.size.height, viewFrame.size.width);
    }
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:viewFrame];
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.maximumZoomScale = 2.5f;
    scrollView.minimumZoomScale = 1.0f;
    scrollView.delegate = self;

    self.scrollView = scrollView;
    self.zoomGesture = scrollView.pinchGestureRecognizer;

    [self.view insertSubview:scrollView atIndex:0];
    [self addConstraintsForView:scrollView toView:self.view];

    self.glView = [[GLKView alloc] initWithFrame:viewFrame context:self.context];
    self.glView.delegate = (id)self;
    [scrollView addSubview:self.glView];
}

- (void)addGestures
{
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchForZoom:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
}

#pragma mark - Cleanup

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBufferID);
    glDeleteVertexArraysOES(1, &_vertexArrayID);
    glDeleteBuffers(1, &_vertexTexCoordID);
    _program = nil;
    if (_texture.name) {
        GLuint textureName = _texture.name;
        glDeleteTextures(1, &textureName);
    }
    _texture = nil;
}

- (void)cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.glView;
}

#pragma mark - Constraints

- (void)addConstraintsForView:(UIView *)firstItem toView:(UIView *)secondItem
{
    [secondItem addConstraints:@[[NSLayoutConstraint constraintWithItem:firstItem
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:secondItem
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0
                                                             constant:0],
                                 [NSLayoutConstraint constraintWithItem:firstItem
                                                             attribute:NSLayoutAttributeLeft
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:secondItem
                                                             attribute:NSLayoutAttributeLeft
                                                            multiplier:1.0
                                                              constant:0],
                                 [NSLayoutConstraint constraintWithItem:firstItem
                                                               attribute:NSLayoutAttributeRight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:secondItem
                                                               attribute:NSLayoutAttributeRight
                                                              multiplier:1.0
                                                                constant:0],
                                 [NSLayoutConstraint constraintWithItem:firstItem
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:secondItem
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0]]];
}

@end
