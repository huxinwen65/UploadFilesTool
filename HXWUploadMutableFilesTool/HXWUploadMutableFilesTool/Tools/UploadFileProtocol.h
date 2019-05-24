//
//  UploadFileProtocol.h
//  HXWUploadMutableFilesTool
//
//  Created by BTI-HXW on 2019/5/23.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^HXWUploadSuceedResult)(NSString* remoteUrl);
typedef void(^HXWUploadFailedResult)(NSString* des,NSInteger code);
typedef void(^HXWUploadProgress)(double progress);

@protocol UploadFileProtocol <NSObject>

@required

- (NSURLSessionUploadTask*)uploadFile:(NSString*)filePath suceed:(HXWUploadSuceedResult)suceed failed:(HXWUploadFailedResult)failed progress:(HXWUploadProgress)progress;

@end
