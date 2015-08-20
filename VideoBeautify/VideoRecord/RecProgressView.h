//
//  NTRecProgressView.h
//  GPUImageVideoStitchRec
//
//  Created by Nao Tokui on 6/16/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoComposition.h"

@interface NTRecProgressView : UIView

@property (nonatomic, strong) NTVideoComposition *composition;

- (void) clearAll;

@end
