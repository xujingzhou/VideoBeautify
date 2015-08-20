
#import "GPUImageMovieWriter.h"

@interface GPUImageMovieWriterEx : GPUImageMovieWriter

@property (nonatomic, assign) BOOL started;
@property (readwrite) int32_t maxFrames; //为了计算进度

- (void)pauseRecording;
- (void)resumeRecording;
- (float)getProgress;

@end
