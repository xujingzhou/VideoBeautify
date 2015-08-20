//
//  NTVideoComposition.m
//  GPUImageVideoStitchRec
//
//  Created by Nao Tokui on 6/16/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import "VideoComposition.h"

@interface NTVideoComposition()
{
    // For checking recording duration
    NSDate *_startedAt;
    NSTimer *_timerRecord;
}

@property (assign, nonatomic) id delegate;

@property (retain, nonatomic) NSDate *startedAt;
@property (retain, nonatomic) NSTimer *timerRecord;

@end

@implementation NTVideoComposition

@synthesize delegate = _delegate;
@synthesize startedAt = _startedAt;
@synthesize timerRecord = _timerRecord;

- (float) maxDurationAllowed
{
    return  kMaxRecordDuration;
}

- (void) clearAll
{
    [self.clips removeAllObjects];
    
    self.startedAt = nil;
    
    [self.timerRecord invalidate];
    self.timerRecord = nil;
}

- (void) dealloc
{
    [self clearAll];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.clips = [[NSMutableArray alloc] init];
        self.startedAt = nil;
        self.timerRecord = nil;
    }
    return self;
}

- (id) initWithDelegate:(id)delegate
{
	if (self = [super init])
    {
        self.delegate = delegate;
        
        self.clips = [[NSMutableArray alloc] init];
        self.startedAt = nil;
        self.timerRecord = nil;
	}
    
	return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"composition contains %ld takes", (unsigned long)[_clips count]];
}

- (void) addVideoClip: (NTVideoClip *) take
{
    float duration = [self duration];
    take.startAt = duration;
    [self.clips addObject: take];
    self.isLastTakeReadyToRemove = NO;
    
    [self notifyDurationChanges];
}

- (void) removeLastVideoClip
{
    [self.clips removeLastObject];
    self.isLastTakeReadyToRemove = NO;
}

- (float) duration
{
    return [self recordedDuration] + [self recordingDuration];
}

- (CGSize) lastVideoClipRange
{
    NTVideoClip *take = [_clips lastObject];
    return  take.timeRange;
}

#pragma mark

- (BOOL) canAddVideoClip
{
    return ([self duration] < kMaxRecordDuration);
}

- (void) setRecording: (BOOL) recording
{
    _isRecording = recording;
    
    if (_isRecording)
    {
        self.startedAt = [NSDate date];
        self.timerRecord = [NSTimer scheduledTimerWithTimeInterval: 0.1 target:self selector:@selector(notifyDurationChanges) userInfo:nil repeats:YES];
    }
    else
    {
        [self notifyDurationChanges];
        [self.timerRecord invalidate];
        self.timerRecord = nil;
        self.startedAt = nil;
    }
}

- (float) recordingDuration
{
    if (!_isRecording)
        return  0.0;
    else
    {
//        NSLog(@"startedAt is: %@", self.startedAt);
        return [self.startedAt timeIntervalSinceNow] * -1;
    }
}

- (float) recordedDuration
{
    float dur = 0;
    for (NTVideoClip *take in _clips)
    {
        dur += take.duration;
    }
    return dur;
}

- (void) notifyDurationChanges
{
    [self willChangeValueForKey: @"duration"];
    [self didChangeValueForKey: @"duration"];
    
    if( ![self canAddVideoClip] )
    {
        NSLog(@"Max length is up.");
        
        // Exceed max length
        if(_delegate && [_delegate respondsToSelector:@selector(recordTimeUp:)])
        {
            [_delegate performSelector:@selector(recordTimeUp:) withObject:nil];
        }
    }
}

#pragma mark - Merge & Finish
- (void) concatenateVideosWithCompletionHandler:(void (^)(NSURL*))handler
{
    if (self.duration == 0)
    {
        NSLog(@"No video clips to stitch");
        handler(NO);
        return;
    }
    
    
    NSMutableArray *assets = [NSMutableArray array];
    for (NTVideoClip *take in self.clips)
    {
        [assets addObject: [take videoAsset]];
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    CMTime current = kCMTimeZero;
    NSError *compositionError = nil;
    for(AVAsset *asset in assets)
    {
        BOOL result = [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration])
                                           ofAsset:asset atTime:current error:&compositionError];
        if(!result)
        {
            handler(NO);
            return;
        }
        else
        {
            current = CMTimeAdd(current, [asset duration]);
        }
    }
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:composition];
    AVAssetExportSession *exportSession;
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality])
    {
        exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    }
    else if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
    {
        exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    }
    else if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality])
    {
        exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetLowQuality];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent: @"inputVideo.m4v"];
    unlink([outputURL UTF8String]);
    
    exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        BOOL success = ([exportSession status] == AVAssetExportSessionStatusCompleted);
        if (success)
        {
            handler(exportSession.outputURL);
        }
    }];
}

@end
