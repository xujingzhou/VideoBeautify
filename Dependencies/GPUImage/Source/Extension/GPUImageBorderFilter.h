
#import "GPUImageTwoInputFilter.h"
#import "GPUImagePicture.h"

@interface GPUImageBorderFilter : GPUImageTwoInputFilter
{
    GPUImagePicture *framePicture;
}

@property (nonatomic, readwrite, retain) UIImage *borderImage;

@end
