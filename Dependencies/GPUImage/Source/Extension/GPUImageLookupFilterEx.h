#import "GPUImageLookupFilter.h"

@interface GPUImageLookupFilterEx : GPUImageLookupFilter
{
    GLint levelUniform;
    CGFloat _level;
}

@property(readwrite, nonatomic) CGFloat level;

@end
