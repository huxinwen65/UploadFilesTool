//
//  UploadFilesTool.m
//  HXWUploadMutableFilesTool
//
//  Created by BTI-HXW on 2019/5/23.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import "UploadFilesTool.h"


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
 上传状态更新锁
 */
@property (nonatomic, strong) NSLock *lock;
/**
上传失败后，默认重新上传3次
 */
@property (nonatomic, assign) int reUploadCount ;
@end
@implementation UploadFilesTool
-(instancetype)init{
    if (self = [super init]) {
        self.semo = dispatch_semaphore_create(self.maxQueueCount);
        self.queue = dispatch_queue_create("HXWUPLOADQUEUE", DISPATCH_QUEUE_CONCURRENT);
        self.group = dispatch_group_create();
        self.needRestart = NO;
        self.lock = [NSLock new];
        self.reUploadCount = 3;
    }
    return self;
}
///第一次提交待上传的本地文件路径集合
- (void)startLocalFilePaths:(NSArray<NSString*>*)filePaths completion:(CompletionHandler)handler{
    if (handler) {
        self.handler = handler;
    }
    for (NSString* filePath in filePaths) {
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
        
    }
    [self startUpload];
}
///中途提交待上传的本地文件路径集合
- (void)addLocalFilePaths:(NSArray<NSString*>*)filePaths{
    [self startLocalFilePaths:filePaths completion:nil];
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
    [self.lock lock];
    if (self.needRestart) {
        self.needRestart = NO;
    }
    [self.lock unlock];
    __weak typeof(self) weakSelf = self;
    [self.uploadDic.allValues enumerateObjectsUsingBlock:^(UploadFileModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
                    obj.task = nil;///任务置空
                    ///信号量加1
                    dispatch_semaphore_signal(weakSelf.semo);
                    ///记得enter跟leave一一对应
                    dispatch_group_leave(weakSelf.group);
                } failed:^(NSString *des, NSInteger code) {
                    if (obj.state == UploadStateUploading) {
                        ///不是主动取消，设置为failed
                        [weakSelf updateMode:obj state:UploadStateFailed];
                    }
                    obj.task = nil;///任务置空
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
        if (weakSelf.needRestart && weakSelf.reUploadCount>0) {
            weakSelf.reUploadCount--;
            [weakSelf startUpload];
        }else{
            if (weakSelf.handler) {
                weakSelf.handler(weakSelf.uploadDic.allValues);
            }
            
        }
    });
}
- (void)updateMode:(UploadFileModel*)mode state:(UploadState)state{
    [self.lock lock];
    mode.state = state;
    if (state == UploadStateFailed) {
        self.needRestart = YES;
    }
    [self.lock unlock];
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
