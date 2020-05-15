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
- (void) createConnect:(NSString *)addr;
- (void) joinRoom:(NSString *)room;
- (void) leaveRoom:(NSString *)room;
- (void) sendMessage:(NSString *)room withMsg:(NSDictionary *)msg;

@property (weak, nonatomic) id<SignalEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
