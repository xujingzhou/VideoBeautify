//
//  VideoThemesData.m
//  VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 8/11/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "VideoThemesData.h"

@interface VideoThemesData()
{
    NSMutableDictionary *_themesDic;
    
    NSMutableDictionary *_filterFromOthers;
    NSMutableDictionary *_filterFromSystemCamera;
}

@property (retain, nonatomic) NSMutableDictionary *themesDic;
@property (retain, nonatomic) NSMutableDictionary *filterFromOthers;
@property (retain, nonatomic) NSMutableDictionary *filterFromSystemCamera;
@end


@implementation VideoThemesData

@synthesize themesDic = _themesDic;
@synthesize filterFromOthers = _filterFromOthers;
@synthesize filterFromSystemCamera = _filterFromSystemCamera;

#pragma mark - Singleton
+ (VideoThemesData *) sharedInstance
{
    static VideoThemesData *singleton = nil;
    static dispatch_once_t once = 0;
    dispatch_once(&once, ^{
        singleton = [[VideoThemesData alloc] init];
    });
    
    return singleton;
}

#pragma mark - Life cycle
- (id)init
{
	if (self = [super init])
    {
        // Only run once
        [self initThemesData];
        
        NSMutableDictionary *filterOthers = [[self initThemeFilter:FALSE] autorelease];
        self.filterFromOthers = filterOthers;

        NSMutableDictionary *filterSystemCamera = [[self initThemeFilter:TRUE] autorelease];
        self.filterFromSystemCamera = filterSystemCamera;
    }
    
	return self;
}

- (void)dealloc
{
    [self clearAll];
    
    [super dealloc];
}

- (void) clearAll
{
    if (self.filterFromOthers && [self.filterFromOthers count]>0)
    {
        [self.filterFromOthers removeAllObjects];
        self.filterFromOthers = nil;
    }
    
    if (self.filterFromSystemCamera && [self.filterFromSystemCamera count]>0)
    {
        for (GPUImageOutput<GPUImageInput> *filter in self.filterFromOthers)
        {
            [filter removeAllTargets];
            [filter release];
        }
        [self.filterFromSystemCamera removeAllObjects];
        self.filterFromSystemCamera = nil;
    }
    
    if (self.themesDic && [self.themesDic count]>0)
    {
        [self.themesDic removeAllObjects];
        self.themesDic = nil;
    }
}

#pragma mark - Common function
- (NSString*) getWeekdayFromDate:(NSDate*)date
{
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* components = nil; //[[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit |
    NSMonthCalendarUnit |
    NSDayCalendarUnit |
    NSWeekdayCalendarUnit |
    NSHourCalendarUnit |
    NSMinuteCalendarUnit |
    NSSecondCalendarUnit;
    components = [calendar components:unitFlags fromDate:date];
    NSUInteger weekday = [components weekday];
    
    NSString *result = nil;
    switch (weekday)
    {
        case 1:
        {
            result = @"Sunday";
            break;
        }
        case 2:
        {
            result = @"Monday";
            break;
        }
        case 3:
        {
            result = @"Tuesday";
            break;
        }
        case 4:
        {
            result = @"Wednesday";
            break;
        }
        case 5:
        {
            result = @"Thursday";
            break;
        }
        case 6:
        {
            result = @"Friday";
            break;
        }
        case 7:
        {
            result = @"Saturday";
            break;
        }
        default:
            break;
    }
    
    [calendar release];
    
    return result;
}

-(NSString*) getStringFromDate:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *strDate = [dateFormatter stringFromDate:date];
    [dateFormatter release];
    
    return strDate;
}

#pragma mark - Init themes
- (GPUImageOutput<GPUImageInput> *) createFilterClassic:(BOOL)fromSystemCamera
{
    // Filter
//    GPUImageOutput<GPUImageInput> *filterClassic = [[GPUImageFilterGroup alloc] init];
//    
//    CGFloat rotationAngle = 0;
//    if (fromSystemCamera)
//    {
//        rotationAngle = M_PI_2;
//    }
//    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
//    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
//    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
//    [(GPUImageFilterGroup *)filterClassic addFilter:transformFilter];
//    
//    GPUImageOutput<GPUImageInput> *borderFilter = [[GPUImageBorderFilter alloc] init];
//    NSString *borderImageName = @"border_00";
//    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
//    [(GPUImageFilterGroup *)filterClassic addFilter:borderFilter];
//    
//    [transformFilter addTarget:borderFilter];
//    
//    [(GPUImageFilterGroup *)filterClassic setInitialFilters:[NSArray arrayWithObject:transformFilter]];
//    [(GPUImageFilterGroup *)filterClassic setTerminalFilter:borderFilter];
//    
//    [transformFilter release];
//    transformFilter = nil;
//    [borderFilter release];
//    borderFilter = nil;
//    
//    return filterClassic;
    
    GPUImageTransformFilter *transformFilter = nil;
    if (fromSystemCamera)
    {
        // If this is from system camera, it will rotate 90c
        transformFilter = [[[GPUImageTransformFilter alloc] init] autorelease];
        [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    }
    
    return transformFilter;
}

- (VideoThemes*) createThemeClassic
{
    VideoThemes *themeClassic = [[[VideoThemes alloc] init] autorelease];
    themeClassic.ID = kThemeClassic;
    themeClassic.thumbImageName = @"themeClassic";
    themeClassic.name = @"Classic";
    themeClassic.textStar = nil;
    themeClassic.textSparkle = nil;
    themeClassic.bgMusicFile = @"Funk Type.mp3";
    themeClassic.imageFile = nil;
    
    // Filter
//    themeClassic.filter = [self createFilterClassic:fromSystemCamera];
    
    // Animation effects
    NSArray *aniClassic = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationFireworks], nil];
    themeClassic.animationActions = [NSArray arrayWithArray:aniClassic];
    
    return themeClassic;
}

- (GPUImageOutput<GPUImageInput> *) createFilterNostalgia:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterNostalgia = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterNostalgia addFilter:transformFilter];
    
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    [(GPUImageFilterGroup *)filterNostalgia addFilter:sepiaFilter];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    [(GPUImageVignetteFilter *)vignetteFilter setVignetteEnd:0.7];
    [(GPUImageFilterGroup *)filterNostalgia addFilter:vignetteFilter];
    
    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
    NSString *borderImageName = @"border_14";
    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
    [(GPUImageFilterGroup *)filterNostalgia addFilter:borderFilter];
    
    [vignetteFilter addTarget:borderFilter];
    [sepiaFilter addTarget:vignetteFilter];
    [transformFilter addTarget:sepiaFilter];
    
    [(GPUImageFilterGroup *)filterNostalgia setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterNostalgia setTerminalFilter:borderFilter];
    
    [transformFilter release];
    transformFilter = nil;
    [sepiaFilter release];
    sepiaFilter = nil;
    [vignetteFilter release];
    vignetteFilter = nil;
    [borderFilter release];
    borderFilter = nil;
    
    return filterNostalgia;
}

- (VideoThemes*) createThemeNostalgia
{
    VideoThemes *themeNostalgia = [[[VideoThemes alloc] init] autorelease];
    themeNostalgia.ID = kThemeNostalgia;
    themeNostalgia.thumbImageName = @"themeNostalgia";
    themeNostalgia.name = @"Country";
    themeNostalgia.textStar = nil;
    themeNostalgia.textSparkle = nil;
    themeNostalgia.bgMusicFile = @"Bye Bye Sunday.mp3";
    themeNostalgia.imageFile = nil;
    
    // Filter
//    themeNostalgia.filter = [self createFilterNostalgia:fromSystemCamera];
    
    // Animation effects
    NSArray *aniNostalgia = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationSnow], nil];
    themeNostalgia.animationActions = [NSArray arrayWithArray:aniNostalgia];
    
    return themeNostalgia;
}

- (GPUImageOutput<GPUImageInput> *) createFilterHeartbeat:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterHeartbeat = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterHeartbeat addFilter:transformFilter];
    
//    GPUImageTiltShiftFilter *tiltshiftFilter = [[GPUImageTiltShiftFilter alloc] init];
//    [(GPUImageTiltShiftFilter *)tiltshiftFilter setTopFocusLevel:0.4];
//    [(GPUImageTiltShiftFilter *)tiltshiftFilter setBottomFocusLevel:0.6];
//    [(GPUImageTiltShiftFilter *)tiltshiftFilter setFocusFallOffRate:0.2];
//    [(GPUImageFilterGroup *)filterHeartbeat addFilter:tiltshiftFilter];
    
    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
    NSString *borderImageName = @"border_10";
    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
    [(GPUImageFilterGroup *)filterHeartbeat addFilter:borderFilter];
    
//    [tiltshiftFilter addTarget:borderFilter];
//    [transformFilter addTarget:tiltshiftFilter];
    
    [transformFilter addTarget:borderFilter];
    
    [(GPUImageFilterGroup *)filterHeartbeat setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterHeartbeat setTerminalFilter:borderFilter];
    
    [transformFilter release];
    transformFilter = nil;
//    [tiltshiftFilter release];
//    tiltshiftFilter = nil;
    [borderFilter release];
    borderFilter = nil;
    
    return filterHeartbeat;
}

- (VideoThemes*) createThemeHeartbeat
{
    VideoThemes *themeHeartbeat = [[[VideoThemes alloc] init] autorelease];
    themeHeartbeat.ID = kThemeHeartbeat;
    themeHeartbeat.thumbImageName = @"themeHeartbeat";
    themeHeartbeat.name = @"Heart";
    themeHeartbeat.textStar = nil;
    themeHeartbeat.textSparkle = nil;
    themeHeartbeat.bgMusicFile = @"Come With Me.mp3";
    themeHeartbeat.imageFile = nil;
    
    // Filter
//    themeHeartbeat.filter = [self createFilterHeartbeat:fromSystemCamera];
    
    // Animation effects
    NSArray *aniHeartbeat = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationHeart], nil];
    themeHeartbeat.animationActions = [NSArray arrayWithArray:aniHeartbeat];
    
    return themeHeartbeat;
}

- (GPUImageOutput<GPUImageInput> *) createFilterFashion:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterFashion = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterFashion addFilter:transformFilter];
    
    GPUImageZoomBlurFilter *zoomBlurFilter = [[GPUImageZoomBlurFilter alloc] init];
    [(GPUImageZoomBlurFilter *)zoomBlurFilter setBlurSize:0.5];
    [(GPUImageFilterGroup *)filterFashion addFilter:zoomBlurFilter];
    
    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
    NSString *borderImageName = @"border_12";
    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
    [(GPUImageFilterGroup *)filterFashion addFilter:borderFilter];
    
    [zoomBlurFilter addTarget:borderFilter];
    [transformFilter addTarget:zoomBlurFilter];
    
    [(GPUImageFilterGroup *)filterFashion setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterFashion setTerminalFilter:borderFilter];
    
    [transformFilter release];
    transformFilter = nil;
    [zoomBlurFilter release];
    zoomBlurFilter = nil;
    [borderFilter release];
    borderFilter = nil;
    
    return filterFashion;
}

- (VideoThemes*) createThemeFashion
{
    VideoThemes *themeFashion = [[[VideoThemes alloc] init] autorelease];
    themeFashion.ID = kThemeFashion;
    themeFashion.thumbImageName = @"themeFashion";
    themeFashion.name = @"Fashion";
    themeFashion.textStar = @"Music!";
    themeFashion.textSparkle = nil;
    themeFashion.bgMusicFile = @"Hubble PoPo.mp3";
    themeFashion.imageFile = nil;
    
    // Filter
//    themeFashion.filter = [self createFilterFashion:fromSystemCamera];
    
    // Animation effects
    NSArray *aniFashion = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationRing], nil];
    themeFashion.animationActions = [NSArray arrayWithArray:aniFashion];
    
    return themeFashion;
}

- (GPUImageOutput<GPUImageInput> *) createFilterRomantic:(BOOL)fromSystemCamera
{
    // Filter
//    GPUImageOutput<GPUImageInput> *filterRomantic = [[GPUImageFilterGroup alloc] init];
//    
//    CGFloat rotationAngle = 0;
//    if (fromSystemCamera)
//    {
//        rotationAngle = M_PI_2;
//    }
//    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
//    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
//    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
//    [(GPUImageFilterGroup *)filterRomantic addFilter:transformFilter];
//    
//    GPUImageOutput<GPUImageInput> *borderFilter = [[GPUImageBorderFilter alloc] init];
//    NSString *borderImageName = @"border_23";
//    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
//    [(GPUImageFilterGroup *)filterRomantic addFilter:borderFilter];
//    
//    [transformFilter addTarget:borderFilter];
//    
//    [(GPUImageFilterGroup *)filterRomantic setInitialFilters:[NSArray arrayWithObject:transformFilter]];
//    [(GPUImageFilterGroup *)filterRomantic setTerminalFilter:borderFilter];
//    
//    [transformFilter release];
//    transformFilter = nil;
//    [borderFilter release];
//    borderFilter = nil;
//    
//    return filterRomantic;
    
    GPUImageTransformFilter *transformFilter = nil;
    if (fromSystemCamera)
    {
        // If this is from system camera, it will rotate 90c
        transformFilter = [[[GPUImageTransformFilter alloc] init] autorelease];
        [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    }
    
    return transformFilter;
}

- (VideoThemes*) createThemeRomantic
{
    VideoThemes *themeRomantic = [[[VideoThemes alloc] init] autorelease];
    themeRomantic.ID = kThemeRomantic;
    themeRomantic.thumbImageName = @"themeRomantic";
    themeRomantic.name = @"Feel";
    themeRomantic.textStar = nil;
    themeRomantic.textSparkle = nil;
    themeRomantic.bgMusicFile = @"Jazz Club.mp3";
    themeRomantic.imageFile = nil;
    
    // Filter
//    themeRomantic.filter = [self createFilterRomantic:fromSystemCamera];
    
    // Animation effects
    NSArray *aniRomantic = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationStar],nil];
    themeRomantic.animationActions = [NSArray arrayWithArray:aniRomantic];
    
    return themeRomantic;
}

- (GPUImageOutput<GPUImageInput> *) createFilterStarshine:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterStarshine = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterStarshine addFilter:transformFilter];
    
    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
    NSString *borderImageName = @"border_16";
    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
    [(GPUImageFilterGroup *)filterStarshine addFilter:borderFilter];
    
    GPUImageVignetteFilterEx *vignetterFilter = [[GPUImageVignetteFilterEx alloc] init];
    float level = 0.6; // 0 ~ 1
    vignetterFilter.vignetteStart = 0.1;
    vignetterFilter.vignetteEnd = 0.75;
    vignetterFilter.vignetteLevel = level * .3;
    [(GPUImageFilterGroup *)filterStarshine addFilter:vignetterFilter];
    
    [vignetterFilter addTarget:borderFilter];
    [transformFilter addTarget:vignetterFilter];
    
    [(GPUImageFilterGroup *)filterStarshine setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterStarshine setTerminalFilter:borderFilter];
    
    [transformFilter release];
    transformFilter = nil;
    [vignetterFilter release];
    vignetterFilter = nil;
    [borderFilter release];
    borderFilter = nil;
    
    return filterStarshine;
}

- (VideoThemes*) createThemeStarshine
{
    VideoThemes *themeStarshine = [[[VideoThemes alloc] init] autorelease];
    themeStarshine.ID = kThemeStarshine;
    themeStarshine.thumbImageName = @"themeStarshine";
    themeStarshine.name = @"Star";
    themeStarshine.textStar = nil;
    themeStarshine.textSparkle = nil;
    themeStarshine.bgMusicFile = @"Let Me Know.mp3";
    themeStarshine.imageFile = nil;
    
    // Filter
//    themeStarshine.filter = [self createFilterStarshine:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationMoveDot],nil];
    themeStarshine.animationActions = [NSArray arrayWithArray:aniActions];
    
    return themeStarshine;
}

- (GPUImageOutput<GPUImageInput> *) createFilterMood:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterMood = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterMood addFilter:transformFilter];
    
    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
    NSString *borderImageName = @"border_25";
    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
    [(GPUImageFilterGroup *)filterMood addFilter:borderFilter];
    
    GPULookupFilterEx *lookupFilter = [[GPULookupFilterEx alloc] initWithName:@"milk" isWhiteAndBlack:YES];
    [(GPUImageFilterGroup *)filterMood addFilter:lookupFilter];
    
    [lookupFilter addTarget:borderFilter];
    [transformFilter addTarget:lookupFilter];
    
    [(GPUImageFilterGroup *)filterMood setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterMood setTerminalFilter:borderFilter];
    
    [transformFilter release];
    transformFilter = nil;
    [lookupFilter release];
    lookupFilter = nil;
    [borderFilter release];
    borderFilter = nil;
    
    return filterMood;
}

- (VideoThemes*) createThemeMood
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = kThemeMood;
    theme.thumbImageName = @"themeMood";
    theme.name = @"Miss";
    theme.textStar = nil;
    theme.textSparkle = @"Miss You!";
    theme.bgMusicFile = @"Oh My Juliet.mp3";
    theme.imageFile = nil;
    
    // Filter
//    theme.filter = [self createFilterMood:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationTextSparkle], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (GPUImageOutput<GPUImageInput> *) createFilterSky:(BOOL)fromSystemCamera
{
    // Filter
//    GPUImageOutput<GPUImageInput> *filterSky = [[GPUImageFilterGroup alloc] init];
//    
//    CGFloat rotationAngle = 0;
//    if (fromSystemCamera)
//    {
//        rotationAngle = M_PI_2;
//    }
//    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
//    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
//    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
//    [(GPUImageFilterGroup *)filterSky addFilter:transformFilter];
//    
//    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
//    NSString *borderImageName = @"border_07";
//    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
//    [(GPUImageFilterGroup *)filterSky addFilter:borderFilter];
//    
//    GPULookupFilterEx *lookupFilter = [[GPULookupFilterEx alloc] initWithName:@"smoky" isWhiteAndBlack:NO];
//    [(GPUImageFilterGroup *)filterSky addFilter:lookupFilter];
//    
//    [lookupFilter addTarget:borderFilter];
//    [transformFilter addTarget:lookupFilter];
//    
//    [(GPUImageFilterGroup *)filterSky setInitialFilters:[NSArray arrayWithObject:transformFilter]];
//    [(GPUImageFilterGroup *)filterSky setTerminalFilter:lookupFilter];
//    
//    [transformFilter release];
//    transformFilter = nil;
//    [lookupFilter release];
//    lookupFilter = nil;
//    [borderFilter release];
//    borderFilter = nil;
//    
//    return filterSky;
    
    GPUImageTransformFilter *transformFilter = nil;
    if (fromSystemCamera)
    {
        // If this is from system camera, it will rotate 90c
        transformFilter = [[[GPUImageTransformFilter alloc] init] autorelease];
        [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    }
    
    return transformFilter;
}

- (VideoThemes*) createThemeSky
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = kThemeSky;
    theme.thumbImageName = @"themeSky";
    theme.name = @"Sky";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.bgMusicFile = @"A Little Kiss.mp3";
    theme.imageFile = nil;
    
    // Filter
//    theme.filter = [self createFilterSky:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationSky], [NSNumber numberWithInt:kAnimationMeteor], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (GPUImageOutput<GPUImageInput> *) createFilterRain:(BOOL)fromSystemCamera
{
    // Filter
//    GPUImageOutput<GPUImageInput> *filterRain = [[GPUImageFilterGroup alloc] init];
    
//    CGFloat rotationAngle = 0;
//    if (fromSystemCamera)
//    {
//        rotationAngle = M_PI_2;
//    }
//    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
//    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
//    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
//    [(GPUImageFilterGroup *)filterRain addFilter:transformFilter];
    
//    GPUImageOutput<GPUImageInput> *blendFilter = [[GPUImageDissolveBlendFilter alloc] init];
//    [(GPUImageDissolveBlendFilter *)blendFilter setMix:0.6];
//    UIImage *inputImage = [UIImage imageNamed:@"rainBlend"];
//    GPUImagePicture *sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
//    [sourcePicture processImage];
//    [sourcePicture addTarget:blendFilter];
//    [(GPUImageFilterGroup *)filterRain addFilter:blendFilter];
//    
//    [transformFilter addTarget:blendFilter];
//    
//    [(GPUImageFilterGroup *)filterRain setInitialFilters:[NSArray arrayWithObject:transformFilter]];
//    [(GPUImageFilterGroup *)filterRain setTerminalFilter:blendFilter];
    
//    [transformFilter release];
//    transformFilter = nil;
//    [blendFilter release];
//    blendFilter = nil;

//    return filterRain;
    
    GPUImageTransformFilter *transformFilter = nil;
    if (fromSystemCamera)
    {
        // If this is from system camera, it will rotate 90c
        transformFilter = [[[GPUImageTransformFilter alloc] init] autorelease];
        [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    }
    
    return transformFilter;
}

- (VideoThemes*) createThemeRain
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = kThemeRain;
    theme.thumbImageName = @"themeRain";
    theme.name = @"Rain";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.bgMusicFile = @"I Do.mp3";
    theme.imageFile = nil;
    
    // Filter
//    theme.filter = [self createFilterRain:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationRain],nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (GPUImageOutput<GPUImageInput> *) createFilterFlower:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageTransformFilter *transformFilter = nil;
    if (fromSystemCamera)
    {
        // If this is from system camera, it will rotate 90c
        transformFilter = [[[GPUImageTransformFilter alloc] init] autorelease];
        [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    }
    
    return transformFilter;
}

- (VideoThemes*) createThemeFlower
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = kThemeFlower;
    theme.thumbImageName = @"themeFlower";
    theme.name = @"Flower";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.bgMusicFile = @"Lost In Manhattan.mp3";
    theme.imageFile = nil;
    theme.textGradient = @"nice!";
    
    NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
    for (int i = 1; i<4; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"ani_%d.png",i];
        UIImage *image = [UIImage imageNamed:imageName];
        [imagesArray addObject:(id)image.CGImage];
    }
    theme.animationImages = imagesArray;
    
    [imagesArray release];
    
    NSArray *frameTimesArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:4], nil];
    theme.keyFrameTimes = frameTimesArray;
    
    // Filter
//    theme.filter = [self createFilterFlower:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationFlower], [NSNumber numberWithInt:kAnimationImageArray], [NSNumber numberWithInt:kAnimationVideoFrame], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (GPUImageOutput<GPUImageInput> *) createFilterBirthday:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterBirthday = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    // If this is from system camera, it will rotate 90c
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterBirthday addFilter:transformFilter];
    
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    [(GPUImageFilterGroup *)filterBirthday addFilter:sepiaFilter];
    
    [transformFilter addTarget:sepiaFilter];
    [(GPUImageFilterGroup *)filterBirthday setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterBirthday setTerminalFilter:sepiaFilter];
    
    [transformFilter release];
    transformFilter = nil;
    [sepiaFilter release];
    sepiaFilter = nil;
    
    return filterBirthday;
}

- (VideoThemes*) createThemeBirthday
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = kThemeBirthday;
    theme.thumbImageName = @"themeBirthday";
    theme.name = @"Birthday";
    theme.textStar = @"Happy Birthday!";
    theme.textSparkle = nil;
    theme.bgMusicFile = @"Christmas Song.mp3";
    theme.imageFile = @"cake01";
    
    // Filter
//    theme.filter = [self createFilterBirthday:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationTextStar], [NSNumber numberWithInt:kAnimationImage], [NSNumber numberWithInt:kAnimationBirthday], [NSNumber numberWithInt:kAnimationFire], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (GPUImageOutput<GPUImageInput> *) createFilterOldFilm:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageOutput<GPUImageInput> *filterOldFilm = [[[GPUImageFilterGroup alloc] init] autorelease];
    
    CGFloat rotationAngle = 0;
    if (fromSystemCamera)
    {
        rotationAngle = M_PI_2;
    }
    // If this is from system camera, it will rotate 90c
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(rotationAngle)];
    [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    [(GPUImageFilterGroup *)filterOldFilm addFilter:transformFilter];
    
    GPUImageBorderFilter *borderFilter = [[GPUImageBorderFilter alloc] init];
    NSString *borderImageName = @"border_22";
    ((GPUImageBorderFilter*)borderFilter).borderImage = [UIImage imageNamed:borderImageName];
    [(GPUImageFilterGroup *)filterOldFilm addFilter:borderFilter];
    
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    [(GPUImageFilterGroup *)filterOldFilm addFilter:sepiaFilter];
    
    GPUImageEmbossFilter *embossFilter = [[GPUImageEmbossFilter alloc] init];
    [(GPUImageEmbossFilter *)embossFilter setIntensity:0.2];
    [(GPUImageFilterGroup *)filterOldFilm addFilter:embossFilter];
    
    [sepiaFilter addTarget:borderFilter];
    [embossFilter addTarget:sepiaFilter];
    [transformFilter addTarget:embossFilter];
    
    [(GPUImageFilterGroup *)filterOldFilm setInitialFilters:[NSArray arrayWithObject:transformFilter]];
    [(GPUImageFilterGroup *)filterOldFilm setTerminalFilter:borderFilter];
    
    [transformFilter release];
    transformFilter = nil;
    [embossFilter release];
    embossFilter = nil;
    [sepiaFilter release];
    sepiaFilter = nil;
    [borderFilter release];
    borderFilter = nil;
    
    return filterOldFilm;
}

- (VideoThemes*) createThemeOldFilm
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = KThemeOldFilm;
    theme.thumbImageName = @"themeOldFilm";
    theme.name = @"Old Film";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.bgMusicFile = @"Swing Dance Two.mp3";
    theme.imageFile = nil;
    
    // Scroll text
    NSMutableArray *scrollText = [[NSMutableArray alloc] init];
    [scrollText addObject:(id)[self getStringFromDate:[NSDate date]]];
    [scrollText addObject:(id)[self getWeekdayFromDate:[NSDate date]]];
    [scrollText addObject:(id)@"It's a beautiful day!"];
    theme.scrollText = scrollText;
    
    [scrollText release];
    
    // Filter
//    theme.filter = [self createFilterOldFilm:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationScrollScreen], [NSNumber numberWithInt:kAnimationTextScroll], [NSNumber numberWithInt:kAnimationBlackWhiteDot], [NSNumber numberWithInt:kAnimationScrollLine], [NSNumber numberWithInt:kAnimationFlashScreen], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (GPUImageOutput<GPUImageInput> *) createFilterNiceDay:(BOOL)fromSystemCamera
{
    // Filter
    GPUImageTransformFilter *transformFilter = nil;
    if (fromSystemCamera)
    {
        // If this is from system camera, it will rotate 90c
        transformFilter = [[[GPUImageTransformFilter alloc] init] autorelease];
        [(GPUImageTransformFilter *)transformFilter setAffineTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [(GPUImageTransformFilter *)transformFilter setIgnoreAspectRatio:YES];
    }
    
    return transformFilter;
}

- (VideoThemes*) createThemeNiceDay
{
    VideoThemes *theme = [[[VideoThemes alloc] init] autorelease];
    theme.ID = kThemeNiceDay;
    theme.thumbImageName = @"themeNiceDay";
    theme.name = @"Nice day";
    theme.textStar = nil;
    theme.textSparkle = nil;
    theme.textGradient = @"Nice Day!";
    theme.bgMusicFile = @"Swing Dance.mp3";
    theme.imageFile = nil;
    theme.scrollText = nil;
    
    // Filter
//    theme.filter = [self createFilterNiceDay:fromSystemCamera];
    
    // Animation effects
    NSArray *aniActions = [NSArray arrayWithObjects:[NSNumber numberWithInt:kAnimationSpotlight], [NSNumber numberWithInt:kAnimationTextGradient], [NSNumber numberWithInt:kAnimationRipple], nil];
    theme.animationActions = [NSArray arrayWithArray:aniActions];
    
    return theme;
}

- (void) initThemesData
{
    self.themesDic = [NSMutableDictionary dictionaryWithCapacity:15];
    
    VideoThemes *theme = nil;
    for (int i = kThemeNone; i <= kThemeStarshine; ++i)
    {
        switch (i)
        {
            case kThemeNone:
            {
                // 0. 无
                break;
            }
            case kThemeMood:
            {
                // 心情
                theme = [self createThemeMood];
                break;
            }
            case kThemeNostalgia:
            {
                // 怀旧
                theme = [self createThemeNostalgia];
                break;
            }
            case KThemeOldFilm:
            {
                // 老电影
                theme = [self createThemeOldFilm];
                break;
            }
            case kThemeNiceDay:
            {
                // Nice day
                theme = [self createThemeNiceDay];
                break;
            }
            case kThemeSky:
            {
                // 星空
                theme = [self createThemeSky];
                break;
            }
            case kThemeFashion:
            {
                // 时尚
                theme = [self createThemeFashion];
                break;
            }
            case kThemeBirthday:
            {
                // 生日
                theme = [self createThemeBirthday];
                break;
            }
            case kThemeHeartbeat:
            {
                // 心动
                theme = [self createThemeHeartbeat];
                break;
            }
            case kThemeRomantic:
            {
                // 浪漫
                theme = [self createThemeRomantic];
                break;
            }
            case kThemeStarshine:
            {
                // 星光
                theme = [self createThemeStarshine];
                break;
            }
            case kThemeRain:
            {
                // 雨天
                theme = [self createThemeRain];
                break;
            }
            case kThemeFlower:
            {
                // 花语
                theme = [self createThemeFlower];
                break;
            }
            case kThemeClassic:
            {
                // 经典
                theme = [self createThemeClassic];
                break;
            }
            default:
                break;
        }
        
        if (i == kThemeNone)
        {
            [self.themesDic setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeNone]];
        }
        else
        {
            [self.themesDic setObject:theme forKey:[NSNumber numberWithInt:i]];
        }
    }
}

- (NSMutableDictionary*) initThemeFilter:(BOOL)fromSystemCamera
{
    NSMutableDictionary *themesFilter = [NSMutableDictionary dictionaryWithCapacity:15];
    
    for (int i = kThemeNone; i < self.themesDic.count; ++i)
    {
        switch (i)
        {
            case kThemeNone:
            {
                [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeNone]];
                break;
            }
            case kThemeMood:
            {
                // 心情
                GPUImageOutput<GPUImageInput> *filterMood = [self createFilterMood:fromSystemCamera];
                if (filterMood == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeMood]];
                }
                else
                {
                    [themesFilter setObject:filterMood forKey:[NSNumber numberWithInt:kThemeMood]];
                }
                
                break;
            }
            case kThemeNostalgia:
            {
                // 怀旧
                GPUImageOutput<GPUImageInput> *filterNostalgia = [self createFilterNostalgia:fromSystemCamera];
                if (filterNostalgia == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeNostalgia]];
                }
                else
                {
                    [themesFilter setObject:filterNostalgia forKey:[NSNumber numberWithInt:kThemeNostalgia]];
                }

                break;
            }
            case KThemeOldFilm:
            {
                // 老电影
                GPUImageOutput<GPUImageInput> *filterOldFilm = [self createFilterOldFilm:fromSystemCamera];
                if (filterOldFilm == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:KThemeOldFilm]];
                }
                else
                {
                    [themesFilter setObject:filterOldFilm forKey:[NSNumber numberWithInt:KThemeOldFilm]];
                }

                break;
            }
            case kThemeNiceDay:
            {
                // Nice day
                GPUImageOutput<GPUImageInput> *filterNiceDay = [self createFilterNiceDay:fromSystemCamera];
                if (filterNiceDay == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeNiceDay]];
                }
                else
                {
                    [themesFilter setObject:filterNiceDay forKey:[NSNumber numberWithInt:kThemeNiceDay]];
                }
                
                break;
            }
            case kThemeSky:
            {
                // 星空
                GPUImageOutput<GPUImageInput> *filterSky = [self createFilterSky:fromSystemCamera];
                if (filterSky == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeSky]];
                }
                else
                {
                    [themesFilter setObject:filterSky forKey:[NSNumber numberWithInt:kThemeSky]];
                }
                
                break;
            }
            case kThemeFashion:
            {
                // 时尚
                GPUImageOutput<GPUImageInput> *filterFashion = [self createFilterFashion:fromSystemCamera];
                if (filterFashion == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeFashion]];
                }
                else
                {
                    [themesFilter setObject:filterFashion forKey:[NSNumber numberWithInt:kThemeFashion]];
                }
                
                break;
            }
            case kThemeBirthday:
            {
                // 生日
                GPUImageOutput<GPUImageInput> *filterBirthday = [self createFilterBirthday:fromSystemCamera];
                if (filterBirthday == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeBirthday]];
                }
                else
                {
                    [themesFilter setObject:filterBirthday forKey:[NSNumber numberWithInt:kThemeBirthday]];
                }

                break;
            }
            case kThemeHeartbeat:
            {
                // 心动
                GPUImageOutput<GPUImageInput> *filterHeartbeat = [self createFilterHeartbeat:fromSystemCamera];
                if (filterHeartbeat == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeHeartbeat]];
                }
                else
                {
                    [themesFilter setObject:filterHeartbeat forKey:[NSNumber numberWithInt:kThemeHeartbeat]];
                }
                
                break;
            }
            case kThemeRomantic:
            {
                // 浪漫
                GPUImageOutput<GPUImageInput> *filterRomantic = [self createFilterRomantic:fromSystemCamera];
                if (filterRomantic == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeRomantic]];
                }
                else
                {
                    [themesFilter setObject:filterRomantic forKey:[NSNumber numberWithInt:kThemeRomantic]];
                }

                break;
            }
            case kThemeStarshine:
            {
                // 星光
                GPUImageOutput<GPUImageInput> *filterStarshine = [self createFilterStarshine:fromSystemCamera];
                if (filterStarshine == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeStarshine]];
                }
                else
                {
                    [themesFilter setObject:filterStarshine forKey:[NSNumber numberWithInt:kThemeStarshine]];
                }

                break;
            }
            case kThemeRain:
            {
                // 雨天
                GPUImageOutput<GPUImageInput> *filterRain = [self createFilterRain:fromSystemCamera];
                if (filterRain == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeRain]];
                }
                else
                {
                    [themesFilter setObject:filterRain forKey:[NSNumber numberWithInt:kThemeRain]];
                }
                
                break;
            }
            case kThemeFlower:
            {
                // 花语
                GPUImageOutput<GPUImageInput> *filterFlower = [self createFilterFlower:fromSystemCamera];
                if (filterFlower == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeFlower]];
                }
                else
                {
                    [themesFilter setObject:filterFlower forKey:[NSNumber numberWithInt:kThemeFlower]];
                }

                break;
            }
            case kThemeClassic:
            {
                // 经典
                GPUImageOutput<GPUImageInput> *filterClassic = [self createFilterClassic:fromSystemCamera];
                if (filterClassic == nil)
                {
                    [themesFilter setObject:[NSNull null] forKey:[NSNumber numberWithInt:kThemeClassic]];
                }
                else
                {
                    [themesFilter setObject:filterClassic forKey:[NSNumber numberWithInt:kThemeClassic]];
                }

                break;
            }
            default:
                break;
        }
    }

    return [themesFilter retain];
}

- (GPUImageOutput<GPUImageInput> *) createThemeFilter:(ThemesType)themeType fromSystemCamera:(BOOL)fromSystemCamera
{
    GPUImageOutput<GPUImageInput> *filter = nil;
    switch (themeType)
    {
        case kThemeNone:
        {
            break;
        }
        case kThemeMood:
        {
            filter = [self createFilterMood:fromSystemCamera];
            break;
        }
        case kThemeNostalgia:
        {
            filter = [self createFilterNostalgia:fromSystemCamera];
            break;
        }
        case KThemeOldFilm:
        {
            filter = [self createFilterOldFilm:fromSystemCamera];
            break;
        }
        case kThemeNiceDay:
        {
            filter = [self createFilterNiceDay:fromSystemCamera];
            break;
        }
        case kThemeSky:
        {
            filter = [self createFilterSky:fromSystemCamera];
            break;
        }
        case kThemeFashion:
        {
            filter = [self createFilterFashion:fromSystemCamera];
            break;
        }
        case kThemeBirthday:
        {
            filter = [self createFilterBirthday:fromSystemCamera];
            break;
        }
        case kThemeHeartbeat:
        {
            filter = [self createFilterHeartbeat:fromSystemCamera];
            break;
        }
        case kThemeRomantic:
        {
            filter = [self createFilterRomantic:fromSystemCamera];
            break;
        }
        case kThemeStarshine:
        {
            filter = [self createFilterStarshine:fromSystemCamera];
            break;
        }
        case kThemeRain:
        {
            filter = [self createFilterRain:fromSystemCamera];
            break;
        }
        case kThemeFlower:
        {
            filter = [self createFilterFlower:fromSystemCamera];
            break;
        }
        case kThemeClassic:
        {
            filter = [self createFilterClassic:fromSystemCamera];
            break;
        }
        default:
            break;
    }
    
    return filter;
}

- (NSMutableDictionary*) getThemeFilter:(BOOL)fromSystemCamera
{
    if (fromSystemCamera)
    {
        return self.filterFromSystemCamera;
    }
    else
    {
        return self.filterFromOthers;
    }
}

- (NSMutableDictionary*) getThemeData
{
    return self.themesDic;
}

@end
