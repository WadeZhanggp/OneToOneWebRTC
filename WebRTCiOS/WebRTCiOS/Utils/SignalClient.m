//
//  SignalClient.m
//  WebRTCiOS
//
//  Created by zhangguangpeng on 2020/5/15.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import "SignalClient.h"
@import SocketIO;

@interface SignalClient()
{
    SocketManager *manager;
    SocketIOClient *socket;
    
    NSString *room;
}

@end


@implementation SignalClient

static SignalClient *mInstance = nil;

+ (SignalClient *)getInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken , ^{
        mInstance = [[self alloc] init];
    });
    
    return mInstance;
}

- (void)createConnect:(NSString *)addr {
    NSLog(@"the server addr is %@", addr);
    /*
    log 是否打印日志
    forcePolling  是否强制使用轮询
    reconnectAttempts 重连次数，-1表示一直重连
    reconnectWait 重连间隔时间
    forceWebsockets 是否强制使用websocket
    */
    NSURL *url = [[NSURL alloc] initWithString:addr];
    manager = [[SocketManager alloc] initWithSocketURL:url config:@{@"log": @YES,
        @"forcePolling":@YES,
        @"forceWebsockets":@YES,
        @"reconnectAttempts":@(5),
        @"reconnectWait":@(1)}];
    socket = [manager socketForNamespace:@"/"];
    [socket on:@"connect" callback:^(NSArray * data, SocketAckEmitter * ack) {
        NSLog(@"socket connect");
        [self.delegate connected];
    }];
    
    [socket on:@"error" callback:^(NSArray * data, SocketAckEmitter * ack) {
        NSLog(@"socket connect error");
        [self.delegate connectError];
    }];
    
    
    
    
}



@end
