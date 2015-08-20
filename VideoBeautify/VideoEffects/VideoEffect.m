//
//  VideoEffect
//  From VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoEffect.h"
#import "VideoBuilder.h"
//#import "VideoThemes.h"
#import "CommonDefine.h"
//#import <AssetsLibrary/AssetsLibrary.h>

#pragma mark - Private
@interface VideoEffect()
{
    GPUImageMovie *_movieFile;
    GPUImageOutput<GPUImageInput> *_filter;
    GPUImageMovieWriter *_movieWriter;
    
    AVAssetExportSession *_exportSession;
    NSTimer *_timerFilter;
    NSTimer *_timerEffect;
    
    NSMutableDictionary *_themesDic;
    
    VideoBuilder *_videoBuilder;
}

@property (retain, nonatomic) VideoBuilder *videoBuilder;
@property (retain, nonatomic) NSMutableDictionary *themesDic;
@property (assign, nonatomic) id delegate;

@property (retain, nonatomic) GPUImageMovie *movieFile;
@property (retain, nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (retain, nonatomic) GPUImageMovieWriter *movieWriter;
@property (retain, nonatomic) AVAssetExportSession *exportSession;

@property (retain, nonatomic) NSTimer *timerFilter;
@property (retain, nonatomic) NSTimer *timerEffect;

@end


@implementation VideoEffect

@synthesize movieFile = _movieFile;
@synthesize filter = _filter;
@synthesize movieWriter = _movieWriter;
@synthesize exportSession = _exportSession;

@synthesize timerFilter = _timerFilter;
@synthesize timerEffect = _timerEffect;

@synthesize delegate = _delegate;
@synthesize themeCurrentType = _themeCurrentType;
@synthesize themesDic = _themesDic;
@synthesize videoBuilder = _videoBuilder;

#pragma mark - Init instance
- (id) initWithDelegate:(id)delegate
{
	if (self = [super init])
    {
        _delegate = delegate;
        _movieFile = nil;
        _filter = nil;
        _movieWriter = nil;
        _exportSession = nil;
        _timerFilter = nil;
        _timerEffect = nil;
        _themesDic = nil;
        
        // Default theme
        self.themeCurrentType = kThemeNone;
        
        _videoBuilder = [[VideoBuilder alloc] init];
	}
    
	return self;
}

- (void) clearAll
{
    if (_videoBuilder)
    {
        [_videoBuilder release];
        _videoBuilder = nil;
    }
    
    if (_movieFile)
    {
        [_movieFile release];
        _movieFile = nil;
    }
    
    if (_movieWriter)
    {
        [_movieWriter release];
        _movieWriter = nil;
    }
    
    if (_exportSession)
    {
        [_exportSession release];
        _exportSession = nil;
    }
    
    if (_timerFilter)
    {
        [_timerFilter invalidate];
        _timerFilter = nil;
    }
    
    if (_timerEffect) {
        [_timerEffect invalidate];
        _timerEffect = nil;
    }
    
//    if (_filter)
//    {
//        if ((NSNull*)_filter != [NSNull null])
//        {
//            [_filter removeAllTargets];
//        }
//
//        [_filter release];
//        _filter = nil;
//    }
    
//    if (_themesDic && [_themesDic count]>0)
//    {
//        [_themesDic removeAllObjects];
//        [_themesDic release];
//        _themesDic = nil;
//    }
    
}

- (void)dealloc
{
    [self clearAll];
    
    [super dealloc];
}

- (void) pause
{
    if (_movieFile.progress < 1.0)
    {
        [_movieWriter cancelRecording];
    }
    else if (_exportSession.progress < 1.0)
    {
        [_exportSession cancelExport];
    }
}

- (void) resume
{
    [self clearAll];
}

#pragma mark - Common function
//- (void) writeExportedVideoToAssetsLibrary:(NSString *)outputURL
//{
//	NSURL *exportURL = [NSURL fileURLWithPath:outputURL];
//	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL])
//    {
//		[library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error)
//         {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (error)
//                 {
//                     if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4ToAlbumStatusFailed:)])
//                     {
//                         [_delegate performSelector:@selector(AVAssetExportMP4ToAlbumStatusFailed:) withObject:nil];
//                     }
//                 }
//                 else
//                 {
//                     if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4ToAlbumStatusCompleted:)])
//                     {
//                         [_delegate performSelector:@selector(AVAssetExportMP4ToAlbumStatusCompleted:) withObject:nil];
//                     }
//                 }
//                 
//#if !TARGET_IPHONE_SIMULATOR
//                 [[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
//#endif
//             });
//         }];
//	}
//    else
//    {
//		NSLog(@"Video could not be exported to camera roll.");
//	}
//
//  [library release];
//}

#pragma mark - Build beautiful video
- (void) initializeVideo:(NSURL*) inputMovieURL fromSystemCamera:(BOOL)fromSystemCamera
{
    // 1.
    _movieFile = [[GPUImageMovie alloc] initWithURL:inputMovieURL];
    _movieFile.runBenchmark = NO;
    _movieFile.playAtActualSpeed = NO;

    // 2. Add filter effect
    _filter = nil;
    NSUInteger themesCount = [[[VideoThemesData sharedInstance] getThemeData] count];
    if (self.themeCurrentType != kThemeNone && themesCount >= self.themeCurrentType)
    {
        GPUImageOutput<GPUImageInput> *filterCurrent = [[[VideoThemesData sharedInstance] getThemeFilter:fromSystemCamera] objectForKey:[NSNumber numberWithInt:self.themeCurrentType]];
        _filter = filterCurrent;
    }

    // 3.
    if ((NSNull*)_filter != [NSNull null] && _filter != nil)
    {
        [_movieFile addTarget:_filter];

//        if (_delegate && [_delegate isKindOfClass:[UIViewController class]])
//        {
//            GPUImageView *filterView = (GPUImageView *)((UIViewController*)_delegate).view;
//            [_filter addTarget:filterView];
//        }
    }
//    else if (_delegate && [_delegate isKindOfClass:[UIViewController class]])
//    {
//        GPUImageView *filterView = (GPUImageView *)((UIViewController*)_delegate).view;
//        [_movieFile addTarget:filterView];
//    }
}

- (void) buildVideoBeautify:(NSString*)exportVideoFile inputVideoURL:(NSURL*)inputVideoURL fromSystemCamera:(BOOL)fromSystemCamera
{
    if (self.themeCurrentType == kThemeNone)
    {
        NSLog(@"Theme is empty!");

        return;
    }
    
    if (!inputVideoURL || ![inputVideoURL isFileURL])
    {
        NSLog(@"Input file is invalied! = %@", inputVideoURL);
        return;
    }
    
    // 1.
//    NSString *fileName = [inputVideoFile stringByDeletingPathExtension];
//    NSLog(@"%@",fileName);
//    NSString *fileExt = [inputVideoFile pathExtension];
//    NSLog(@"%@",fileExt);
//    NSURL *inputMovieURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileExt];
    
    self.themesDic = [[VideoThemesData sharedInstance] getThemeData];
    
    // 2.
    [self initializeVideo:inputVideoURL fromSystemCamera:fromSystemCamera];
    
    // 3. Movie output temp file
//    NSString *pathToTempMov = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/tempMovie.mov"];
    NSString *pathToTempMov = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempMovie.mov"];
    unlink([pathToTempMov UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *outputTempMovieURL = [NSURL fileURLWithPath:pathToTempMov];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputVideoURL options:nil];
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count <= 0)
    {
        NSLog(@"Video track is empty!");
        return;
    }
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // If this if from system camera, it will rotate 90c, and swap width and height
    CGSize sizeVideo = CGSizeMake(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
    if (fromSystemCamera)
    {
        sizeVideo = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    }
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:outputTempMovieURL size:sizeVideo];
    
    if ((NSNull*)_filter != [NSNull null] && _filter != nil)
    {
        [_filter addTarget:_movieWriter];
    }
    else
    {
        [_movieFile addTarget:_movieWriter];
    }
    
    // 4. Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    _movieWriter.shouldPassthroughAudio = YES;
    _movieFile.audioEncodingTarget = _movieWriter;
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];
    
    // 5.
    [_movieWriter startRecording];
    [_movieFile startProcessing];
    
    // 6. Progress monitor for filter
    _timerFilter = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                             target:self
                                           selector:@selector(retrievingProgress)
                                           userInfo:nil
                                            repeats:YES];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    // 7. Filter effect finished
    [weakSelf.movieWriter setCompletionBlock:^{
        
        if ((NSNull*)_filter != [NSNull null] && _filter != nil)
        {
            [_filter removeTarget:weakSelf.movieWriter];
        }
        else
        {
            [_movieFile removeTarget:weakSelf.movieWriter];
        }
        
        [_movieWriter finishRecordingWithCompletionHandler:^{
            
            // Closer timer
            [_timerFilter invalidate];
            _timerFilter = nil;
            
            unlink([exportVideoFile UTF8String]);

            // Mov convert to mp4 (Add animation and music effect)
            NSURL *inputVideoURL = outputTempMovieURL;
            if (![self buildVideoEffectsToMP4:exportVideoFile inputVideoURL:inputVideoURL])
            {
                NSLog(@"Convert to mp4 file failed");
            }
            else
            {
                
            }
        }];
        
    }];
    
    // 8. Filter effect failed
    [weakSelf.movieWriter  setFailureBlock: ^(NSError* error){
        
        if ((NSNull*)_filter != [NSNull null] && _filter != nil)
        {
            [_filter removeTarget:weakSelf.movieWriter];
        }
        else
        {
            [_movieFile removeTarget:weakSelf.movieWriter];
        }
        
        [_movieWriter finishRecordingWithCompletionHandler:^{
            
            // Closer timer
            [_timerFilter invalidate];
            _timerFilter = nil;
            
            // Mov convert to mp4 (Add animation and music effect)
            unlink([exportVideoFile UTF8String]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusFailed:)])
                {
                    [_delegate performSelector:@selector(AVAssetExportMP4SessionStatusFailed:) withObject:nil];
                }
                
            });
            
            NSLog(@"Add filter effect failed! - %@", error.description);
            return;

        }];
        
     }];
}
                           
// Convert 'space' char
-(NSString *)returnFormatString:(NSString *)str
{
    return [str stringByReplacingOccurrencesOfString:@" " withString:@" "];
}
                       
// Add animation and music effect
- (BOOL)buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoURL:(NSURL *)inputVideoURL
{
    // 1.
    if (!inputVideoURL || ![inputVideoURL isFileURL] || !exportVideoFile || [exportVideoFile isEqualToString:@""])
    {
        NSLog(@"Input filename or Output filename is invalied for convert to Mp4!");
        return NO;
    }
    
//    if (![[NSFileManager defaultManager] fileExistsAtPath:[inputVideoURL absoluteString]])
//    {
//        NSLog(@"Input file hasn't exist in directory for convert to Mp4!");
//        return NO;
//    }
    
    // 2. Create the composition and tracks
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
    NSParameterAssert(asset);
    if(asset ==nil || [[asset tracksWithMediaType:AVMediaTypeVideo] count]<1)
    {
        NSLog(@"Input video is invalid!");
        [asset release];
        return NO;
    }
   
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count <= 0)
    {
        // Retry once
        if (asset)
        {
            [asset release];
            asset = nil;
        }
        
        asset = [[AVURLAsset alloc] initWithURL:inputVideoURL options:nil];
        assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ([assetVideoTracks count] <= 0)
        {
            if (asset)
            {
                [asset release];
                asset = nil;
            }
            
            NSLog(@"Error reading the transformed video track");
            return NO;
        }
    }
    
    // 3. Insert the tracks in the composition's tracks
    AVAssetTrack *assetVideoTrack = [assetVideoTracks firstObject];
    [videoTrack insertTimeRange:assetVideoTrack.timeRange ofTrack:assetVideoTrack atTime:CMTimeMake(0, 1) error:nil];
    [videoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0)
    {
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [audioTrack insertTimeRange:assetAudioTrack.timeRange ofTrack:assetAudioTrack atTime:CMTimeMake(0, 1) error:nil];
    }
    else
    {
         NSLog(@"Reminder: video hasn't audio!");
    }
    
    // 4. Effects
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    videoLayer.frame = CGRectMake(0, 0, assetVideoTrack.naturalSize.width, assetVideoTrack.naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    
    VideoThemes *themeCurrent = nil;
    if (self.themeCurrentType != kThemeNone && [self.themesDic count] >= self.themeCurrentType)
    {
        themeCurrent = [self.themesDic objectForKey:[NSNumber numberWithInt:self.themeCurrentType]];
    }
    
    // Animation effects
    NSMutableArray *animatedLayers = [[NSMutableArray alloc] init];
    if (themeCurrent && [[themeCurrent animationActions] count]>0)
    {
        for (NSNumber *animationAction in [themeCurrent animationActions])
        {
            CALayer *animatedLayer = nil;
            switch ([animationAction intValue])
            {
                case kAnimationFireworks:
                {
                    animatedLayer = [_videoBuilder buildEmitterFireworks:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSnow:
                {
                    animatedLayer = [_videoBuilder buildEmitterSnow:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSnow2:
                {
                    animatedLayer = [_videoBuilder buildEmitterSnow2:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationHeart:
                {
                    animatedLayer = [_videoBuilder buildEmitterHeart:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationRing:
                {
                    animatedLayer = [_videoBuilder buildEmitterRing:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationStar:
                {
                    animatedLayer = [_videoBuilder buildEmitterStar:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationMoveDot:
                {
                    animatedLayer = [_videoBuilder buildEmitterMoveDot:assetVideoTrack.naturalSize position:CGPointMake(160, 240)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextSparkle:
                {
                    if (!isStringEmpty(themeCurrent.textSparkle))
                    {
                        animatedLayer = [_videoBuilder buildEmitterSparkle:assetVideoTrack.naturalSize text:themeCurrent.textSparkle startTime:1.0];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationTextStar:
                {
                    if (!isStringEmpty(themeCurrent.textStar))
                    {
                        animatedLayer = [_videoBuilder buildAnimationStarText:assetVideoTrack.naturalSize text:themeCurrent.textStar];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationSky:
                {
                    animatedLayer = [_videoBuilder buildEmitterSky:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationMeteor:
                {
                    NSTimeInterval timeInterval = 0.1;
                    for (int i=0; i<2; ++i)
                    {
                        animatedLayer = [_videoBuilder buildEmitterMeteor:assetVideoTrack.naturalSize startTime:timeInterval pathN:i];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationRain:
                {
                    animatedLayer = [_videoBuilder buildEmitterRain:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationFlower:
                {
                    animatedLayer = [_videoBuilder buildEmitterFlower:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationFire:
                {
                    if (!isStringEmpty(themeCurrent.imageFile))
                    {
                        UIImage *image = [UIImage imageNamed:themeCurrent.imageFile];
                        animatedLayer = [_videoBuilder buildEmitterFire:assetVideoTrack.naturalSize position:CGPointMake(assetVideoTrack.naturalSize.width/2.0, image.size.height+10)];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    break;
                }
                case kAnimationSmoke:
                {
                    animatedLayer = [_videoBuilder buildEmitterSmoke:assetVideoTrack.naturalSize position:CGPointMake(assetVideoTrack.naturalSize.width/2.0, 105)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSpark:
                {
                    animatedLayer = [_videoBuilder buildEmitterSpark:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationBirthday:
                {
                    animatedLayer = [_videoBuilder buildEmitterBirthday:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationImage:
                {
                    if (!isStringEmpty(themeCurrent.imageFile))
                    {
                        UIImage *image = [UIImage imageNamed:themeCurrent.imageFile];
                        animatedLayer = [_videoBuilder buildImage:assetVideoTrack.naturalSize image:themeCurrent.imageFile position:CGPointMake(assetVideoTrack.naturalSize.width/2, image.size.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationImageArray:
                {
                    if(themeCurrent.animationImages)
                    {
                        UIImage *image = [UIImage imageWithCGImage:(CGImageRef)themeCurrent.animationImages[0]];
                        animatedLayer = [_videoBuilder buildAnimationImages:assetVideoTrack.naturalSize imagesArray:themeCurrent.animationImages position:CGPointMake(assetVideoTrack.naturalSize.width/2, image.size.height/2)];
                        
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationVideoFrame:
                {
                    if (themeCurrent.keyFrameTimes  && [[themeCurrent keyFrameTimes] count]>0)
                    {
                        for (NSNumber *timeSecond in themeCurrent.keyFrameTimes)
                        {
                            CMTime time = CMTimeMake([timeSecond doubleValue], 1);
                            if (CMTIME_COMPARE_INLINE([asset duration], >, time))
                            {
                                animatedLayer = [_videoBuilder buildVideoFrameImage:assetVideoTrack.naturalSize videoFile:inputVideoURL startTime:time];
                                if (animatedLayer)
                                {
                                    [animatedLayers addObject:(id)animatedLayer];
                                }
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationSpotlight:
                {
                    animatedLayer = [_videoBuilder buildSpotlight:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationScrollScreen:
                {
                    animatedLayer = [_videoBuilder buildAnimationScrollScreen:assetVideoTrack.naturalSize];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextScroll:
                {
                    if (themeCurrent.scrollText && [[themeCurrent scrollText] count] > 0)
                    {
                        NSArray *startYPoints = [NSArray arrayWithObjects:[NSNumber numberWithFloat:assetVideoTrack.naturalSize.height/3], [NSNumber numberWithFloat:assetVideoTrack.naturalSize.height/2], [NSNumber numberWithFloat:assetVideoTrack.naturalSize.height*2/3], nil];
                        
                        NSTimeInterval timeInterval = 0.0;
                        for (NSString *text in themeCurrent.scrollText)
                        {
                            animatedLayer = [_videoBuilder buildAnimatedScrollText:assetVideoTrack.naturalSize text:text startPoint:CGPointMake(assetVideoTrack.naturalSize.width, [startYPoints[arc4random()%(int)3] floatValue]) startTime:timeInterval];
                            
                            if (animatedLayer)
                            {
                                [animatedLayers addObject:(id)animatedLayer];
                                
                                timeInterval += 2.0;
                            }
                        }
                    }
                    
                    break;
                }
                case kAnimationBlackWhiteDot:
                {
                    for (int i=0; i<2; ++i)
                    {
                        animatedLayer = [_videoBuilder buildEmitterBlackWhiteDot:assetVideoTrack.naturalSize positon:CGPointMake(assetVideoTrack.naturalSize.width/2, i*assetVideoTrack.naturalSize.height) startTime:2.0f];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationScrollLine:
                {
                    animatedLayer = [_videoBuilder buildAnimatedScrollLine:assetVideoTrack.naturalSize startTime:1 lineHeight:30.0f image:nil];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationRipple:
                {
                    NSTimeInterval timeInterval = 1.0;
                    animatedLayer = [_videoBuilder buildAnimationRipple:assetVideoTrack.naturalSize centerPoint:CGPointMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height/2) radius:assetVideoTrack.naturalSize.width/2 startTime:timeInterval];
                    
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationSteam:
                {
                    animatedLayer = [_videoBuilder buildEmitterSteam:assetVideoTrack.naturalSize positon:CGPointMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height - assetVideoTrack.naturalSize.height/8)];
                    if (animatedLayer)
                    {
                        [animatedLayers addObject:(id)animatedLayer];
                    }
                    
                    break;
                }
                case kAnimationTextGradient:
                {
                    if (!isStringEmpty(themeCurrent.textGradient))
                    {
                        animatedLayer = [_videoBuilder buildGradientText:assetVideoTrack.naturalSize positon:CGPointMake(assetVideoTrack.naturalSize.width/2, assetVideoTrack.naturalSize.height - assetVideoTrack.naturalSize.height/4) text:themeCurrent.textGradient];
                        if (animatedLayer)
                        {
                            [animatedLayers addObject:(id)animatedLayer];
                        }
                    }
                    
                    break;
                }
                case kAnimationFlashScreen:
                {
                    for (int timeSecond=2; timeSecond<12; timeSecond+=3)
                    {
                        CMTime time = CMTimeMake(timeSecond, 1);
                        if (CMTIME_COMPARE_INLINE([asset duration], >, time))
                        {
                            animatedLayer = [_videoBuilder buildAnimationFlashScreen:assetVideoTrack.naturalSize startTime:timeSecond startOpacity:TRUE];
                            if (animatedLayer)
                            {
                                [animatedLayers addObject:(id)animatedLayer];
                            }
                        }
                    }
                    
                    break;
                }
                default:
                    break;
            }
        }
        
        if (animatedLayers && [animatedLayers count] > 0)
        {
            for (CALayer *animatedLayer in animatedLayers)
            {
                [parentLayer addSublayer:animatedLayer];
            }
        }
    }
    
    // Make a "pass through video track" video composition.
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
    
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
    passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
    
    // Fixing orientation
//    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
//    
//    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:assetVideoTrack];
//    
//    UIImageOrientation FirstAssetOrientation_  = UIImageOrientationUp;
//    BOOL  isFirstAssetPortrait_  = NO;
//    CGAffineTransform firstTransform = assetVideoTrack.preferredTransform;
//    
//    if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)
//    {
//        FirstAssetOrientation_= UIImageOrientationRight;
//        isFirstAssetPortrait_ = YES;
//    }
//    else if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)
//    {
//        FirstAssetOrientation_ =  UIImageOrientationLeft;
//        isFirstAssetPortrait_ = YES;
//    }
//    else if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)
//    {
//        FirstAssetOrientation_ =  UIImageOrientationUp;
//    }
//    else if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0)
//    {
//        FirstAssetOrientation_ = UIImageOrientationDown;
//    }
//    
//    CGFloat FirstAssetScaleToFitRatio = 480/assetVideoTrack.naturalSize.width;
//    if(isFirstAssetPortrait_)
//    {
//        FirstAssetScaleToFitRatio = 480/assetVideoTrack.naturalSize.height;
//        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
//        [FirstlayerInstruction setTransform:CGAffineTransformConcat(assetVideoTrack.preferredTransform, FirstAssetScaleFactor) atTime:kCMTimeZero];
//    }
//    else
//    {
//        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
//        [FirstlayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(assetVideoTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 20)) atTime:kCMTimeZero];
//    }
//    
//    [FirstlayerInstruction setOpacity:0.0 atTime:asset.duration];
//    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction, nil];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = [NSArray arrayWithObject:passThroughInstruction];
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
    videoComposition.renderSize =  assetVideoTrack.naturalSize;
    
    if (animatedLayers)
    {
        [animatedLayers removeAllObjects];
        [animatedLayers release];
        animatedLayers = nil;
    }
    
    // 5. Music effect
    AVMutableAudioMix *audioMix = nil;
    if (themeCurrent && !isStringEmpty(themeCurrent.bgMusicFile))
    {
        NSString *fileName = [themeCurrent.bgMusicFile stringByDeletingPathExtension];
        NSLog(@"%@",fileName);
        
        NSString *fileExt = [themeCurrent.bgMusicFile pathExtension];
        NSLog(@"%@",fileExt);
        
        NSURL *bgMusicURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:fileExt];
        AVURLAsset *assetMusic = [[AVURLAsset alloc] initWithURL:bgMusicURL options:nil];
        _videoBuilder.commentary = assetMusic;
        audioMix = [AVMutableAudioMix audioMix];
        [_videoBuilder addCommentaryTrackToComposition:composition withAudioMix:audioMix];
        
        if (assetMusic)
        {
            [assetMusic release];
            assetMusic = nil;
        }
    }
    
    // 6. Export to mp4 （Attention: iOS 5.0不支持导出MP4，会crash）
    NSString *mp4Quality = AVAssetExportPresetMediumQuality; //AVAssetExportPresetPassthrough
    NSString *exportPath = exportVideoFile;
    NSURL *exportUrl = [NSURL fileURLWithPath:[self returnFormatString:exportPath]];
    
    _exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:mp4Quality];
    _exportSession.outputURL = exportUrl;
    _exportSession.outputFileType = [[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0 ? AVFileTypeMPEG4 : AVFileTypeQuickTimeMovie;
    
    _exportSession.shouldOptimizeForNetworkUse = YES;
    
    if (audioMix)
    {
        _exportSession.audioMix = audioMix;
    }
    
    if (videoComposition)
    {
        _exportSession.videoComposition = videoComposition;
    }
    
    // 6.1
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor for effect
        _timerEffect = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                 target:self
                                               selector:@selector(retrievingProgressMP4)
                                               userInfo:nil
                                                repeats:YES];
    });
    
    
    // 7. Success status
    [_exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([_exportSession status])
        {
            case AVAssetExportSessionStatusCompleted:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    [_timerEffect invalidate];
                    _timerEffect = nil;
                    
                    NSLog(@"MP4 Successful!");
                    
                    if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusCompleted:)])
                    {
                        [_delegate performSelector:@selector(AVAssetExportMP4SessionStatusCompleted:) withObject:nil];
                    }

                    NSLog(@"Output Mp4 is %@", exportVideoFile);
                    
                    // Write to photo album
//                    [self writeExportedVideoToAssetsLibrary:exportVideoFile];
                });
                
                break;
            }
            case AVAssetExportSessionStatusFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Close timer
                    [_timerEffect invalidate];
                    _timerEffect = nil;
                    
                    if (_delegate && [_delegate respondsToSelector:@selector(AVAssetExportMP4SessionStatusFailed:)])
                    {
                        [_delegate performSelector:@selector(AVAssetExportMP4SessionStatusFailed:) withObject:nil];
                    }
                    
                });
                
                NSLog(@"Export failed: %@", [[_exportSession error] localizedDescription]);
                
                break;
            }
            case AVAssetExportSessionStatusCancelled:
            {
                NSLog(@"Export canceled");
                break;
            }
            case AVAssetExportSessionStatusWaiting:
            {
                NSLog(@"Export Waiting");
                break;
            }
            case AVAssetExportSessionStatusExporting:
            {
                NSLog(@"Export Exporting");
                break;
            }
            default:
                break;
        }
        
        [_exportSession release];
        _exportSession = nil;
        
        if (asset)
        {
            [asset release];
        }
    }];
    
    return YES;
}

- (void)retrievingProgress
{
    if (_delegate && [_delegate respondsToSelector:@selector(retrievingProgressFilter:)])
    {
        [_delegate performSelector:@selector(retrievingProgressFilter:) withObject:[NSNumber numberWithFloat:_movieFile.progress]];
        
//             NSLog(@"Filter Progress: %f", movieFile.progress);
    }
}

- (void)retrievingProgressMP4
{
    if (_exportSession)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(retrievingProgressMP4:)])
        {
            [_delegate performSelector:@selector(retrievingProgressMP4:) withObject:[NSNumber numberWithFloat:_exportSession.progress]];
            
//            NSLog(@"Effect Progress: %f", exportSession.progress);
        }
    }
    
}

@end
