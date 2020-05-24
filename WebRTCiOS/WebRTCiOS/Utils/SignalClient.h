//
//  SignalClient.h
//  WebRTCiOS
//
//  Created by zhangguangpeng on 2020/5/15.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SignalEventDelegate <NSObject>

@required
- (void) joined:(NSString *)room;
- (void) leaved:(NSString *)room;
- (void) otherjoin:(NSString *)room user:(NSString *)uid;
- (void) full:(NSString *)room;
- (void) byeFrom:(NSString *)room user:(NSString *)uid;
- (void) answer:(NSString *)room message:(NSDictionary *)dict;
- (void) offer:(NSString *)room message:(NSDictionary *)dict;
- (void) candidate: (NSString*) room message: (NSDictionary*) dict;
- (void) connected;
- (void) connectError;
- (void) connectTimeout;
- (void) reconectAttempt;

@end

@interface SignalClient : NSObject

+(SignalClient *) getInstance;
/// 创建连接
/// @param addr 地址
- (void) createConnect:(NSString *)addr;
/// 加入房间
/// @param room 房间号
- (void) joinRoom:(NSString *)room;
/// 离开房间
/// @param room 房间号
- (void) leaveRoom:(NSString *)room;
/// 发送消息
/// @param room 房间号
/// @param msg 信息
- (void) sendMessage:(NSString *)room withMsg:(NSDictionary *)msg;

@property (weak, nonatomic) id<SignalEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
