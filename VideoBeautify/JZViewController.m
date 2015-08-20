//
//  JZViewController.m
//  VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 8/4/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#import "JZViewController.h"
#import "VideoEffect.h"
#import "ThemeScrollView.h"
//#import "VideoRecordViewController.h"
#import "PBJVideoPlayerController.h"
#import "MMProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "CMPopTipView.h"
#import "YoukuOAuthViewController.h"

@interface JZViewController()<ThemeScrollViewDelegate, PBJVideoPlayerControllerDelegate, CMPopTipViewDelegate, YoukuUploaderDelegate>
{
    NSURL* _videoPickURL;
    NSString* _mp4OutputPath;
    
    BOOL _hasVideo;
    BOOL _hasMp4;
    
    BOOL _fromSystemCamera;
    VideoEffect *_videoEffects;
    
    PBJVideoPlayerController *_videoPlayerController;
    UIImageView *_playButton;
    
    UIButton *_saveButton;
    
    dispatch_queue_t _queue;
}

@property (copy, nonatomic) NSString *uploaderUrl;
@property (copy, nonatomic) NSURL *uploaderThumbnailUrl;
@property (retain, nonatomic) UIImage *videoThumbnailImage;
@property (assign, nonatomic) BOOL hasUploadedUrl;

@property (copy, nonatomic) NSURL* videoPickURL;
@property (copy, nonatomic) NSString* mp4OutputPath;
@property (assign, nonatomic) BOOL hasVideo;
@property (assign, nonatomic) BOOL hasMp4;

@property (assign, nonatomic) BOOL fromSystemCamera;
@property (retain, nonatomic) VideoEffect *videoEffects;

@property (retain, nonatomic) UIView *viewToolbar;
@property (retain, nonatomic) UIButton *takeVideo;
@property (retain, nonatomic) UIButton *toggleEffects;
@property (retain, nonatomic) UIButton *openCameraRoll;
@property (retain, nonatomic) UIImageView *imageViewToolbarBG;
@property (retain, nonatomic) UIButton *titleCameraRoll;
@property (retain, nonatomic) UIButton *titleEffects;
@property (retain, nonatomic) UIButton *titleSave;
@property (retain, nonatomic) UIButton *share;
@property (retain, nonatomic) UIButton *titleShare;

@property (retain, nonatomic) UIImageView *imageViewPreview;

@property (retain, nonatomic) ThemeScrollView *frameScrollView;

@property (retain, nonatomic) CMPopTipView *popTipView;

- (NSInteger)getFileSize:(NSString*)path;
- (CGFloat)getVideoDuration:(NSURL*)URL;
- (NSString*)getOutputFilePath;

@end

@implementation JZViewController

@synthesize videoPickURL = _videoPickURL;
@synthesize mp4OutputPath = _mp4OutputPath;
@synthesize hasVideo = _hasVideo;
@synthesize hasMp4 = _hasMp4;
@synthesize fromSystemCamera = _fromSystemCamera;
@synthesize videoEffects = _videoEffects;

#pragma mark - Video effects status
- (void)AVAssetExportMP4SessionStatusFailed:(id)object
{
    NSString *failed = NSLocalizedString(@"failed", nil);
    [self dismissProgressBar:failed];
    
    // Dispose memory
    [self.videoEffects clearAll];
    
    NSString *ok = NSLocalizedString(@"ok", nil);
    NSString *msgFailed =  NSLocalizedString(@"msgConvertFailed", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:failed message:msgFailed
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:ok, nil];
    [alert show];
    [alert release];
    
    NSLog(@"videoPickURL is:%@", self.videoPickURL);
}

- (void)AVAssetExportMP4SessionStatusCompleted:(id)object
{
    // Dispose memory
    [self.videoEffects clearAll];
    self.hasMp4 = YES;
    
    
    NSString *success = NSLocalizedString(@"success", nil);
    [self dismissProgressBar:success];
    [self playMp4Video];
}

- (void)AVAssetExportMP4ToAlbumStatusCompleted:(id)object
{
    NSString *success = NSLocalizedString(@"success", nil);
    NSString *msgSuccess =  NSLocalizedString(@"msgSuccess", nil);
    NSString *ok = NSLocalizedString(@"ok", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:success message:msgSuccess
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:ok, nil];
    [alert show];
    [alert release];
}

- (void)AVAssetExportMP4ToAlbumStatusFailed:(id)object
{
    NSString *failed = NSLocalizedString(@"failed", nil);
    NSString *msgFailed =  NSLocalizedString(@"msgFailed", nil);
    NSString *ok = NSLocalizedString(@"ok", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: failed message:msgFailed
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:ok, nil];
    [alert show];
    [alert release];
}

#pragma mark - Progress callback
- (void)retrievingProgressFilter:(id)progress
{
    if (progress && [progress isKindOfClass:[NSNumber class]])
    {
//        NSLog(@"ProgressFilter Text: %f", [progress floatValue]);
        
        NSString *title = NSLocalizedString(@"filter", nil);
        [self updateProgressBarTitle:title status:[NSString stringWithFormat:@"%d%%", (int)([progress floatValue] * 100)]];
    }
}

- (void)retrievingProgressMP4:(id)progress
{
    if (progress && [progress isKindOfClass:[NSNumber class]])
    {
//        NSLog(@"ProgressEffect Text: %f", [progress floatValue]);
        
        NSString *title = NSLocalizedString(@"effect", nil);
        [self updateProgressBarTitle:title status:[NSString stringWithFormat:@"%d%%", (int)([progress floatValue] * 100)]];
    }
}

#pragma mark - Progress Bar
- (void) showProgressBar:(NSString*)title status:(NSString*)status
{
    if (arc4random()%(int)2)
    {
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingLeft];
    }
    else
    {
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingRight];
    }
    
    // Cancelable
    MMProgressHUD *hud = [MMProgressHUD sharedHUD];
    hud.confirmationMessage = @"Cancel?";
    hud.cancelBlock = ^{
        NSLog(@"Task was cancelled!");
    };
}

- (void) setProgressBarDefaultStyle
{
    if (arc4random()%(int)2)
    {
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingLeft];
    }
    else
    {
        [MMProgressHUD setPresentationStyle:MMProgressHUDPresentationStyleSwingRight];
    }
}

- (void) updateProgress:(CGFloat)value
{
     [MMProgressHUD updateProgress:value];
}

- (void) updateProgressBarTitle:(NSString*)title status:(NSString*)status
{
    [MMProgressHUD updateTitle:title status:status];
}

- (void) dismissProgressBarbyDelay:(NSTimeInterval)delay
{
    [MMProgressHUD dismissAfterDelay:delay];
}

- (void) dismissProgressBar:(NSString*)status
{
    [MMProgressHUD dismissWithSuccess:status];
}

#pragma mark - private Method
- (void) createAssetsAlbumGroupWithName:(NSString*)name
                          assertLibrary:(ALAssetsLibrary*)assertLibrary
            enumerateGroupsFailureBlock:(void (^) (NSError *error))enumerateGroupsFailureBlock
                    hasTheNewGroupBlock:(void (^) (ALAssetsGroup *group))hasGroup
                   createSuccessedBlock:(void (^) (ALAssetsGroup *group))createSuccessedBlock
                      createFaieldBlock:(void (^) (NSError *error))createFaieldBlock
{
    __block BOOL hasTheNewGroup = NO;
    
    [assertLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         hasTheNewGroup = [name isEqualToString:[group valueForProperty:ALAssetsGroupPropertyName]];
         if (hasTheNewGroup)
         {
             hasGroup(group);
             *stop = YES;
         }
         
         if (!group && !hasTheNewGroup && !*stop)
         {
             
             [assertLibrary addAssetsGroupAlbumWithName:name resultBlock:^(ALAssetsGroup *agroup)
              {
                  createSuccessedBlock(agroup);
                  
              } failureBlock:^(NSError *error)
              {
                  createFaieldBlock(error);
              }];
         }
     } failureBlock:^(NSError *error)
     {
         
         enumerateGroupsFailureBlock(error);
     }];
}

- (void) addVideoToAssetGroupWithAssetUrl:(NSURL*)assetURL
                            assertLibrary:(ALAssetsLibrary*)assertLibrary
                                  toAlbum:(NSString*)name
                          addSuccessBlock:(void (^) (ALAssetsGroup *targetGroup, NSURL *currentAssetUrl, ALAsset *currentAsset))addSuccessBlock
                           addFaieldBlock:(void (^) (NSError *error))addFaieldBlock
{
    
    [self createAssetsAlbumGroupWithName:name
                           assertLibrary:assertLibrary
             enumerateGroupsFailureBlock:^(NSError *error)
     {
         if (error)
         {
             addFaieldBlock(error);
             return ;
         }
     } hasTheNewGroupBlock:^(ALAssetsGroup *group)
     {
         
         [assertLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset)
          {
              [group addAsset:asset];
              addSuccessBlock(group,assetURL,asset);
              
          } failureBlock:^(NSError *error)
          {
              if (error)
              {
                  addFaieldBlock(error);
                  return ;
              }
          }];
     } createSuccessedBlock:^(ALAssetsGroup *group)
     {
         
         [assertLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset)
          {
              [group addAsset:asset];
              addSuccessBlock(group,assetURL,asset);
              
          } failureBlock:^(NSError *error)
          {
              if (error)
              {
                  addFaieldBlock(error);
                  return ;
              }
          }];
     } createFaieldBlock:^(NSError *error)
     {
         if (error)
         {
             addFaieldBlock(error);
             return ;
         }
     }];
}

- (void) writeExportedVideoToAssetsLibrary:(NSString *)outputURL
{
    __unsafe_unretained typeof(self) weakSelf = self;
	NSURL *exportURL = [NSURL fileURLWithPath:outputURL];
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL])
    {
		[library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error)
         {
             if (error)
             {
                 [weakSelf AVAssetExportMP4ToAlbumStatusFailed:error];
             }
             else
             {
                 NSString *albumGroupName = @"VideoBeautify";
                 [weakSelf addVideoToAssetGroupWithAssetUrl:assetURL
                                              assertLibrary:library
                                                    toAlbum:albumGroupName
                                            addSuccessBlock:^(ALAssetsGroup *targetGroup, NSURL *currentAssetUrl, ALAsset *currentAsset)
                  {
                      [weakSelf AVAssetExportMP4ToAlbumStatusCompleted:error];
                      
                  } addFaieldBlock:^(NSError *error)
                  {
                    
                  }];
             }
         }];
	}
    else
    {
		NSLog(@"Video could not be exported to camera roll.");
	}
    
    [library release];
    library = nil;
}

- (NSInteger)getFileSize:(NSString*)path
{
    NSFileManager * filemanager = [[[NSFileManager alloc]init] autorelease];
    if([filemanager fileExistsAtPath:path])
    {
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return  [theFileSize intValue]/1024;
        else
            return -1;
    }
    else
    {
        return -1;
    }
}

- (CGFloat)getVideoDuration:(NSURL*)URL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:URL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    
    return second;
}

- (NSString*)getOutputFilePath
{
//    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
//    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
//    NSString *path = [NSString stringWithFormat: @"output-%@.mp4", [formater stringFromDate:[NSDate date]]];
//    NSString* mp4OutputFile = [[NSTemporaryDirectory() stringByAppendingPathComponent:path] retain];
//    [formater release];
    
    NSString *path = @"outputMovie.mp4";
    NSString* mp4OutputFile = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
    
    return mp4OutputFile;
}

-(void)pickVideoFromCameraRoll
{
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	picker.allowsEditing = YES;
	
	picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
        // Only movie
        NSArray* availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        picker.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];
    }
    
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)pickVideoFromCamera
{
//    if (iOS5)
//    {
        [self pickVideoFromSystemCamera];
//    }
//    else
//    {
//         NTViewController *videoRecordVC = [[NTViewController alloc] initWithDelegate:self];
//        [self presentModalViewController:videoRecordVC animated:NO];
//    }
}

- (void)pickVideoFromSystemCamera
{
    UIImagePickerController* pickerView = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        pickerView.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        NSArray* availableMedia = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        pickerView.mediaTypes = [NSArray arrayWithObject:availableMedia[1]];
    }
    else
    {
        [pickerView release];
        NSLog(@"Camera not exist in this device.");
        return;
    }
    
    pickerView.videoQuality = UIImagePickerControllerQualityTypeMedium;
    [self presentModalViewController:pickerView animated:YES];
    
    pickerView.videoMaximumDuration = kMaxRecordDuration;
    pickerView.delegate = self;
    [pickerView release];
}

- (void) pickVideoFromCameraComplete:(id)inputFileUrl
{
    [self dismissModalViewControllerAnimated:NO];
    
    if (inputFileUrl && ![inputFileUrl isFileURL])
    {
        NSLog(@"Input file from camera is invalid.");
        return;
    }
    
    self.videoPickURL = inputFileUrl;
    self.mp4OutputPath = [self getOutputFilePath];
    self.hasVideo = YES;
    
    self.toggleEffects.enabled = TRUE;
    [self getPreviewImage:inputFileUrl];
}

- (void) buildVideoEffect:(ThemesType)curThemeType
{
//    NSString *inputFile = @"happy_04971.m4v";
    
    if (_videoEffects)
    {
        [_videoEffects release];
        _videoEffects = nil;
    }
    
    self.videoEffects = [[VideoEffect alloc] initWithDelegate:self];
    self.videoEffects.themeCurrentType = curThemeType;
    [self.videoEffects buildVideoBeautify:self.mp4OutputPath inputVideoURL:self.videoPickURL fromSystemCamera:self.fromSystemCamera];
}

- (void) playMp4Video
{
    if (!_hasMp4)
    {
        NSLog(@"Mp4 file not found!");
        return;
    }
    
    NSLog(@"%@",[NSString stringWithFormat:@"Play file is %@", _mp4OutputPath]);
    
    [self showVideoPlayView:TRUE];
    _videoPlayerController.videoPath = _mp4OutputPath;
//    _videoPlayerController.playbackLoops = YES;
    [_videoPlayerController playFromBeginning];
}

-(void) getPreviewImage:(NSURL *)url
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    // Test (save to png file)
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSData *dataForPNGFile = UIImagePNGRepresentation(img);
//    if (![dataForPNGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:@"snapVideo.png"] options:NSAtomicWrite error:&error])
//    {
//        NSLog(@"Error: Couldn't save snap image.");
//    }
//    else
//    {
//        NSLog(@"Success: saved snap image.");
//    }

    _imageViewPreview.image = img;
    
    [asset release];
    [img release];
    [gen release];
}

- (UIImage*) getImageForVideoFrame:(NSString *)videoFilePath atTime:(CMTime)time
{
    NSURL *inputUrl = [NSURL fileURLWithPath:videoFilePath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputUrl options:nil];
    NSParameterAssert(asset);
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
    {
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    }
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    if (thumbnailImageRef)
    {
        CGImageRelease(thumbnailImageRef);
    }
    
    return thumbnailImage;
}

- (UIImage *) scaleFromImage:(UIImage *)image toSize:(CGSize)size
{
    if (image == nil)
    {
        return nil;
    }
    
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - Weixi
-(BOOL)isWXAppInstalled
{
    return [WXApi isWXAppInstalled];
}

-(void)shareWeixiFriendGroup
{
    WXMediaMessage *message = [WXMediaMessage message];
    NSString *title = @"Created by VideoBeautify";
    message.title = title;
    message.description = nil;
    
    if (self.videoThumbnailImage != nil)
    {
        [message setThumbImage: self.videoThumbnailImage];
    }
    
    if (self.videoThumbnailImage == nil)
    {
        NSURL *thumbnailImageUrl = self.uploaderThumbnailUrl;
        UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:thumbnailImageUrl]];
        [message setThumbImage:image];
    }
    
    WXVideoObject *ext = [WXVideoObject object];
    NSString *webUrl = self.uploaderUrl;
    ext.videoUrl = webUrl;
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneTimeline;
    
    [WXApi sendReq:req];
}

- (void)retrievingProgress:(int)progress
{
    if (progress)
    {
        NSString *title = NSLocalizedString(@"uploading", nil);
        [self updateProgressBarTitle:title status:[NSString stringWithFormat:@"%d%%", progress]];
    }
}

#pragma mark - YoukuUploaderDelegate
- (void) onStart
{
    NSLog(@"Upload start");
}

- (void) onProgressUpdate:(int)progress
{
    [self retrievingProgress:progress];
}

- (void) onSuccess:(NSString*)vid
{
    NSLog(@"Upload success: %@", vid);
    
    // Enable
    self.share.enabled = YES;
    self.titleShare.enabled = YES;
    
    if (!isStringEmpty(vid))
    {
        [self searchUploadedYouKuVideoByVid:vid];
        
        NSString *success = NSLocalizedString(@"success", nil);
        [self dismissProgressBar:success];
    }
}

- (void) onFailure:(NSDictionary*)response
{
    NSLog(@"Upload failed: %@", [response objectForKey:@"desc"]);
    
    int errConnectCode = [[response objectForKey:@"code"] integerValue];
    if (50002 == errConnectCode)
    {
        // Authorize
        [self authorizeYouku];
        
        NSString *success = NSLocalizedString(@"success", nil);
        [self dismissProgressBar:success];
    }
    else
    {
        NSString *failed = NSLocalizedString(@"failed", nil);
        [self dismissProgressBar:failed];
    }
    
    // Enable
    self.share.enabled = YES;
    self.titleShare.enabled = YES;
}

#pragma mark - YoukuUploader
- (void) searchUploadedYouKuVideoByVid:(NSString*)vid
{
    __block NSArray *dataVideos = nil;
    NSURL *url = [NSURL URLWithString:kApiYoukuBasePath];
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:url];
    NSDictionary *credential = [[NSUserDefaults standardUserDefaults] objectForKey:kOAuthCredential];
    NSDictionary *propertes = @{@"client_id": kYoukuAppKey,
                                @"access_token": [credential objectForKey:kOAuthAccessToken]};
    [client getPath:kApiYoukuMyVideos parameters:propertes success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         id json = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
         //         NSLog(@"json = %@", json);
         
         dataVideos = [json objectForKey:@"videos"];
         if (dataVideos == nil || [dataVideos count] < 1)
         {
             NSLog(@"Uploaded videos is empty.");
             return;
         }
         
         for (NSDictionary *dic in dataVideos)
         {
             NSString *id = [dic objectForKey:@"id"];
             if ([vid isEqualToString:id])
             {
                 NSLog(@"uploaded Video: %@", dic);
                 
                 self.uploaderUrl = [dic objectForKey:@"link"];
                 NSLog(@"uploaderUrl: %@", self.uploaderUrl);
                 
                 self.uploaderThumbnailUrl = [NSURL URLWithString:[dic objectForKey:@"thumbnail"]];
                 NSLog(@"uploaderThumbnailUrl: %@", self.uploaderThumbnailUrl);
                 
                 self.hasUploadedUrl = YES;
                 
                 // Share to Weixi
                 [self shareWeixiFriendGroup];
             }
         }
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"error : %@", error);
         
         NSString *failed = NSLocalizedString(@"failed", nil);
         NSString *errorContent = NSLocalizedString(@"YoukuOAuthFailed", nil);
         [self popAlert:errorContent title:failed];
     }];
}

- (void)uploadVideoToYouKu
{
    NSLog(@"uploadVideoToYouKu");
    
    if (self.videoPickURL && [self.videoPickURL isFileURL])
    {
        [[YoukuUploader sharedInstance] setClientID:kYoukuAppKey andClientSecret:kYoukuAppScrect];
        
        NSDictionary *credential = [[NSUserDefaults standardUserDefaults] objectForKey:kOAuthCredential];
        NSString *accessToken = [credential objectForKey:kOAuthAccessToken];
        NSString *username = @"";
        NSString *password = @"";
        NSMutableDictionary *uploadParams = [NSMutableDictionary dictionaryWithCapacity:3];
        if (isStringEmpty(accessToken))
        {
            [uploadParams setObject:@"" forKey:@"access_token"];
        }
        else
        {
            [uploadParams setObject:accessToken forKey:@"access_token"];
        }
        [uploadParams setObject:username forKey:@"username"];
        [uploadParams setObject:password forKey:@"password"];
        
        NSString *title = @"Created by VideoBeautify";
        NSString *tags = @"VideoBeautify";
        NSString *fileName = [self.videoPickURL path];
        NSMutableDictionary *uploadInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        [uploadInfo setObject:title forKey:@"title"];
        [uploadInfo setObject:tags forKey:@"tags"];
        [uploadInfo setObject:fileName forKey:@"file_name"];
        
        _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        [[YoukuUploader sharedInstance] upload:uploadParams uploadInfo:uploadInfo uploadDelegate:self dispatchQueue:_queue];
    }
}

-(void) popAlert:(NSString*)content title:(NSString*)title
{
    NSString *ok = NSLocalizedString(@"ok", nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:content
                                                   delegate:nil
                                          cancelButtonTitle:ok
                                          otherButtonTitles:nil];
    [alert show];
}

- (void) authorizeYouku
{
    YoukuOAuthViewController *nextController = [[YoukuOAuthViewController alloc] init];
    [self.navigationController pushViewController:nextController animated:YES];
}

#pragma mark - CMPopTipViewDelegate methods
- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    
}

#pragma mark - ThemeScrollView Delegate
- (void)themeScrollView:(ThemeScrollView *)themeScrollView didSelectMaterial:(VideoThemes *)videoTheme
{
    if (!_hasVideo)
    {
        NSLog(@"There haven't any video now.");
        return;
    }
    
    ThemesType curThemeType = kThemeNone;
    if ((NSNull*)videoTheme != [NSNull null])
    {
        curThemeType = (ThemesType)videoTheme.ID;
    }
    
    if (curThemeType == kThemeNone)
    {
        NSLog(@"curThemeType is empty.");
        return;
    }
    
    // Progress bar
    [self setProgressBarDefaultStyle];
    NSString *title = NSLocalizedString(@"Processing", nil);
    [self updateProgressBarTitle:title status:@""];
    
    // Pause play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController pause];
    }
    
     // Build video effect
    [self buildVideoEffect:curThemeType];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 1.
    [self dismissModalViewControllerAnimated:YES];
    
    NSLog(@"info = %@",info);
    
    // 2.
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if([mediaType isEqualToString:@"public.movie"])
	{
		NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        
        if (url && ![url isFileURL])
        {
            NSLog(@"Input file from camera is invalid.");
            return;
        }
        
        if ([self getVideoDuration:url] > kMaxRecordDuration)
        {
            NSString *ok = NSLocalizedString(@"ok", nil);
            NSString *error = NSLocalizedString(@"error", nil);
            NSString *fileLenHint = NSLocalizedString(@"fileLenHint", nil);
            NSString *seconds = NSLocalizedString(@"seconds", nil);
            NSString *hint = [fileLenHint stringByAppendingFormat:@" %d ", kMaxRecordDuration];
            hint = [hint stringByAppendingString:seconds];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:error
                                                            message:hint
                                                           delegate:nil
                                                  cancelButtonTitle:ok
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
            
            return;
        }
        
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        {
             self.fromSystemCamera = TRUE;
        }
        else if(picker.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum)
        {
             self.fromSystemCamera = FALSE;
        }
        else
        {
             self.fromSystemCamera = FALSE;
        }
        
        // Remove last file
        if (self.videoPickURL && [self.videoPickURL isFileURL])
        {
            if ([[NSFileManager defaultManager] removeItemAtURL:self.videoPickURL error:nil])
            {
                NSLog(@"Success for delete old pick file: %@", self.videoPickURL);
            }
            else
            {
                NSLog(@"Failed for delete old pick file: %@", self.videoPickURL);
            }
        }
        
		self.videoPickURL = url;
        self.mp4OutputPath = [self getOutputFilePath];
        self.hasVideo = YES;
		
        [self showVideoPlayView:FALSE];
        
        self.toggleEffects.enabled = TRUE;
        self.frameScrollView.hidden = FALSE;
        [self getPreviewImage:url];
	}
	else
	{
		NSLog(@"Error media type");
		return;
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - IBAction Methods
- (void)handleActionTakeEffects
{
    NSLog(@"handleActionToggleEffects");
    
    if (_hasVideo)
    {
        self.frameScrollView.hidden = !self.frameScrollView.hidden;
    }
}

- (void)handleActionTakeVideo
{
    NSLog(@"handleActionTakeVideo");
    
    // Pick a video from camera
    [self pickVideoFromCamera];
}

- (void)handleActionOpenCameraRoll
{
    NSLog(@"handleActionOpenCameraRoll");
    
    // Pick a video from camera roll
    [self pickVideoFromCameraRoll];
}

- (void) handleActionSavetoAlbums
{
    if (_hasMp4)
    {
        [self writeExportedVideoToAssetsLibrary:_mp4OutputPath];
    }
}

- (void) handleActionShare
{
    if (_hasMp4)
    {
        if (![self isWXAppInstalled])
        {
            NSString *failed = NSLocalizedString(@"failed", nil);
            NSString *Error = NSLocalizedString(@"WeixiInstallError", nil);
            [self popAlert:Error title:failed];
            return;
        }
        
        // Disable first
        self.share.enabled = NO;
        self.titleShare.enabled = NO;
        
        // Progress bar
        [self setProgressBarDefaultStyle];
        NSString *title = NSLocalizedString(@"Processing", nil);
        [self updateProgressBarTitle:title status:@""];
        
        UIImage *image = [self getImageForVideoFrame:_mp4OutputPath atTime:CMTimeMake(1, 1)];
        CGFloat scaleFactor = MIN(170/image.size.width, 170/image.size.height);
        self.videoThumbnailImage = [self scaleFromImage:image toSize:CGSizeMake(image.size.width*scaleFactor, image.size.height*scaleFactor)];
        
        [self uploadVideoToYouKu];
    }
}

#pragma mark - PBJVideoPlayerControllerDelegate
- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //NSLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{
    _playButton.alpha = 1.0f;
    _playButton.hidden = NO;
    
    [UIView animateWithDuration:0.1f animations:^{
        _playButton.alpha = 0.0f;
    } completion:^(BOOL finished)
    {
        _playButton.hidden = YES;
        
        // Hide themes
        if (!self.frameScrollView.hidden)
        {
            self.frameScrollView.hidden = YES;
        }
    }];
}

- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    _playButton.hidden = NO;
    
    [UIView animateWithDuration:0.1f animations:^{
        _playButton.alpha = 1.0f;
    } completion:^(BOOL finished)
    {
        // Show themes
        if (self.frameScrollView.hidden)
        {
            self.frameScrollView.hidden = NO;
        }
    }];
}

#pragma mark - App NSNotifications
- (void)_applicationWillEnterForeground:(NSNotification *)notification
{
    NSLog(@"applicationWillEnterForeground");
    
    [self.videoEffects resume];
    
    // Resume play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePaused)
    {
        [_videoPlayerController playFromCurrentTime];
    }
    
    [self dismissProgressBar:@"Failed!"];
    
    // Show themes
    if (_hasVideo)
    {
        if (self.frameScrollView.hidden)
        {
            self.frameScrollView.hidden = NO;
        }
    }
}

- (void)_applicationDidEnterBackground:(NSNotification *)notification
{
    NSLog(@"applicationDidEnterBackground");
 
    [self.videoEffects pause];
    
    // Pause play
    if (_videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying)
    {
        [_videoPlayerController pause];
    }
}

#pragma mark - View lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        
    }
    return self;
}

-(id) init
{
    if (self = [super init])
    {
        self.fromSystemCamera = FALSE;
        
        self.hasVideo = NO;
        self.hasMp4 = NO;
        self.videoPickURL = nil;
        self.mp4OutputPath = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground:) name:@"UIApplicationWillEnterForegroundNotification" object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:@"UIApplicationDidEnterBackgroundNotification" object:[UIApplication sharedApplication]];
    }
    
	return self;
}

- (void)initToolbarView
{
//    CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
    BOOL hideStatus = [UIApplication sharedApplication].isStatusBarHidden;
    CGFloat orginHeight = self.view.frame.size.height - toolbarHeight;
    if (hideStatus)
    {
        orginHeight += 20; //rectStatus.size.height;
    }
    _viewToolbar = [[UIView alloc] initWithFrame:CGRectMake(0, orginHeight, self.view.frame.size.width, toolbarHeight)];
    _viewToolbar.backgroundColor = [UIColor clearColor];
    
    _imageViewToolbarBG = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"toolbar_bkg"]];
    _imageViewToolbarBG.frame = CGRectMake(0, 0, _viewToolbar.frame.size.width, _viewToolbar.frame.size.height);
    [_imageViewToolbarBG setUserInteractionEnabled:NO];
    
    UIImage *imageEffectsUp = [UIImage imageNamed:@"drawerOpen_up"];
    _toggleEffects = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, imageEffectsUp.size.width, imageEffectsUp.size.height)];
    [_toggleEffects setImage:imageEffectsUp forState:(UIControlStateNormal)];
    [_toggleEffects setImage:[UIImage imageNamed:@"drawerOpen_down"] forState:(UIControlStateSelected)];
    [_toggleEffects addTarget:self action:@selector(handleActionTakeEffects) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect rectEffects = CGRectMake(_toggleEffects.frame.origin.x, _toggleEffects.frame.origin.y+_toggleEffects.frame.size.height, _toggleEffects.frame.size.width, 15);
    NSString *textEffects = NSLocalizedString(@"Theme", nil);
    _titleEffects = [[UIButton alloc] initWithFrame:rectEffects];
    [_titleEffects setBackgroundColor:[UIColor clearColor]];
    [_titleEffects setTitleColor:[UIColor darkGrayColor]forState:UIControlStateNormal];
    _titleEffects.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    _titleEffects.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleEffects setTitle:textEffects forState: UIControlStateNormal];
    [_titleEffects addTarget:self action:@selector(handleActionTakeEffects) forControlEvents:UIControlEventTouchUpInside];
  
    
    UIImage *imageCameraRollUp = [UIImage imageNamed:@"cameraRoll_up"];
    _openCameraRoll = [[UIButton alloc] initWithFrame:CGRectMake(_toggleEffects.frame.origin.x + _toggleEffects.bounds.size.width + 10, 0, imageCameraRollUp.size.width, imageCameraRollUp.size.height)];
    [_openCameraRoll setImage:imageCameraRollUp forState:(UIControlStateNormal)];
    [_openCameraRoll setImage:[UIImage imageNamed:@"cameraRoll_down"] forState:(UIControlStateSelected)];
    [_openCameraRoll addTarget:self action:@selector(handleActionOpenCameraRoll) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect rectCameraRoll = CGRectMake(_openCameraRoll.frame.origin.x, _openCameraRoll.frame.origin.y+_openCameraRoll.frame.size.height, _openCameraRoll.frame.size.width, 15);
    NSString *textCameraRoll = NSLocalizedString(@"Album", nil);
    _titleCameraRoll = [[UIButton alloc] initWithFrame:rectCameraRoll];
    [_titleCameraRoll setBackgroundColor:[UIColor clearColor]];
    [_titleCameraRoll setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    _titleCameraRoll.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    _titleCameraRoll.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleCameraRoll setTitle:textCameraRoll forState: UIControlStateNormal];
    [_titleCameraRoll addTarget:self action:@selector(handleActionOpenCameraRoll) forControlEvents:UIControlEventTouchUpInside];

    
    UIImage *imageTakeVideoUp = [UIImage imageNamed:@"cameraButton_ready"];
    _takeVideo = [[UIButton alloc] initWithFrame:CGRectMake(_viewToolbar.bounds.size.width/2 - imageTakeVideoUp.size.width/2, _viewToolbar.frame.size.height - imageTakeVideoUp.size.height - 3, imageTakeVideoUp.size.width, imageTakeVideoUp.size.height)];
    [_takeVideo setImage:imageTakeVideoUp forState:(UIControlStateNormal)];
    [_takeVideo setImage:[UIImage imageNamed:@"cameraButton_take"] forState:(UIControlStateSelected)];
    [_takeVideo addTarget:self action:@selector(handleActionTakeVideo) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIImage *imageShare = [UIImage imageNamed:@"share_down"];
    _share = [[UIButton alloc] initWithFrame:CGRectMake(_viewToolbar.bounds.size.width - (imageShare.size.width + 10)*2, 0, imageShare.size.width, imageShare.size.height)];
    [_share setImage:imageShare forState:(UIControlStateNormal)];
    [_share addTarget:self action:@selector(handleActionShare) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect rectShare = CGRectMake(_share.frame.origin.x, _share.frame.origin.y+_share.frame.size.height, _share.frame.size.width, 15);
    NSString *textShare = NSLocalizedString(@"share", nil);
    _titleShare = [[UIButton alloc] initWithFrame:rectShare];
    [_titleShare setBackgroundColor:[UIColor clearColor]];
    [_titleShare setTitleColor:[UIColor darkGrayColor]forState:UIControlStateNormal];
    _titleShare.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    _titleShare.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleShare setTitle:textShare forState: UIControlStateNormal];
    [_titleShare addTarget:self action:@selector(handleActionShare) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIImage *imageSaveUp = [UIImage imageNamed:@"saveCameraRoll_up"];
    _saveButton = [[UIButton alloc] initWithFrame:CGRectMake(_viewToolbar.bounds.size.width - imageSaveUp.size.width - 10, 0, imageSaveUp.size.width, imageSaveUp.size.height)];
    [_saveButton setImage:imageSaveUp forState:(UIControlStateNormal)];
    [_saveButton setImage:[UIImage imageNamed:@"saveCameraRoll_down"] forState:(UIControlStateSelected)];
    [_saveButton setImage:[UIImage imageNamed:@"saveCameraRoll_disabled"] forState:(UIControlStateHighlighted)];
    [_saveButton addTarget:self action:@selector(handleActionSavetoAlbums) forControlEvents:UIControlEventTouchUpInside];

    CGRect rectSave = CGRectMake(_saveButton.frame.origin.x, _saveButton.frame.origin.y+_saveButton.frame.size.height, _saveButton.frame.size.width, 15);
    NSString *textSave = NSLocalizedString(@"Save", nil);
    _titleSave = [[UIButton alloc] initWithFrame:rectSave];
    [_titleSave setBackgroundColor:[UIColor clearColor]];
    [_titleSave setTitleColor:[UIColor darkGrayColor]forState:UIControlStateNormal];
    _titleSave.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    _titleSave.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleSave setTitle:textSave forState: UIControlStateNormal];
    [_titleSave addTarget:self action:@selector(handleActionSavetoAlbums) forControlEvents:UIControlEventTouchUpInside];
    
    [_viewToolbar addSubview:_imageViewToolbarBG];
    [_viewToolbar addSubview:_toggleEffects];
    [_viewToolbar addSubview:_titleEffects];
    [_viewToolbar addSubview:_takeVideo];
    [_viewToolbar addSubview:_openCameraRoll];
    [_viewToolbar addSubview:_titleCameraRoll];
    [_viewToolbar addSubview:_share];
    [_viewToolbar addSubview:_titleShare];
    [_viewToolbar addSubview:_saveButton];
    [_viewToolbar addSubview:_titleSave];
    [self.view addSubview:_viewToolbar];
    
    [_imageViewToolbarBG release];
    [_toggleEffects release];
    [_titleEffects release];
    [_takeVideo release];
    [_openCameraRoll release];
    [_titleCameraRoll release];
    [_share release];
    [_titleShare release];
    [_saveButton release];
    [_titleSave release];
    [_viewToolbar release];
}

- (void)initPreviewView
{
//    CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
    BOOL hideStatus = [UIApplication sharedApplication].isStatusBarHidden;
    CGFloat orginHeight = 0;
    if (!hideStatus && iOS7)
    {
        orginHeight += 20; // rectStatus.size.height;
    }

    _imageViewPreview = [[UIImageView alloc] initWithFrame:CGRectMake(0, orginHeight, self.view.frame.size.width, self.view.frame.size.height - orginHeight - toolbarHeight)];
    _imageViewPreview.image = [UIImage imageNamed:@"Background"];
    _imageViewPreview.clipsToBounds = TRUE;
    
    [self.view addSubview:_imageViewPreview];
    
    [_imageViewPreview release];
}

- (void) initThemeScrollView
{
    CGFloat height = 150;
    _frameScrollView = [[ThemeScrollView alloc] initWithFrame:CGRectMake(0, _viewToolbar.frame.origin.y - height, self.view.frame.size.width, height)];
    _frameScrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_frameScrollView];
    
    [self.frameScrollView setDelegate:self];
    [self.frameScrollView setCurrentSelectedItem:0];
    [self.frameScrollView scrollToItemAtIndex:0];
    self.frameScrollView.hidden = YES;
    
    [_frameScrollView release];
}

- (void) initVideoPlayView
{
    _videoPlayerController = [[PBJVideoPlayerController alloc] init];
    _videoPlayerController.delegate = self;
    _videoPlayerController.view.frame = _imageViewPreview.frame;
    
    [self addChildViewController:_videoPlayerController];
    [self.view addSubview:_videoPlayerController.view];
    
    _playButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button"]];
    _playButton.center = self.view.center;
    [_videoPlayerController.view addSubview:_playButton];
    
    [_playButton release];
}

- (void)initPopView
{
    NSArray *colorSchemes = [NSArray arrayWithObjects:
                             [NSArray arrayWithObjects:[NSNull null], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor colorWithRed:134.0/255.0 green:74.0/255.0 blue:110.0/255.0 alpha:1.0], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor darkGrayColor], [NSNull null], nil],
                             [NSArray arrayWithObjects:[UIColor lightGrayColor], [UIColor darkTextColor], nil],
                             [NSArray arrayWithObjects:[UIColor colorWithRed:220.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0], [NSNull null], nil],
                             nil];
    NSArray *colorScheme = [colorSchemes objectAtIndex:foo4random()*[colorSchemes count]];
    UIColor *backgroundColor = [colorScheme objectAtIndex:0];
    UIColor *textColor = [colorScheme objectAtIndex:1];
    
    NSString *hint = NSLocalizedString(@"UsageHint", nil);
    self.popTipView = [[CMPopTipView alloc] initWithMessage:hint];
    self.popTipView.delegate = self;
    if (backgroundColor && ![backgroundColor isEqual:[NSNull null]])
    {
        self.popTipView.backgroundColor = backgroundColor;
    }
    if (textColor && ![textColor isEqual:[NSNull null]])
    {
        self.popTipView.textColor = textColor;
    }
    
    if (iOS7)
    {
        self.popTipView.preferredPointDirection = PointDirectionDown;
    }
    self.popTipView.animation = arc4random() % 2;
//    self.popTipView.has3DStyle = (BOOL)(arc4random() % 2);
    self.popTipView.has3DStyle = FALSE;
    self.popTipView.dismissTapAnywhere = YES;
    [self.popTipView autoDismissAnimated:YES atTimeInterval:3.0];
    
    [self.popTipView presentPointingAtView:_takeVideo inView:self.view animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initPreviewView];
    [self initVideoPlayView];
    [self initToolbarView];
    [self initThemeScrollView];
    [self initPopView];
    
    self.toggleEffects.enabled = FALSE;
    [self showVideoPlayView:FALSE];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Hide Navbar
    [self.navigationController setNavigationBarHidden:YES];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidLayoutSubviews
{
//    CGRect rectStatus = [[UIApplication sharedApplication] statusBarFrame];
    BOOL hideStatus = [UIApplication sharedApplication].isStatusBarHidden;
    CGFloat orginHeight = self.view.frame.size.height - toolbarHeight;
    if (hideStatus)
    {
        orginHeight += 20; // rectStatus.size.height;
    }
    _viewToolbar.frame = CGRectMake(0, orginHeight, self.view.frame.size.width, toolbarHeight);
  
    CGFloat height = 150;
    _frameScrollView.frame = CGRectMake(0, _viewToolbar.frame.origin.y - height, self.view.frame.size.width, height);
    
//    _imageViewPreview.frame = CGRectMake(0, orginHeight, self.view.frame.size.width, self.view.frame.size.height - toolbarHeight - orginHeight);
    
//    NSLog(@"_viewToolbar = %@", NSStringFromCGRect(_viewToolbar.frame));
//    NSLog(@"_imageViewToolbarBG = %@", NSStringFromCGRect(_imageViewToolbarBG.frame));
//    NSLog(@"_toggleEffects = %@", NSStringFromCGRect(_toggleEffects.frame));
//    NSLog(@"_takeVideo = %@", NSStringFromCGRect(_takeVideo.frame));
//    NSLog(@"_openCameraRoll = %@", NSStringFromCGRect(_openCameraRoll.frame));
}

- (void)didReceiveMemoryWarning
{
//    [self dismissProgressBar:@"Failed for memory!"];
//    [self.videoEffects pause];
//    [self.videoEffects clearAll];
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self setImageViewPreview:nil];
    [self setFrameScrollView:nil];
    [self setPopTipView:nil];
    
    [self setViewToolbar:nil];
    [self setTakeVideo:nil];
    [self setToggleEffects:nil];
    [self setOpenCameraRoll:nil];
    [self setImageViewToolbarBG:nil];
    [self setTitleCameraRoll:nil];
    [self setTitleEffects:nil];
    
    [self setVideoPickURL:nil];
    [self setMp4OutputPath:nil];
    
    [self setHasMp4:NO];
    [self setHasVideo:NO];
    
    [self setFromSystemCamera:NO];
    [self setVideoEffects:nil];
    
    _share = nil;
    _saveButton = nil;
    _playButton = nil;
    _videoPlayerController = nil;
    
    [super viewDidUnload];
}

- (void) dealloc
{
    [_imageViewPreview release];
    [_frameScrollView release];
    [_popTipView release];
    
    [_viewToolbar release];
    [_takeVideo release];
    [_toggleEffects release];
    [_openCameraRoll release];
    [_imageViewToolbarBG release];
    [_titleEffects release];
    [_titleCameraRoll release];
    
    [_videoPickURL release];
    [_mp4OutputPath release];
    
    [_videoEffects release];
    
    [_share release];
    [_saveButton release];
    [_playButton release];
    [_videoPlayerController release];
    
    [super dealloc];
}

- (void) showVideoPlayView:(BOOL)show
{
    if (show)
    {
        _imageViewPreview.hidden = YES;
        
        _share.enabled = YES;
        _titleShare.enabled = YES;
        
        _saveButton.enabled = YES;
        _titleSave.enabled = YES;
        _playButton.hidden = NO;
        _videoPlayerController.view.hidden = NO;
    }
    else
    {
        _imageViewPreview.hidden = NO;
        
        _share.enabled = NO;
        _titleShare.enabled = NO;
        
        _saveButton.enabled = NO;
        _titleSave.enabled = NO;
        _playButton.hidden = YES;
        _videoPlayerController.view.hidden = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
