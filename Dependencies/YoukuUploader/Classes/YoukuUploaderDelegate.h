//
//  YoukuUploaderDelegate.h
//  YoukuUploader
//
//  Created by silwings on 14-2-27.
//  Copyright (c) 2014年 wangcong. All rights reserved.
//

@protocol YoukuUploaderDelegate <NSObject>

@required

- (void) onStart;

- (void) onProgressUpdate:(int)progress;

- (void) onSuccess:(NSString*)vid;

- (void) onFailure:(NSDictionary*)response;

@end