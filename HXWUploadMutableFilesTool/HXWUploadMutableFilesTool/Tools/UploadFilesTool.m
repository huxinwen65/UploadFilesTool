//
//  UploadFilesTool.m
//  HXWUploadMutableFilesTool
//
//  Created by BTI-HXW on 2019/5/23.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import "UploadFilesTool.h"
#import <pthread.h>

@interface UploadFilesTool ()
/**
 上传
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, UploadFileModel*> *uploadDic;
/**
 最大并发数，默认为1
 */
@property (nonatomic, assign) NSUInteger maxQueueCount;
/**
 实际上传实现代理
 */
@property (nonatomic, weak) id<UploadFileProtocol> delegate;
/**
 上传完成回调
 */
@property (nonatomic, copy) CompletionHandler handler;
/**
 控制并发数信号量
 */
@property (nonatomic, strong) dispatch_semaphore_t semo;
/**
 上传队列
 */
@property (nonatomic, strong) dispatch_queue_t queue;
/**
 上传dispatch_group_t
 */
@property (nonatomic, strong) dispatch_group_t group;
/**
 标记是否需要上传
 */
@property (nonatomic, assign)  BOOL needRestart;
/**
上传失败后，默认重新上传3次
 */
@property (nonatomic, assign) int reUploadCount ;
@end
@implementation UploadFilesTool
{
    pthread_mutex_t _lock;
}
-(instancetype)init{
    if (self = [super init]) {
        self.semo = dispatch_semaphore_create(self.maxQueueCount);
        self.queue = dispatch_queue_create("HXWUPLOADQUEUE", DISPATCH_QUEUE_CONCURRENT);
        self.group = dispatch_group_create();
        self.needRestart = NO;
        pthread_mutex_init(&_lock, NULL);
        self.reUploadCount = 3;
    }
    return self;
}
- (void)setCompletionHandler:(CompletionHandler)handler{
    self.handler = handler;
}
///第一次提交待上传的本地文件路径集合
- (void)startLocalFilePaths:(NSArray<NSString*>*)filePaths{
  
    for (NSString* filePath in filePaths) {
        pthread_mutex_lock(&_lock);
        UploadFileModel* model = [self.uploadDic objectForKey:filePath];
        if (!model) {
            model = [UploadFileModel new];
            model.state = UploadStateWaiting;
            model.originFilePath = filePath;
            model.remoteUrl = @"";
            [self.uploadDic setObject:model forKey:filePath];
        }
        ///取消了，再次添加到上传队列，设置为待上传状态
        if ([model.remoteUrl isEqualToString:@""] && model.state == UploadStateCancel) {
            [self updateMode:model state:UploadStateWaiting];
        }
        pthread_mutex_unlock(&_lock);
    }
    [self startUpload];
}
///中途提交待上传的本地文件路径集合
- (void)addLocalFilePaths:(NSArray<NSString*>*)filePaths{
    [self startLocalFilePaths:filePaths];
}
///取消上传
- (void)cancelUploadLocalFilePaths:(NSArray<NSString*>*)filePaths{
    
        for (NSString* filePath in filePaths) {
            UploadFileModel* model = [self.uploadDic objectForKey:filePath];
            if (model) {///置为取消状态，并取消任务
                [self updateMode:model state:UploadStateCancel];
                if (model.task) {
                    [model.task cancel];
                }
            }
        }
    
}
///开始上传
- (void)startUpload{
    pthread_mutex_lock(&_lock);
    if (self.needRestart) {
        self.needRestart = NO;
    }
    NSArray* uploads = self.uploadDic.allValues;
    pthread_mutex_unlock(&_lock);
    __weak typeof(self) weakSelf = self;
    [uploads enumerateObjectsUsingBlock:^(UploadFileModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.state == UploadStateWaiting ||obj.state == UploadStateFailed) {
            obj.state = UploadStateUploading;
            ///记得enter跟leave一一对应
            dispatch_group_enter(weakSelf.group);
            dispatch_group_async(weakSelf.group, weakSelf.queue, ^{
                ///信号量减1，小于0等待
                dispatch_semaphore_wait(weakSelf.semo, DISPATCH_TIME_FOREVER);
                obj.task = [weakSelf.delegate uploadFile:obj.originFilePath suceed:^(NSString *remoteUrl) {
                    [weakSelf updateMode:obj state:UploadStateSucessed];
                    obj.remoteUrl = remoteUrl;
                    ///信号量加1
                    dispatch_semaphore_signal(weakSelf.semo);
                    ///记得enter跟leave一一对应
                    dispatch_group_leave(weakSelf.group);
                } failed:^(NSString *des, NSInteger code) {
                    if (obj.state == UploadStateUploading) {
                        ///不是主动取消，设置为failed
                        [weakSelf updateMode:obj state:UploadStateFailed];
                    }
                    ///信号量加1
                    dispatch_semaphore_signal(weakSelf.semo);
                    ///记得enter跟leave一一对应
                    dispatch_group_leave(weakSelf.group);
                } progress:^(double progress) {
                    ///备用
                }];
            });
        }
        
    }];
    ///全部上传完成通知结果
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        ///上传失败，需要重传，并且次数减1
        pthread_mutex_lock(&self->_lock);
        if (weakSelf.needRestart && weakSelf.reUploadCount>0) {
            weakSelf.reUploadCount--;
            pthread_mutex_unlock(&self->_lock);
            [weakSelf startUpload];
        }else{
            if (weakSelf.handler) {
                weakSelf.handler(weakSelf.uploadDic.allValues);
            }
            
        }
    });
}
- (void)updateMode:(UploadFileModel*)mode state:(UploadState)state{
    pthread_mutex_lock(&_lock);
    mode.state = state;
    if (state == UploadStateFailed) {
        self.needRestart = YES;
    }
    pthread_mutex_unlock(&_lock);
}

-(NSMutableDictionary *)uploadDic{
    if (!_uploadDic) {
        _uploadDic = [NSMutableDictionary new];
    }
    return _uploadDic;
}
-(NSUInteger)maxQueueCount{
    if (_maxQueueCount == 0) {
        _maxQueueCount = 1;
    }
    return _maxQueueCount;
}
@end
