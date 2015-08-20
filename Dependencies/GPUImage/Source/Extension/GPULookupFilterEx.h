#import "GPUImageFilterGroup.h"
#import "GPUImagePicture.h"

@class GPUImageLookupFilterEx;
@interface GPULookupFilterEx : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
    GPUImageLookupFilterEx *lookupFilter;
}

@property (nonatomic, readwrite) CGFloat level;

- (instancetype)initWithName:(NSString *)name isWhiteAndBlack:(BOOL)isWhiteAndBlack;

@end
