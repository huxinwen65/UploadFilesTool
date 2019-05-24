//
//  ViewController.m
//  HXWUploadMutableFilesTool
//
//  Created by BTI-HXW on 2019/5/23.
//  Copyright © 2019 BTI-HXW. All rights reserved.
//

#import "ViewController.h"
#import "UploadFileModel.h"

@interface ViewController ()
/**
 
 */
@property (nonatomic, strong) NSMutableArray *arr;
/**
 
 */
@property (nonatomic, strong) dispatch_queue_t queue;
/**
 
 */
@property (nonatomic, strong) dispatch_group_t group;
/**
 
 */
@property (nonatomic, strong) dispatch_semaphore_t semo;
/**
 
 */
@property (nonatomic, strong) NSMutableDictionary *dic;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.group = dispatch_group_create();
    self.queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    self.semo = dispatch_semaphore_create(3);
    [self task];
//    [self.arr removeObject:@"2"];
//    NSLog(@"arr.count:%ld",self.arr.count);
//    [self task];
//    UploadFileModel* mode = self.dic[@"key"];
//    NSLog(@"mode state:%ld",mode.state);
//    [self.dic.allValues enumerateObjectsUsingBlock:^(UploadFileModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        obj.state = 2;
//    }];
//    mode = self.dic[@"key"];
//    NSLog(@"mode state:%ld",mode.state);
    // Do any additional setup after loading the view.
}
- (void)task{
    __weak typeof(self) weakSelf = self;
    [self.arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        dispatch_group_async(weakSelf.group, weakSelf.queue, ^{
            dispatch_semaphore_wait(weakSelf.semo, DISPATCH_TIME_FOREVER);
            sleep(2);
            NSLog(@"group_里面_打印:%@ thread：%@",obj,[NSThread currentThread]);
            dispatch_semaphore_signal(weakSelf.semo);
        
        });
        NSLog(@"group_外面__打印:%@ thread：%@",obj,[NSThread currentThread]);
    }];
}
- (void)task1{
    __weak typeof(self) weakSelf = self;
    [self.arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_semaphore_wait(weakSelf.semo, DISPATCH_TIME_FOREVER);
        dispatch_group_async(weakSelf.group, weakSelf.queue, ^{
            sleep(2.0);
            NSLog(@"group_里面_打印:%@ thread：%@",obj,[NSThread currentThread]);
            dispatch_semaphore_signal(weakSelf.semo);
        });
        NSLog(@"group_外面__打印:%@ thread：%@",obj,[NSThread currentThread]);
    }];
}
- (void)task2{
    __weak typeof(self) weakSelf = self;
    [self.arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_group_enter(weakSelf.group);
        dispatch_group_async(weakSelf.group, weakSelf.queue, ^{
            sleep(2.0);
            NSLog(@"group_里面_打印:%@ thread：%@",obj,[NSThread currentThread]);
            dispatch_group_leave(weakSelf.group);
        });
        
        NSLog(@"group_外面__打印:%@ thread：%@",obj,[NSThread currentThread]);
    }];
    dispatch_group_notify(self.group, self.queue, ^{
        NSLog(@"group_里面__打印完成thread：%@",[NSThread currentThread]);
    });
    NSLog(@"task2结束：%@",[NSThread currentThread]);
}
-(NSMutableArray *)arr{
    if (!_arr) {
        _arr = [NSMutableArray arrayWithArray:@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8"]];
    }
    return _arr;
}
-(NSMutableDictionary *)dic{
    if (!_dic) {
        _dic = [NSMutableDictionary new];
        UploadFileModel* mode = [UploadFileModel new];
        mode.state = 1;
        mode.originFilePath = @"key";
        [_dic setObject:mode forKey:mode.originFilePath];
    }
    return _dic;
}

@end
