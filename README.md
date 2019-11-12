# UploadFilesTool
运用GCD实现多个本地文件的并发上传，并能够设置最大并发数。
导入工程后：

1、设置实现代理UploadFileProtocol的方法：

typedef void(^HXWUploadSuceedResult)(NSString* remoteUrl);

typedef void(^HXWUploadFailedResult)(NSString* des,NSInteger code);

typedef void(^HXWUploadProgress)(double progress);

@protocol UploadFileProtocol <NSObject>

@required

- (NSURLSessionUploadTask*)uploadFile:(NSString*)filePath suceed:(HXWUploadSuceedResult)suceed failed:(HXWUploadFailedResult)failed progress:(HXWUploadProgress)progress;

@end

2、UploadFilesTool.h：

///设置实际上传网络接口代理
- (void)setDelegate:(id<UploadFileProtocol>)delegate;
  
///上传任务完成后回调
- (void)setCompletionHandler:(CompletionHandler)handler;

///提交待上传文件路径集合
- (void)addLocalFilePaths:(NSArray<NSString*>*)filePaths;

///取消上传文件路径集合
- (void)cancelUploadLocalFilePaths:(NSArray<NSString*>*)filePaths;

///设置最大并发数
- (void)setMaxQueueCount:(NSUInteger)maxQueueCount;
  
3、上传完成后回调为UploadFileModel的数组，根据状态state和本地路径拿到相应的远端url：

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
