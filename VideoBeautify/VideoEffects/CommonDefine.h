//
//  CommonDefine.h
//  VideoBeautify
//
//  Created by Johnny Xu(徐景周) on 8/14/14.
//  Copyright (c) 2014 Future Studio. All rights reserved.
//

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : 0)
#define IS_PHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPAD         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#define iOS7 ((([[UIDevice currentDevice].systemVersion intValue] >= 7) && ([[UIDevice currentDevice].systemVersion intValue] < 8)) ? YES : NO )
#define iOS6 ((([[UIDevice currentDevice].systemVersion intValue] >= 6) && ([[UIDevice currentDevice].systemVersion intValue] < 7)) ? YES : NO )
#define iOS5 ((([[UIDevice currentDevice].systemVersion intValue] >= 5) && ([[UIDevice currentDevice].systemVersion intValue] < 6)) ? YES : NO )

#define toolbarHeight 60
#define kMaxRecordDuration 15

#define foo4random() (1.0 * (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX)

#pragma mark - Common function
static inline void dispatch_async_main_after(NSTimeInterval after, dispatch_block_t block)
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

static inline void deleteFilesAt(NSString *directory, NSString *suffixName)
{
    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directory];
    NSString *toDelVideoFile;
    while (toDelVideoFile = [dirEnum nextObject])
    {
        if ([[toDelVideoFile pathExtension] isEqualToString:suffixName])
        {
            NSLog(@"removing file：%@",toDelVideoFile);
            if(![fileManager removeItemAtPath:[directory stringByAppendingPathComponent:toDelVideoFile] error:&err])
            {
                NSLog(@"Error: %@", [err localizedDescription]);
            }
        }
    }
}

static inline BOOL isStringEmpty(NSString *value)
{
    BOOL result = FALSE;
    if (!value || [value isKindOfClass:[NSNull class]])
    {
        // Null object
        result = TRUE;
    }
    else
    {
        NSString *trimedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([value isKindOfClass:[NSString class]] && [trimedString length] == 0)
        {
            // Empty string
            result = TRUE;
        }
    }
    
    return result;
}

static inline float systemVersion()
{
    static dispatch_once_t pred = 0;
    static NSUInteger version = -1;
    dispatch_once(&pred, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    
    return version;
}

static inline CGSize windowSize()
{
    static dispatch_once_t pred = 0;
    static CGSize size;
    dispatch_once(&pred, ^{
        size = [[UIScreen mainScreen] bounds].size;
    });
    
    return size;
}

static inline CGRect frameForStateBar()
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    return CGRectMake(0, systemVersion >= 7.0 ? 20.0f : 0.0f, windowSize().width, systemVersion >= 7.0 ? windowSize().height - 20: windowSize().height);
}
