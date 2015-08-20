//
//  NTViewController.m
//  GPUImageVideoStitchRec
//
//  Created by Nao Tokui on 6/16/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import "VideoRecordViewController.h"
//#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoClip.h"
#import "RecProgressView.h"
#import "JZViewController.h"

@interface NTViewController ()

@property (assign, nonatomic) id delegate;

@end

@implementation NTViewController
{
    GPUImageVideoCamera     *videoCamera;
    GPUImageView            *videoView;
    GPUImageMovieWriter     *movieWriter;
    NTRecProgressView       *progressView;
    
    NTVideoComposition      *composition;
    NTVideoClip             *videoTake;
    NSURL *movieURL;
    
    UILabel *tapRecordLabel;
    UIButton *removeButton;
    UIButton *doneButton;
}

@synthesize delegate = _delegate;
@synthesize outputFileUrl = _outputFileUrl;

- (id) initWithDelegate:(id)delegate
{
	if (self = [super init])
    {
        _delegate = delegate;
        
        videoCamera = nil;
        videoView = nil;
        movieWriter = nil;
        composition = nil;
        videoTake = nil;
        movieURL = nil;
        progressView = nil;
	}
    
	return self;
}

- (void)loadView
{
    [super loadView];
    
    // Camera
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    // Preview view
    videoView = [[GPUImageView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    videoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view insertSubview: videoView atIndex: 0];
    
    // Progress View
    progressView = [[NTRecProgressView alloc] initWithFrame: CGRectMake(0, 120, 320, 15)];
    [videoView addSubview: progressView];
    
    // Label 'tap & hold to record'
    tapRecordLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+self.view.frame.size.height/2)];
    tapRecordLabel.text = @"tap & hold to record";
    tapRecordLabel.textColor = [UIColor colorWithRed:155/255.0f green:188/255.0f blue:220/255.0f alpha:1];
    tapRecordLabel.font = [UIFont boldSystemFontOfSize:22];
    tapRecordLabel.textAlignment = NSTextAlignmentCenter;
    [videoView addSubview: tapRecordLabel];
    
    // Button 'remove'
    removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    removeButton.frame = CGRectMake(10, progressView.frame.origin.y-50, 50, 50);
    [removeButton setImage:[UIImage imageNamed:@"cancel_up"] forState:UIControlStateNormal];
    [removeButton setImage:[UIImage imageNamed:@"cancel_down"] forState:UIControlStateSelected];
    [removeButton addTarget:self action:@selector(removeLastTake) forControlEvents:UIControlEventTouchUpInside];
    [videoView addSubview:removeButton];
    
    // Button 'done'
    doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.frame = CGRectMake(progressView.frame.size.width-55, progressView.frame.origin.y-50, 50, 50);
    [doneButton setImage:[UIImage imageNamed:@"continue_up"] forState:UIControlStateNormal];
    [doneButton setImage:[UIImage imageNamed:@"continue_down"] forState:UIControlStateSelected];
    [doneButton addTarget:self action:@selector(stopRecording) forControlEvents:UIControlEventTouchUpInside];
    [videoView addSubview:doneButton];
    
    
    // Tap Gesture
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(longPressGestureRecognized:)];
    gesture.minimumPressDuration = 0.25;
    [videoView addGestureRecognizer: gesture];
    
    // Setting
    [videoCamera addTarget: videoView];
    [videoCamera startCameraCapture];
    
    // Video composition
    composition = [[NTVideoComposition alloc] initWithDelegate:self];
    progressView.composition = composition;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
//    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewDidUnload
{
    progressView.composition = nil;
    progressView = nil;
    videoView = nil;
    tapRecordLabel = nil;
    removeButton = nil;
    doneButton = nil;
    
    videoCamera = nil;
    movieWriter = nil;
    composition = nil;
    videoTake = nil;
    movieURL = nil;

    [super viewDidUnload];
}

- (void) dealloc
{
    [progressView release];
    [videoView release];
    [tapRecordLabel release];
    [removeButton release];
    [doneButton release];
    
    [videoCamera release];
    [movieWriter release];
    [composition release];
    [videoTake release];
    [movieURL release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark

- (void) startRecording
{
    if ([composition canAddVideoClip])
    {
        [composition setRecording: YES];
        
        // Record Settings
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        NSString *path = [NSString stringWithFormat: @"Movie_%@.m4v", [formater stringFromDate:[NSDate date]]];
        [formater release];
        
        NSString *pathToMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
        unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
        movieURL = [NSURL fileURLWithPath:pathToMovie];
        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
        
        videoTake = [[NTVideoClip alloc] init];
        videoTake.videoPath = movieURL;
        [composition addVideoClip: videoTake];
        
        [videoCamera addTarget: movieWriter];
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
    }
}

- (void) pauseRecording
{
    [composition setRecording: NO];
    
    [videoCamera removeTarget:movieWriter];
    videoCamera.audioEncodingTarget = nil;
    
    float duration = CMTimeGetSeconds(movieWriter.duration);
    videoTake.duration = duration;
    
    [movieWriter finishRecordingWithCompletionHandler:^{
        
    }];
}

- (void) longPressGestureRecognized:(UILongPressGestureRecognizer *) gesture
{
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
            [self startRecording];
            break;
        case UIGestureRecognizerStateEnded:
            [self pauseRecording];
            break;
        default:
            break;
    }
}

- (void) removeLastTake
{
    if ([composition isLastTakeReadyToRemove])
    {
        [composition removeLastVideoClip];
    }
    else
    {
        composition.isLastTakeReadyToRemove = YES;
    }
    
    [progressView setNeedsDisplay];
}

- (void)recordTimeUp:(id)object
{
    [self stopRecording];
}

- (void) stopRecording
{
    if ([[composition clips] count] < 1 )
    {
        NSLog(@"Record video count is empty.");
        return;
    }
    
    [self pauseRecording];
    
    [composition concatenateVideosWithCompletionHandler:^(NSURL *outputUrl)
     {
         NSLog(@"outputUrl is:%@", outputUrl);
         
         _outputFileUrl = outputUrl;
         
//         [composition clearAll];
         [progressView clearAll];
        
         
         // Success
         if(_delegate && [_delegate respondsToSelector:@selector(pickVideoFromCameraComplete:)])
         {
             [_delegate performSelector:@selector(pickVideoFromCameraComplete:) withObject:_outputFileUrl];
         }
         
//         for(UIViewController *controller in self.navigationController.viewControllers)
//         {
//             if([controller isKindOfClass:[JZViewController class]])
//             {
//                 JZViewController *vc = (JZViewController *)controller;
//                 [self.navigationController popToViewController:vc animated:NO];
//             }
//         }
         
         // test
//         [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputUrl completionBlock:^(NSURL *assetURL, NSError *error)
//          {
//              if (error == nil)
//              {
//                  NSLog(@"Movie saved");
//              }
//              else
//              {
//                  NSLog(@"Error %@", error);
//              }
//          }];
//         
     }];
}

@end
