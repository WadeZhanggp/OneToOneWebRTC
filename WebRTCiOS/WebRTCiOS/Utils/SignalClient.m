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
    
    [socket on:@"reconnectAttempt" callback:^(NSArray * data, SocketAckEmitter * ack) {
        NSLog(@"socket reconnectAttempt");
        [self.delegate reconectAttempt];
    }];
    
    [socket on:@"joined" callback:^(NSArray * data, SocketAckEmitter * ack) {
        
        NSString *room = [data objectAtIndex:0];
        NSLog(@"joined room(%@)",room);
        [self.delegate joined:room];
    }];
    
    [socket on:@"leaved" callback:^(NSArray * data, SocketAckEmitter * ack) {
        
        NSString *room = [data objectAtIndex:0];
        NSLog(@"leaved room(%@)",room);
        [self.delegate leaved:room];
    }];
    
    [socket on:@"full" callback:^(NSArray * data, SocketAckEmitter * ack) {
        
        NSString *room = [data objectAtIndex:0];
        NSLog(@"room(%@) is full",room);
        [self.delegate full:room];
    }];
    
    [socket on:@"otherjoin" callback:^(NSArray * data, SocketAckEmitter * ack) {
        
        NSString* room = [data objectAtIndex:0];
        if (data.count > 2) {
            return ;
        }
        NSString* uid = [data objectAtIndex:0];
        
        NSLog(@"other user(%@) has been joined into room(%@)", room, uid);
        [self.delegate otherjoin:room user:uid];
    }];
    
   
    [socket on:@"bye" callback:^(NSArray * data, SocketAckEmitter * ack) {
        
        NSString *room = [data objectAtIndex:0];
        NSString* uid = [data objectAtIndex:1];
        NSLog(@"user(%@) has leaved from room(%@)", room, uid);
        [self.delegate byeFrom:room user:uid];
    }];
    
    
    
    [socket on:@"message" callback:^(NSArray * data, SocketAckEmitter * ack) {
        
        NSString *room = [data objectAtIndex:0];
        NSDictionary* msg = [data objectAtIndex:1];
        NSLog(@"onMessage, room(%@), data(%@)", room, msg);
        NSString *type = msg[@"type"];
        if ([type isEqualToString:@"offer"]) {
            [self.delegate offer:room message:msg];
        }else if([type isEqualToString:@"answer"]) {
            [self.delegate answer:room message:msg];
        }else if([type isEqualToString:@"candidate"]) {
            [self.delegate candidate:room message:msg];
        }else {
            NSLog(@"the msg is invalid!");
        }
        
    }];
    
    //连接超时时间设置为3秒
    [socket connectWithTimeoutAfter:3.0 withHandler:^{
        NSLog(@"socket connect_timeout 3.0s");
        [self.delegate connectTimeout];
    }];
    
}

- (void)joinRoom:(NSString *)room {
    NSLog(@"join room(%@)", room);
    if (socket.status == SocketIOStatusConnected) {
        [socket emit:@"join" with:@[room]];
    }
}

- (void)leaveRoom:(NSString *)room {
    NSLog(@"leave room(%@)", room);
    if (socket.status == SocketIOStatusConnected) {
        [socket emit:@"leave" with:@[room]];
    }
    
}

- (void)sendMessage:(NSString *)room withMsg:(NSDictionary *)msg {
    if (socket.status == SocketIOStatusConnected) {
        if (msg) {
            NSLog(@"json:%@", msg);
            [socket emit:@"message" with:@[room, msg]];
        }else {
            NSLog(@"error: msg is nil!");
        }
    }else {
        NSLog(@"the socket has been disconnect!");
    }
}



@end
