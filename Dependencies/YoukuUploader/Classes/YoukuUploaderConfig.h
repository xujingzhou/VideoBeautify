//
//  YoukuUploaderConfig.h
//  YoukuUploader
//
//  Created by silwings on 14-2-27.
//  Copyright (c) 2014年 wangcong. All rights reserved.
//

NSString* YOUKU_LOGIN_URL = @"https://openapi.youku.com/v2/oauth2/token";
NSString* YOUKU_CREATE_URL = @"https://openapi.youku.com/v2/uploads/create.json";
NSString* YOUKU_CREATE_FILE_URL = @"http://upload_server_uri/create_file";
NSString* YOUKU_NEW_SLICE_URL = @"http://upload_server_uri/gupload/new_slice";
NSString* YOUKU_UPLOAD_SLICE_URL = @"http://upload_server_uri/upload_slice";
NSString* YOUKU_CHECK_URL = @"http://upload_server_uri/check";
NSString* YOUKU_COMMIT_URL = @"https://openapi.youku.com/v2/uploads/commit.json";
NSString* YOUKU_CANCEL_URL = @"https://openapi.youku.com/v2/uploads/cancel.json";

// version update
NSString* YOUKU_VERSION_UPDATE_URL = @"http://open.youku.com/sdk/version_update";
NSString* YOUKU_VERSION = @"13112114";

bool YOUKU_DEBUG = true;

/**
 * 分片最大长度KB
 */
const int YOUKU_SLICE_LENGTH = 1024;

/**
 * 一般接口请求 timeout
 */
const int YOUKU_TIMEOUT = 10 * 1000;

/**
 * upload slice 接口 timeout
 */
const int YOUKU_TIMEOUT_UPLOAD_DATA = 2 * 60 * 1000;

/**
 * check 2、3时 sleep
 */
const int YOUKU_SLEEPTIME = 20000;

// const int YOUKU_UPLOAD_SLICE_MAX_THREAD = 2;

/**
 * upload response handler
 */
const int YOUKU_RES_START = 0;
const int YOUKU_RES_SUCCESS = 1;
const int YOUKU_RES_FAILURE = 2;
const int YOUKU_RES_PROGRESS_UPDATE = 3;
const int YOUKU_RES_FINISHED = 4;
const int YOUKU_RES_UPLOADING = 5;

/**
 * error code ( 仅以下特殊code 返回JSONObject，其他均通过接口返回，更多查看主站提供error code 文档 )
 */
NSString* YOUKU_ERROR_1002 = @"Service exception occured";
NSString* YOUKU_ERROR_1012 = @"Necessary parameter missing";
NSString* YOUKU_ERROR_1013 = @"Invalid parameter";
NSString* YOUKU_ERROR_120020001 = @"The video clip does not exist";

/**
 * 自定义 custom
 */
NSString* YOUKU_ERROR_50001 = @"upload task only one thread";
NSString* YOUKU_ERROR_50002 = @"connect exception";

NSString* YOUKU_ERROR_TYPE_FILE_NOT_FOUND = @"FileNotFoundException";
NSString* YOUKU_ERROR_TYPE_SYSTEM = @"SystemException";
NSString* YOUKU_ERROR_TYPE_UPLOAD_TASK = @"UploadTaskException";
NSString* YOUKU_ERROR_TYPE_CONNECT = @"ConnectException";