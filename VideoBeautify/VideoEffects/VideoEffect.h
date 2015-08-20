//
//  VideoEffect
//  From VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 7/23/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoThemesData.h"

@interface VideoEffect : NSObject
{
    ThemesType _themeCurrentType;
}

@property (assign, nonatomic) ThemesType themeCurrentType;

- (id) initWithDelegate:(id)delegate;

- (void) buildVideoBeautify:(NSString *)exportVideoFile inputVideoURL:(NSURL*)inputVideoURL fromSystemCamera:(BOOL)fromSystemCamera;
- (BOOL) buildVideoEffectsToMP4:(NSString *)exportVideoFile inputVideoURL:(NSURL*)inputVideoURL;

- (void) clearAll;
- (void) pause;
- (void) resume;

@end
