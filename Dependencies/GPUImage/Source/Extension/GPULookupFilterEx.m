
#import "GPULookupFilterEx.h"
#import "GPUImageLookupFilterEx.h"
#import "GPUImageWBLookupFilterEx.h"
#import "UIImage+Additions.h"

@implementation GPULookupFilterEx

- (instancetype)initWithName:(NSString *)name isWhiteAndBlack:(BOOL)isWhiteAndBlack
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"lookup_%@", [name lowercaseString]]];
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    if (isWhiteAndBlack)
    {
        lookupFilter = [[GPUImageWBLookupFilterEx alloc] init];
    }
    else
    {
        lookupFilter = [[GPUImageLookupFilterEx alloc] init];
    }
    
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

-(void)prepareForImageCapture
{
    [lookupImageSource processImage];
//    [super prepareForImageCapture];
}

#pragma mark -
#pragma mark Accessors

- (CGFloat)level
{
    return lookupFilter.level;
}

- (void)setLevel:(CGFloat)level
{
    lookupFilter.level = level;
    [lookupImageSource processImage];
}

- (NSArray *)targets
{
    return lookupFilter.targets;
}

@end