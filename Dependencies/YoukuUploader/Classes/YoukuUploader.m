//
//  YoukuUploader.m
//  YoukuUploader
//
//  Created by silwings on 14-2-27.
//  Copyright (c) 2014年 wangcong. All rights reserved.
//

#import "YoukuUploader.h"
#import "YoukuUploaderConfig.h"
#import <CommonCrypto/CommonDigest.h>
#import <ASIHTTPRequest.h>
#import <ASIFormDataRequest.h>
#import <JSONKit.h>
#import <zlib.h>
#import <netdb.h>
#include <math.h>
#include <arpa/inet.h>

#define SAFE_RELEASE(obj) \
if(obj) {[obj release];obj = nil;}

@interface YoukuUploader ()
{
}

@property (nonatomic, retain) ASIFormDataRequest* http;
@property (nonatomic, retain) NSString* access_token;
@property (nonatomic, assign) int expires_in;
@property (nonatomic, retain) NSString* refresh_token;
@property (nonatomic, retain) NSString* token_type;
@property (nonatomic, retain) NSString* upload_token;
@property (nonatomic, retain) NSString* upload_uri;
@property (nonatomic, retain) NSString* upload_ip;
@property (nonatomic, assign) int slice_task_id;
@property (nonatomic, retain) NSString* upload_offset;
@property (nonatomic, retain) NSString* upload_length;
@property (nonatomic, assign) long uploaded_bytes;
@property (nonatomic, retain) NSString* client_id;
@property (nonatomic, retain) NSString* client_secret;
@property (nonatomic, retain) id<YoukuUploaderDelegate> delegate;
@property (nonatomic, retain) NSDictionary* upload_params;
@property (nonatomic, retain) NSMutableDictionary* upload_info;
@property (nonatomic, assign) long file_size;
@property (nonatomic, retain) NSString* file_ext;
@property (nonatomic, assign) dispatch_queue_t queue;
@property (nonatomic, retain) NSFileHandle* file_handle;

@end

@implementation YoukuUploader {
}

static YoukuUploader* g_sharedUploader = NULL;

+ (YoukuUploader*) sharedInstance
{
    if (g_sharedUploader == NULL) {
        g_sharedUploader = [[YoukuUploader alloc] init];
    }
    return g_sharedUploader;
}

- (YoukuUploader*) init
{
    [super init];
    return self;
}

- (void) setClientID:(NSString *)cid andClientSecret:(NSString *)secret
{
    self.client_id = cid;
    self.client_secret = secret;
}

- (void) upload:(NSDictionary *)params uploadInfo:(NSDictionary *)uploadInfo uploadDelegate:(id<YoukuUploaderDelegate>)uploadDelegate dispatchQueue:(dispatch_queue_t)dispatchQueue
{
    self.delegate = uploadDelegate;
    self.upload_params = params;
    self.upload_info = [NSMutableDictionary dictionaryWithDictionary:uploadInfo];
    self.queue = dispatchQueue;
    self.uploaded_bytes = 0;
    
    if (self.upload_params.count == 0 || self.upload_info.count == 0) {
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM type:YOUKU_ERROR_1012 code:1012]];
        return;
    }
    
    NSString *access_token = [self.upload_params objectForKey:@"access_token"];
    if ((access_token == nil || [access_token isEqualToString:@""])&& ([self.upload_params objectForKey:@"username"] == nil || [self.upload_params objectForKey:@"password"] == nil))
    {
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM type:YOUKU_ERROR_1012 code:1012]];
        return;
    }
    
    if ([self.upload_info objectForKey:@"title"] == nil || [self.upload_info objectForKey:@"tags"] == nil || [self.upload_info objectForKey:@"file_name"] == nil) {
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM type:YOUKU_ERROR_1012 code:1012]];
        return;
    }
    if(![self checkUploadInfo]) {
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_FILE_NOT_FOUND type:YOUKU_ERROR_120020001 code:12002001]];
        return;
    }
    
    if ([self.upload_info objectForKey:@"debug"] != nil) {
        YOUKU_DEBUG = true;
    }
    
    [self updateVersion];
    
    if (access_token != nil)
    {
        // create
        YOUKU_LOG(@"upload:%s", "access_token exist ==> step create");
        self.access_token = [self.upload_params objectForKey:@"access_token"];
        [self createVideo];
    }
    else
    {
        // login
        YOUKU_LOG(@"upload:%s", "step Login");
        [self login:[self.upload_params objectForKey:@"username"] password:[self.upload_params objectForKey:@"password"]];
    }
    
}

- (void) cancel
{
    [self.http cancel];
}

- (void) updateVersion
{
    ASIFormDataRequest* req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:YOUKU_VERSION_UPDATE_URL]];
    [req addPostValue:self.client_id forKey:@"client_id"];
    [req addPostValue:YOUKU_VERSION forKey:@"version"];
    [req addPostValue:@"ios" forKey:@"type"];
    [req setRequestMethod:@"GET"];
    [req setCompletionBlock:^{
        YOUKU_LOG(@"update version finished");
    }];
}


- (void) login:(NSString*)username password:(NSString*)password
{
    NSLog(@"usn:%@, pw:%@", username, password);
    
    self.http = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:YOUKU_LOGIN_URL]];
    [self.http addPostValue:self.client_id forKey:@"client_id"];
    [self.http addPostValue:self.client_secret forKey:@"client_secret"];
    [self.http addPostValue:username forKey:@"username"];
    [self.http addPostValue:password forKey:@"password"];
    [self.http addPostValue:@"authorization_code" forKey:@"grant_type"];
    [self.http setRequestMethod:@"POST"];
    [self.http setCompletionBlock:^{
        NSString* res = self.http.responseString;
        YOUKU_LOG(@"login resp:%@", res);
        NSDictionary* obj = [res objectFromJSONString];
        if (![self checkResponse:obj]) {
            return;
        }
        self.access_token = [obj objectForKey:@"access_token"];
        self.expires_in = [[obj objectForKey:@"expires_in"] integerValue];
        self.refresh_token = [obj objectForKey:@"refresh_token"];
        self.token_type = [obj objectForKey:@"token_type"];
        [self createVideo];
        
    }];
    [self.http setFailedBlock:^{
        YOUKU_LOG(@"http status code:%d", self.http.responseStatusCode);
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http startAsynchronous];
    [self.http retain];
}

- (void) createVideo
{
    self.http = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:YOUKU_CREATE_URL]];
    [self.http setRequestMethod:@"GET"];
    [self.http addPostValue:self.client_id forKey:@"client_id"];
    [self.http addPostValue:self.access_token forKey:@"access_token"];
    [self.http addPostValue:[self.upload_info objectForKey:@"title"] forKey:@"title"];
    [self.http addPostValue:[self.upload_info objectForKey:@"tags"] forKey:@"tags"];
    [self.http addPostValue:[self.upload_info objectForKey:@"file_name"] forKey:@"file_name"];
    [self.http addPostValue:[self.upload_info objectForKey:@"file_md5"] forKey:@"file_md5"];
    [self.http addPostValue:[self.upload_info objectForKey:@"file_size"] forKey:@"file_size"];
    [self.http setCompletionBlock:^{
        YOUKU_LOG(@"create resp:%@", self.http.responseString);
        NSDictionary* obj = [self.http.responseString objectFromJSONString];
        if (![self checkResponse:obj]) {
            return;
        }
        self.upload_token = [obj objectForKey:@"upload_token"];
        self.upload_uri = [obj objectForKey:@"upload_server_uri"];
        self.upload_ip = ipFromHost(self.upload_uri);
        YOUKU_LOG(@"upload ip:%@", self.upload_ip);
        NSString* instant_upload_ok = [obj objectForKey:@"instant_upload_ok"];
        if ([instant_upload_ok isEqualToString:@"yes"]) {
            YOUKU_LOG(@"instant upload ok");
            [self checkVideo];
        }
        else {
            [self uploadVideo];
        }
        
    }];
    [self.http setFailedBlock:^{
        YOUKU_LOG(@"create fail:%d, resp:%@", self.http.responseStatusCode, self.http.responseString);
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http startAsynchronous];
    [self.http retain];
}

- (void) uploadVideo
{
    self.http = [ASIFormDataRequest requestWithURL:[self realUrl:YOUKU_CREATE_FILE_URL]];
    [self.http setRequestMethod:@"POST"];
    [self.http addPostValue:self.upload_token forKey:@"upload_token"];
    [self.http addPostValue:[NSNumber numberWithInteger:self.file_size] forKey:@"file_size"];
    [self.http addPostValue:[self.upload_info objectForKey:@"ext"] forKey:@"ext"];
    [self.http addPostValue:[NSString stringWithFormat:@"%d", YOUKU_SLICE_LENGTH] forKey:@"slice_length"];
    [self.http setCompletionBlock:^{
        if (self.http.responseStatusCode == 201) {
            YOUKU_LOG(@"start upload");
            [self newSliceVideo];
        }
        else {
            [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM type:YOUKU_ERROR_1002 code:1002]];
        }
    }];
    [self.http setFailedBlock:^{
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http startAsynchronous];
    [self.http retain];
}

- (void) newSliceVideo
{
    NSString* url = [NSString stringWithFormat:@"%@?upload_token=%@", [[self realUrl:YOUKU_NEW_SLICE_URL] absoluteString], self.upload_token, nil];
    self.http = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
    [self.http setRequestMethod:@"GET"];
    [self.http setCompletionBlock:^{
        YOUKU_LOG(@"upload slice, resp:%@", self.http.responseString);
        NSDictionary* obj = [self.http.responseString objectFromJSONString];
        if (![self checkResponse:obj]) {
            return;
        }
        self.slice_task_id = [[obj objectForKey:@"slice_task_id"] integerValue];
        bool finished = [[obj objectForKey:@"finished"] boolValue];
//        long transferred = [[obj objectForKey:@"transferred"] longValue];
        self.upload_offset = [obj objectForKey:@"offset"];
        self.upload_length = [obj objectForKey:@"length"];
//        [self.delegate onProgressUpdate:transferred * 100 / self.file_size];
        if (finished || self.slice_task_id == 0) {
            YOUKU_LOG(@"upload finish");
            [self checkVideo];
        }
        else {
            YOUKU_LOG(@"continue upload");
            [self uploadSliceVideo];
        }
    }];
    [self.http setFailedBlock:^{
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http startAsynchronous];
    [self.http retain];
}

- (void) uploadSliceVideo
{
    NSData* sliceData = [self sliceData];
    NSString* crc = crcFromData(sliceData);
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?upload_token=%@&slice_task_id=%d&offset=%@&length=%@&crc=%@", [[self realUrl:YOUKU_UPLOAD_SLICE_URL] absoluteString], self.upload_token, self.slice_task_id, self.upload_offset, self.upload_length, crc, nil]];
    self.http = [ASIHTTPRequest requestWithURL:url];
    [self.http setRequestMethod:@"POST"];
    [self.http setPostBody:[NSMutableData dataWithData:sliceData]];
    [self.http addRequestHeader:@"Content-Type" value:@"multipart/form-data; boundary=***** "];
    [self.http setCompletionBlock:^{
        YOUKU_LOG(@"upload slice resp:%@", self.http.responseString);
        NSDictionary* obj = [self.http.responseString objectFromJSONString];
        if (![self checkResponse:obj]) {
            return;
        }
        self.slice_task_id = [[obj objectForKey:@"slice_task_id"] integerValue];
        bool finished = [[obj objectForKey:@"finished"] boolValue];
        long transferred = [[obj objectForKey:@"transferred"] longValue];
        self.upload_offset = [obj objectForKey:@"offset"];
        self.upload_length = [obj objectForKey:@"length"];
        [self.delegate onProgressUpdate:transferred * 100 / self.file_size];
        if (finished || self.slice_task_id == 0) {
            YOUKU_LOG(@"upload finish");
            [self checkVideo];
        }
        else {
            [self uploadSliceVideo];
        }
    }];
    [self.http setFailedBlock:^{
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http setShowAccurateProgress:YES];
    [self.http setUploadProgressDelegate:self];
    [self.http startAsynchronous];
    [self.http retain];
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes;
{
    YOUKU_LOG(@"upload size:%d,", bytes);
    self.uploaded_bytes += bytes;
	int progress = MIN(100, (int)(self.uploaded_bytes * 100 / self.file_size));
    [self.delegate onProgressUpdate:progress];
}


- (void) checkVideo
{
    NSString* url = [NSString stringWithFormat:@"%@?upload_token=%@", [[self realUrl:YOUKU_CHECK_URL] absoluteString], self.upload_token, nil];
    self.http = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [self.http setRequestMethod:@"GET"];
    [self.http setCompletionBlock:^{
        YOUKU_LOG(@"check resp:%@", self.http.responseString);
        NSDictionary* obj = [self.http.responseString objectFromJSONString];
        if (![self checkResponse:obj]) {
            return;
        }
        int status = [[obj objectForKey:@"status"] integerValue];
        self.upload_ip = [obj objectForKey:@"upload_server_ip"];
        YOUKU_LOG(@"check status:%d", status);
        switch (status) {
            case 1:
                [self commit];
                break;
            case 2:
            case 3:
                [NSThread sleepForTimeInterval:YOUKU_SLEEPTIME];
                [self checkVideo];
                break;
            case 4:
                //TODO 暂时不处理
                [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM type:YOUKU_ERROR_1002 code:1002]];
                break;
            default:
                break;
        }
    }];
    [self.http setFailedBlock:^{
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http startAsynchronous];
    [self.http retain];
}

- (void) commit
{
    self.http = [ASIFormDataRequest requestWithURL:[self realUrl:YOUKU_COMMIT_URL]];
    [self.http addPostValue:self.client_id forKey:@"client_id"];
    [self.http addPostValue:self.access_token forKey:@"access_token"];
    [self.http addPostValue:self.upload_token forKey:@"upload_token"];
    [self.http addPostValue:self.upload_ip forKey:@"upload_server_ip"];
    [self.http setCompletionBlock:^{
        YOUKU_LOG(@"check resp:%@", self.http.responseString);
        NSDictionary* obj = [self.http.responseString objectFromJSONString];
        if (![self checkResponse:obj]) {
            return;
        }
        NSString* vid = [obj objectForKey:@"video_id"];
        [self.delegate onProgressUpdate:100];
        [self.delegate onSuccess:vid];
    }];
    [self.http setFailedBlock:^{
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_CONNECT type:YOUKU_ERROR_50002 code:50002]];
    }];
    [self.http startAsynchronous];
    [self.http retain];
}

- (NSURL*) realUrl:(NSString*)baseUrl
{
    NSString* realUrl = [baseUrl stringByReplacingOccurrencesOfString:@"upload_server_uri" withString:self.upload_ip];
    return [NSURL URLWithString:realUrl];
}

- (NSData*) sliceData
{
    [self.file_handle seekToFileOffset:[self.upload_offset longLongValue]];
    return [self.file_handle readDataOfLength:[self.upload_length integerValue]];
}

- (NSDictionary*) failureResponseWithType:(const NSString*)type type:(const NSString*)desc code:(int)code
{
    NSDictionary* resp = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", desc, @"desc", [NSNumber numberWithInt:code], @"code", nil];
    return resp;
}

- (BOOL) checkUploadInfo
{
    NSString* filename = [self.upload_info objectForKey:@"file_name"];
    if (filename != nil) {
        YOUKU_LOG(@"upload file_name:%@", filename);
        self.file_handle = [NSFileHandle fileHandleForReadingAtPath:filename];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
        if (!fileExists) {
            return NO;
        } else {
            NSError *attributesError = nil;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filename error:&attributesError];
            NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
            self.file_size = [fileSizeNumber longValue];
            self.file_ext = [filename pathExtension];
            
            [self.upload_info setValue:md5FromFile(filename) forKey:@"file_md5"];
            [self.upload_info setValue:[NSString stringWithFormat:@"%ld",self.file_size] forKey:@"file_size"];
            [self.upload_info setValue:self.file_ext forKey:@"ext"];
            return YES;
        }
    } else {
        return NO;
    }
}

- (BOOL) checkResponse:(NSDictionary*)obj
{
    if (obj == nil) {
        [self.delegate onFailure:[self failureResponseWithType:YOUKU_ERROR_TYPE_SYSTEM type:YOUKU_ERROR_1002 code:1002]];
        return NO;
    }
    if ([obj objectForKey:@"error"] != nil) {
        return NO;
    }
    else {
        return YES;
    }
}

NSString* crcFromData(NSData* data) {
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, [data bytes], [data length]);
    return [NSString stringWithFormat:@"%lx", crc];
}

NSString* md5FromFile(NSString* filename){
    
    NSData* data = [NSData dataWithContentsOfFile:filename];
    
    const void* src = [data bytes];
    NSUInteger len = [data length];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(src, len, result);
    return [[NSString
             stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1],
             result[2], result[3],
             result[4], result[5],
             result[6], result[7],
             result[8], result[9],
             result[10], result[11],
             result[12], result[13],
             result[14], result[15]
             ]lowercaseString];
}

NSString* ipFromHost(NSString* host) {
    struct hostent *hostentry;
    hostentry = gethostbyname([host UTF8String]);
    char * ipbuf;
    ipbuf = inet_ntoa(*((struct in_addr *)hostentry->h_addr_list[0]));
    return [NSString stringWithUTF8String:ipbuf];
}

void YOUKU_LOG(NSString* format, ...)
{
    if (YOUKU_DEBUG) {
        va_list argList;
        va_start(argList, format);
        NSString* formattedMessage = [[NSString alloc] initWithFormat: format arguments: argList];
        va_end(argList);
        NSLog(@"[YoukuUploader] %@", formattedMessage);
        [formattedMessage release]; // if not on ARC
    }
}

@end
