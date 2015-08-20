//
//  NTRecProgressView.m
//  GPUImageVideoStitchRec
//
//  Created by Nao Tokui on 6/16/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import "RecProgressView.h"

@interface NTRecProgressView()
{
    
}

@property (assign, nonatomic) BOOL clear;

@end

@implementation NTRecProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.opaque = NO;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) clearAll
{
    self.backgroundColor = [UIColor clearColor];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGFloat fixedColors [] = { 38/255.0,200/255.0,210/255.0, 1.0, 38/255.0,191/255.0,162/255.0, 1.0 };
    CGFloat recColors [] = { 244/255.0,121/255.0,99/255.0, 1.0, 241/255.0,58/255.0,58/255.0, 1.0 };
    CGFloat seconds3Colors [] = { 155/255,188/255,220/255.0, 1.0, 160/255,160/255,200/255.0, 1.0 };
    
    float maxDuration = [self.composition maxDurationAllowed];
    float w = self.frame.size.width;
    float h = self.frame.size.height;
    
    // Background
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.25);
    CGContextFillRect(context, rect);
    
    // Not less than 3s
    float length3Sec = 3 / maxDuration * w;
    [self drawRect: CGRectMake(length3Sec, 0, 5, h) withColors: seconds3Colors context: context];
    
    // Recorded clips
    float duration = [self.composition recordedDuration];
    float lastCompDuration = [self.composition recordingDuration];
    if (self.composition.isLastTakeReadyToRemove)
    {
        CGSize range = [self.composition lastVideoClipRange];
        lastCompDuration = range.height;
        duration -= lastCompDuration;
    }
    float length = duration / maxDuration * w;
    CGRect fixed    = CGRectMake(0, 0, length, h);
    [self drawRect: fixed withColors: fixedColors context: context];
    
    // Recording clip or last clip to be removed
    if (self.composition.isRecording || self.composition.isLastTakeReadyToRemove)
    {
        float addedLength = lastCompDuration / maxDuration * w;
        CGRect added = CGRectMake(length+1, 0, addedLength, h);
        [self drawRect: added withColors: recColors context: context];
    }
}

- (void) drawRect: (CGRect) rect withColors: (CGFloat *) colors context: (CGContextRef) context
{
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient), gradient = NULL;
    CGContextAddRect(context, rect);
}

- (void) setComposition:(NTVideoComposition *)composition
{
    _composition = composition;
    
    if (composition)
    {
        [composition addObserver: self forKeyPath: @"isLastTakeReadyToRemove" options: NSKeyValueObservingOptionNew context: nil];
        [composition addObserver: self forKeyPath:@"duration" options: NSKeyValueObservingOptionInitial context: nil];
    }
    else
    {
        [composition removeObserver: self forKeyPath: @"isLastTakeReadyToRemove"];
        [composition removeObserver: self forKeyPath: @"duration"];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.composition == object)
    {
        if ([keyPath isEqualToString: @"isLastTakeReadyToRemove"] || [keyPath isEqualToString: @"duration"])
        {
            [self setNeedsDisplay];
        }
    }
}

@end
