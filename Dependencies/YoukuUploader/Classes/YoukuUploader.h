//
//  YoukuUploader.h
//  YoukuUploader
//
//  Created by silwings on 14-2-27.
//  Copyright (c) 2014年 wangcong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YoukuUploaderDelegate.h"

@interface YoukuUploader : NSObject {

}

+ (YoukuUploader*) sharedInstance;

- (void) setClientID:(NSString*)cid andClientSecret:(NSString*)secret;

- (void) upload:(NSDictionary*)params uploadInfo:(NSDictionary*)uploadInfo uploadDelegate:(id<YoukuUploaderDelegate>)uploadDelegate dispatchQueue:(dispatch_queue_t)dispatchQueue;
- (void) cancel;

@end


