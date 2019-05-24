//
//  UploadFilesTool.h
//  HXWUploadMutableFilesTool
//
//  Created by BTI-HXW on 2019/5/23.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UploadFileProtocol.h"
#import "UploadFileModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^CompletionHandler)(NSArray<UploadFileModel*>* modes);
@interface UploadFilesTool : NSObject
///设置实际上传网络接口代理
- (void)setDelegate:(id<UploadFileProtocol>)delegate;
///第一次提交待上传文件路径集合
- (void)startLocalFilePaths:(NSArray<NSString*>*)filePaths completion:(CompletionHandler)handler;
///中途提交待上传文件路径集合
- (void)addLocalFilePaths:(NSArray<NSString*>*)filePaths;
///取消上传文件路径集合
- (void)cancelUploadLocalFilePaths:(NSArray<NSString*>*)filePaths;
///设置最大并发数
- (void)setMaxQueueCount:(NSUInteger)maxQueueCount;

@end

NS_ASSUME_NONNULL_END
