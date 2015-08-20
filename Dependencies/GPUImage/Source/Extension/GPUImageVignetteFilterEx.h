#import "GPUImageFilter.h"

/** Performs a vignetting effect, fading out the image at the edges
 */
@interface GPUImageVignetteFilterEx : GPUImageFilter
{
    GLint vignetteCenterUniform, vignetteColorUniform, vignetteStartUniform, vignetteEndUniform, vignetteLevelUniform;
}

// the center for the vignette in tex coords (defaults to 0.5, 0.5)
@property (nonatomic, readwrite) CGPoint vignetteCenter;

// The color to use for the Vignette (defaults to black)
@property (nonatomic, readwrite) GPUVector3 vignetteColor;
@property (nonatomic, readwrite) CGFloat vignetteLevel;

// The normalized distance from the center where the vignette effect starts. Default of 0.5.
@property (nonatomic, readwrite) CGFloat vignetteStart;

// The normalized distance from the center where the vignette effect ends. Default of 0.75.
@property (nonatomic, readwrite) CGFloat vignetteEnd;

@end
