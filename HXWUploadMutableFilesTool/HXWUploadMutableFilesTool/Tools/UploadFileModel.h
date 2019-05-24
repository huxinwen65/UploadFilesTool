//
//  UploadFileModel.h
//  HXWUploadMutableFilesTool
//
//  Created by BTI-HXW on 2019/5/23.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    UploadStateWaiting = 0,///等待上传
    UploadStateUploading,///正在上传
    UploadStateSucessed,///上传成功
    UploadStateFailed,///上传失败
    UploadStateCancel,///取消上传
} UploadState;
@interface UploadFileModel : NSObject
/**
 原始本地路径
 */
@property (nonatomic, copy) NSString *originFilePath;
/**
 远端url
 */
@property (nonatomic, copy) NSString *remoteUrl;
/**
 上传状态
 */
@property (nonatomic, assign) UploadState state;
/**
 对应的上传任务
 */
@property (nonatomic, strong) NSURLSessionUploadTask *task;
@end

NS_ASSUME_NONNULL_END
