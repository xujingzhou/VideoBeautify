//
//  VideoThemesData.h
//  VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 8/11/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoThemes.h"

// Effects
typedef enum
{
    kAnimationNone = 0,
    kAnimationFireworks,
    kAnimationSnow,
    kAnimationSnow2,
    kAnimationHeart,
    kAnimationRing,
    kAnimationStar,
    kAnimationMoveDot,
    kAnimationSky,
    kAnimationMeteor,
    kAnimationRain,
    kAnimationFlower,
    kAnimationFire,
    kAnimationSmoke,
    kAnimationSpark,
    kAnimationSteam,
    kAnimationBirthday,
    kAnimationBlackWhiteDot,
    kAnimationScrollScreen,
    kAnimationSpotlight,
    kAnimationScrollLine,
    kAnimationRipple,
    kAnimationImage,
    kAnimationImageArray,
    kAnimationVideoFrame,
    kAnimationTextStar,
    kAnimationTextSparkle,
    kAnimationTextScroll,
    kAnimationTextGradient,
    kAnimationFlashScreen,
    
} AnimationActionType;

// Themes
typedef enum
{
    // 无
    kThemeNone = 0,
    
    // 心情
    kThemeMood,
    
    // 怀旧
    kThemeNostalgia,
    
    // 老电影
    KThemeOldFilm,
    
    // Nice day
    kThemeNiceDay,

    // 星空
    kThemeSky,
    
    // 时尚
    kThemeFashion,
    
    // 生日
    kThemeBirthday,
    
    // 心动
    kThemeHeartbeat,
    
    // 浪漫
    kThemeRomantic,
    
    // 星光
    kThemeStarshine,
    
    // 雨天
    kThemeRain,

    // 花语
    kThemeFlower,
    
    // 经典
    kThemeClassic,
    
} ThemesType;

@interface VideoThemesData : NSObject
{
    
}

+ (VideoThemesData *) sharedInstance;

- (NSMutableDictionary*) getThemeData;
- (NSMutableDictionary*) getThemeFilter:(BOOL)fromSystemCamera;
//- (GPUImageOutput<GPUImageInput> *) createThemeFilter:(ThemesType)themeType fromSystemCamera:(BOOL)fromSystemCamera;

@end
