
#import "GPUImageVideoCameraEx.h"

@implementation GPUImageVideoCameraEx

- (void)setFlash:(BOOL)flash
{
    self->_flash = flash;
    if (self.backFacingCameraPresent)
    {
        [GPUImageVideoCameraEx setTorch:_flash forCameraInPosition:AVCaptureDevicePositionBack];
    }
    else
    {
        [GPUImageVideoCameraEx setTorch:_flash forCameraInPosition:AVCaptureDevicePositionFront];
    }
}

- (void)startCameraCapture
{
    _status = GPUImageVideoCapturing;
    [super startCameraCapture];
}

- (void)pauseCameraCapture
{
    _status = GPUImageVideoCapturePaused;
    [super pauseCameraCapture];
}

- (void)resumeCameraCapture
{
    _status = GPUImageVideoCapturing;
    [super resumeCameraCapture];
}

- (void)stopCameraCapture
{
    _status = GPUImageVideoCaptureStopped;
    [super stopCameraCapture];
}

+ (void)setTorch:(BOOL)torch forCameraInPosition:(AVCaptureDevicePosition)position
{
    if ([[self cameraInPosition:position] hasTorch])
    {
        if ([[self cameraInPosition:position] lockForConfiguration:nil])
        {
            if (torch)
            {
                if ([[self cameraInPosition:position] isTorchModeSupported:AVCaptureTorchModeOn])
                {
                    [[self cameraInPosition:position] setTorchMode:AVCaptureTorchModeOn];
                }
            }
            else
            {
                if ([[self cameraInPosition:position] isTorchModeSupported:AVCaptureTorchModeOff])
                {
                    [[self cameraInPosition:position] setTorchMode:AVCaptureTorchModeOff];
                }
            }
            
            [[self cameraInPosition:position] unlockForConfiguration];
        }
    }
}

+ (AVCaptureDevice *)cameraInPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            return device;
        }
    }
    
    return nil;
}

@end
