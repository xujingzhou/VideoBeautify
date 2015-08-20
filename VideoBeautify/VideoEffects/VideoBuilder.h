//
//  VideoBuilder
//  From VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CMTime.h>

typedef enum tagEffectDirection
{
    EffectDirectionLeftToRight = 0,
    EffectDirectionRightToLeft = 1,
    EffectDirectionTopToBottom = 2,
    EffectDirectionBottomToTop = 3,
    EffectDirectionTopLeftToBottomRight = 4,
    EffectDirectionBottomRightToTopLeft = 5,
    EffectDirectionBottomLeftToTopRight = 6,
    EffectDirectionTopRightToBottomLeft = 7,
}EffectDirection;

typedef enum
{
	TransitionTypeNone,
	TransitionTypeCrossFade,
	TransitionTypePush
}VideoBuilderTransitionType;


@interface VideoBuilder : NSObject 
{	
	// Configuration
	
	NSArray *_clips;			// array of AVURLAssets
	NSArray *_clipTimeRanges;	// array of CMTimeRanges stored in NSValues.
	
	AVURLAsset *_commentary;
	CMTime _commentaryStartTime;
	
	VideoBuilderTransitionType _transitionType;
	CMTime _transitionDuration;
	
	NSString *_titleText;
	
	
	// Composition objects.
	AVComposition *_composition;
	AVVideoComposition *_videoComposition;
	AVAudioMix *_audioMix;
	
	AVPlayerItem *_playerItem;
	AVSynchronizedLayer *_synchronizedLayer;
}

// Set these properties before building the composition objects.
@property (nonatomic, retain) NSArray *clips;
@property (nonatomic, retain) NSArray *clipTimeRanges;

@property (nonatomic, retain) AVURLAsset *commentary;
@property (nonatomic) CMTime commentaryStartTime;

@property (nonatomic) VideoBuilderTransitionType transitionType;
@property (nonatomic) CMTime transitionDuration;

@property (nonatomic, retain) NSString *titleText;

@property (nonatomic, readonly, retain) AVComposition *composition;
@property (nonatomic, readonly, retain) AVVideoComposition *videoComposition;
@property (nonatomic, readonly, retain) AVAudioMix *audioMix;

- (CALayer*) buildAnimationFlashScreen:(CGSize)viewBounds startTime:(NSTimeInterval)timeInterval startOpacity:(BOOL)startOpacity;
- (CALayer*) buildSpotlight:(CGSize)viewBounds;
- (CALayer*) buildGradientText:(CGSize)viewBounds positon:(CGPoint)postion text:(NSString*)text;
- (CAEmitterLayer*) buildEmitterSteam:(CGSize)viewBounds positon:(CGPoint)postion;
- (CALayer*) buildAnimationRipple:(CGSize)viewBounds centerPoint:(CGPoint)centerPoint radius:(CGFloat)radius startTime:(NSTimeInterval)startTime;
- (CALayer *) buildAnimatedScrollLine:(CGSize)viewBounds startTime:(CFTimeInterval)timeInterval lineHeight:(CGFloat)lineHeight image:(UIImage*)image;
- (CALayer*) buildAnimatedScrollText:(CGSize)viewBounds text:(NSString*)text startPoint:(CGPoint)startPoint startTime:(NSTimeInterval)timeInterval;
- (CALayer*) buildAnimationScrollScreen:(CGSize)viewBounds;
- (CALayer*) buildVideoFrameImage:(CGSize)viewBounds videoFile:(NSURL*)inputVideoURL startTime:(CMTime)startTime;
- (CALayer*) buildAnimationImages:(CGSize)viewBounds imagesArray:(NSMutableArray *)imagesArray position:(CGPoint)position;
- (CALayer*) buildImage:(CGSize)viewBounds image:(NSString*)imageFile position:(CGPoint)position;
- (CAEmitterLayer*) buildEmitterRing:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterSnow:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterSnow2:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterHeart:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterFireworks:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterStar:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterMoveDot:(CGSize)viewBounds position:(CGPoint)position;
- (CAEmitterLayer*) buildEmitterBlackWhiteDot:(CGSize)viewBounds positon:(CGPoint)postion startTime:(NSTimeInterval)startTime;
- (CAEmitterLayer*) buildEmitterSky:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterMeteor:(CGSize)viewBounds startTime:(NSTimeInterval)timeInterval pathN:(NSInteger)pathN;
- (CAEmitterLayer*) buildEmitterRain:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterFlower:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterBirthday:(CGSize)viewBounds;
- (CAEmitterLayer*) buildEmitterFire:(CGSize)viewBounds position:(CGPoint)position;
- (CAEmitterLayer*) buildEmitterSmoke:(CGSize)viewBounds position:(CGPoint)position;
- (CAEmitterLayer*) buildEmitterSpark:(CGSize)viewBounds;
- (CAShapeLayer*) buildEmitterSparkle:(CGSize)viewBounds text:(NSString*)text startTime:(NSTimeInterval)timeInterval;
- (CALayer *)buildAnimationStarText:(CGSize)viewBounds text:(NSString*)text;
- (void)addCommentaryTrackToComposition:(AVMutableComposition *)composition withAudioMix:(AVMutableAudioMix *)audioMix;


// Build the composition, videoComposition, and audioMix. 
// If the composition is being built for playback then a synchronized layer and player item are also constructed.
// All of these objects can be retrieved all of these objects with the accessors below.
// Calling buildCompositionObjectsForPlayback: will get rid of any previously created composition objects.
- (void)buildCompositionObjectsForPlayback:(BOOL)forPlayback;

// The synchronized layer contains a layer tree which is synchronized with the provided player item.
// Inside the layer tree there is a playerLayer along with other layers related to titling.
- (void)getPlayerItem:(AVPlayerItem**)playerItemOut andSynchronizedLayer:(AVSynchronizedLayer**)synchronizedLayerOut;

- (AVAssetImageGenerator*)assetImageGenerator;
- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;

@end
