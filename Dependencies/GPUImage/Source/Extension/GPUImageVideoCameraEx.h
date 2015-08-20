
#import "GPUImageVideoCamera.h"

typedef enum
{
    GPUImageVideoCaptureNone,
    GPUImageVideoCapturing,
    GPUImageVideoCapturePaused,
    GPUImageVideoCaptureStopped
}GPUImageVideoStatus;

@interface GPUImageVideoCameraEx : GPUImageVideoCamera

@property (nonatomic, assign, getter = isFlash)BOOL flash;
@property (nonatomic)GPUImageVideoStatus status;

@end
