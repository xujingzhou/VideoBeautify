//
//  NTViewController.h
//  GPUImageVideoStitchRec
//
//  Created by Nao Tokui on 6/16/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoComposition.h"

@interface NTViewController : UIViewController
{
    NSURL *_outputFileUrl;
}

@property (nonatomic, copy) NSURL *outputFileUrl;

- (id) initWithDelegate:(id)delegate;

- (void) removeLastTake;
- (void) stopRecording;

@end
