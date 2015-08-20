
#import "GPUImageFilter.h"

@interface GPUImageWaveFilter : GPUImageFilter
{
  GLint _normalizedPhaseUniform;
}

@property (nonatomic, assign) CGFloat normalizedPhase;

@end
