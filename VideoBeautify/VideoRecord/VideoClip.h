//
//  NTVideoTake.h
//  GPUImageVideoStitchRec
//
//  Created by Nao Tokui on 6/16/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface NTVideoClip : NSObject

@property (nonatomic, strong) NSURL  *videoPath;
@property (nonatomic) float duration;
@property (nonatomic) float startAt;

- (CGSize) timeRange;
- (AVAsset *)videoAsset;

@end
