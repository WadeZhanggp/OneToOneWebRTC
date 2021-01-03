//
//  CallViewController.m
//  WebRTCiOS
//
//  Created by zhangguangpeng on 2020/5/15.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import "CallViewController.h"

#import "SignalClient.h"
#import <WebRTC/WebRTC.h>
#import <MBProgressHUD.h>
#import <Masonry/Masonry.h>
#import "ReactiveObjC/ReactiveObjC.h"

//static NSString *const RTCSTUNServerURL = @"stun:stun.l.google.com:19302";
static NSString *const RTCSTUNServerURL = @"stun:stun.wadezhanggp.xyz:3478";
static int logY = 0;

@interface CallViewController ()<SignalEventDelegate, RTCPeerConnectionDelegate, RTCVideoViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (copy, nonatomic) NSString *myAddr;
@property (copy, nonatomic) NSString *myRoom;
@property (copy, nonatomic) NSString *myState;
@property (strong, nonatomic) SignalClient *sigclient;
@property (strong, nonatomic) RTCPeerConnectionFactory *factory;
@property (strong, nonatomic) RTCCameraVideoCapturer *capture;
@property (strong, nonatomic) RTCPeerConnection *peerConnection;
@property (strong, nonatomic) RTCVideoTrack *videoTrack;
@property (strong, nonatomic) RTCAudioTrack *audioTrack;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (strong, nonatomic) NSMutableArray *ICEServers;

@property (strong, nonatomic) RTCEAGLVideoView *remoteVideoView;
@property (strong, nonatomic) RTCCameraPreviewView *localVideoView;
@property (strong, nonatomic) UIButton* leaveButton;
@property (strong, nonatomic) dispatch_source_t timer;



@end

@implementation CallViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.localVideoView];
    [self.view addSubview:self.remoteVideoView];
    [self.view addSubview:self.leaveButton];
    [self initLayout];
    
    [self createPeerConnectionFactory];
    [self captureLocalMedia];
    self.sigclient = [SignalClient getInstance];
    self.sigclient.delegate = self;
    self.myState = @"init";
    [self.sigclient createConnect:self.myAddr];
    [self initFunction];
    
    
    
}

- (instancetype)initAddr:(NSString *)addr withRoom:(NSString *)room {
    self.myAddr = addr;
    self.myRoom = room;
    return self;
}

#pragma mark initfunction
- (void)initFunction {
    
    @weakify(self)
    [[self.leaveButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self)
        [self.navigationController popViewControllerAnimated:YES];
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        if (!self.sigclient) {
            self.sigclient = [SignalClient getInstance];
        }
        
        if(![self.myState isEqualToString:@"leaved"]){
            [self.sigclient leaveRoom: self.myRoom];
        }
        
        if(self.peerConnection){
            [self.peerConnection close];
            self.peerConnection = nil;
        }
        
        NSLog(@"leave room(%@)", self.myRoom);
        [self addLogToScreen: @"leave room(%@)", self.myRoom];
        
        
    }];
    
}

#pragma mark 获取回复
- (void) getAnswer:(RTCPeerConnection*) pc {
    
    NSLog(@"Success to set remote offer SDP");
    
    [pc answerForConstraints:[self defaultPeerConnContraints]
           completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if(!error){
            NSLog(@"Success to create local answer sdp!");
            __weak RTCPeerConnection* weakPeerConn = pc;
            [self setLocalAnswer:weakPeerConn withSdp:sdp];
            
        }else{
            NSLog(@"Failure to create local answer sdp!");
        }
    }];
}

#pragma mark 发起语言通话
- (void) doStartCall {
    NSLog(@"Start Call, Wait ...");
    [self addLogToScreen: @"Start Call, Wait ..."];
    if (!self.peerConnection) {
        self.peerConnection = [self createPeerConnection];
    }
    [self.peerConnection offerForConstraints:[self defaultPeerConnContraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to create offer SDP, err=%@", error);
        }else {
            __weak RTCPeerConnection* weakPeerConnction = self.peerConnection;
            [self setLocalOffer: weakPeerConnction withSdp: sdp];
        }
    }];
    
}

#pragma mark 设置本地答复
- (void) setLocalAnswer: (RTCPeerConnection*)pc withSdp: (RTCSessionDescription*)sdp {
    [pc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        if(!error){
            NSLog(@"Successed to set local answer!");
        }else {
            NSLog(@"Failed to set local answer, err=%@", error);
        }
    }];
    __weak NSString* weakMyRoom = self.myRoom;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //send answer sdp
        NSDictionary* dict = [[NSDictionary alloc] initWithObjects:@[@"answer", sdp.sdp]
                                                           forKeys: @[@"type", @"sdp"]];
        
        [[SignalClient getInstance] sendMessage: weakMyRoom withMsg:dict];
    });
    
}

#pragma mark 发起本地请求
- (void)setLocalOffer:(RTCPeerConnection*)pc withSdp:(RTCSessionDescription*) sdp{
    
    [pc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Successed to set local offer sdp!");
        }else{
            NSLog(@"Failed to set local offer sdp, err=%@", error);
        }
    }];
    
    __weak NSString* weakMyRoom = self.myRoom;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary* dict = [[NSDictionary alloc] initWithObjects:@[@"offer", sdp.sdp]
                                                           forKeys: @[@"type", @"sdp"]];
        
        [[SignalClient getInstance] sendMessage: weakMyRoom
                                        withMsg: dict];
    });
}



#pragma mark
- (RTCMediaConstraints*) defaultPeerConnContraints {
    RTCMediaConstraints* mediaConstraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{
        kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue
    }
                                          optionalConstraints:@{ @"DtlsSrtpKeyAgreement" : @"true" }];
    return mediaConstraints;
}

#pragma mark 初始化STUN Server （ICE Server）
- (RTCIceServer *)defaultSTUNServer {
    return [[RTCIceServer alloc] initWithURLStrings:@[RTCSTUNServerURL]
                                           username:@"WadeZhang"
                                         credential:@"zhang503"];
}


#pragma mark 创建peerconnect
- (RTCPeerConnection *)createPeerConnection {
    
    //得到ICEServer
    if (!self.ICEServers) {
        self.ICEServers = [NSMutableArray array];
        [self.ICEServers addObject:[self defaultSTUNServer]];
    }
    
    //用工厂来创建连接
    RTCConfiguration* configuration = [[RTCConfiguration alloc] init];
    [configuration setIceServers:self.ICEServers];
    RTCPeerConnection* conn = [self.factory
                               peerConnectionWithConfiguration:configuration
                               constraints:[self defaultPeerConnContraints]
                               delegate:self];
    
    
    NSArray<NSString*>* mediaStreamLabels = @[@"ARDAMS"];
    [conn addTrack:self.videoTrack streamIds:mediaStreamLabels];
    [conn addTrack:self.audioTrack streamIds:mediaStreamLabels];
    
    return conn;
}

#pragma mark 添加日志到屏幕
-(void)addLogToScreen:(NSString *)format, ...{
    
    va_list paramList;
    va_start(paramList,format);
    NSString* log = [[NSString alloc]initWithFormat:format arguments:paramList];
    va_end(paramList);
    
    CGRect labelRect = CGRectMake(0, logY++ * 20, 500, 200);
    UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
    label.text = log;
    label.textColor = [UIColor redColor];
    [self.view addSubview:label];
}

#pragma mark 创建本地流
- (void) captureLocalMedia {
    NSDictionary *mandatoryConstraints = @{};
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    RTCAudioSource *audioSource = [self.factory audioSourceWithConstraints:constraints];
    self.audioTrack = [self.factory audioTrackWithSource:audioSource trackId:@"ADRAMSa0"];
    
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    AVCaptureDevice *device = captureDevices[0];
    for (AVCaptureDevice *obj in captureDevices) {
        if (obj.position == position) {
            device = obj;
            break;
        }
    }
    
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        NSLog(@"相机访问受限");
        //弹出提醒添加成功
        MBProgressHUD *hud= [[MBProgressHUD alloc] initWithView:self.view];
        [hud setRemoveFromSuperViewOnHide:YES];
        hud.label.text = @"没有权限访问相机";
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, 50, 50)];
        [hud setCustomView:view];
        [hud setMode:MBProgressHUDModeCustomView];
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1.0]; //设置1秒钟后自动消失
        return;
    }
    
    if (device) {
        RTCVideoSource *videoSource = [self.factory videoSource];
        self.capture = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
        AVCaptureDeviceFormat *format = [[RTCCameraVideoCapturer supportedFormatsForDevice:device] lastObject];
        CGFloat fps = [[format videoSupportedFrameRateRanges] firstObject].maxFrameRate;
        self.videoTrack = [self.factory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];
        //self.localVideoView.sampleBufferDelegate.
        self.localVideoView.captureSession = self.capture.captureSession;
        [self.capture startCaptureWithDevice:device format:format fps:fps];
        
    }
    
}

#pragma mark 创建点对点工厂
- (void)createPeerConnectionFactory {
    //设置ssl传输
    [RTCPeerConnectionFactory initialize];
    //点对点工厂设置
    if (!self.factory) {
        RTCDefaultVideoDecoderFactory *decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
        RTCDefaultVideoEncoderFactory *encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
        NSArray *codes = [encoderFactory supportedCodecs];
        [encoderFactory setPreferredCodec:codes[2]];
        self.factory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory decoderFactory:decoderFactory];
    }
}


#pragma mark SignalEventDelegate
- (void)leaved:(nonnull NSString *)room {
    NSLog(@"leaved room(%@) notify!", room);
    [self addLogToScreen: @"leaved room(%@) notify!", room];
}

- (void)joined:(nonnull NSString *)room {
    NSLog(@"joined room(%@) notify!", room);
    [self addLogToScreen: @"joined room(%@) notify!", room];
    
    self.myState = @"joined";
    
    //这里应该创建PeerConnection
    if (!self.peerConnection) {
        self.peerConnection = [self createPeerConnection];
    }
}

- (void)otherjoin:(nonnull NSString *)room user:(nonnull NSString *)uid {
    NSLog(@"other user(%@) has been joined into room(%@) notify!", uid, room);
    [self addLogToScreen: @"other user(%@) has been joined into room(%@) notify!", uid, room];
    if([self.myState isEqualToString:@"joined_unbind"]){
        if (!self.peerConnection) {
            self.peerConnection = [self createPeerConnection];
        }
    }
    
    self.myState =@"joined_conn";
    //调用call， 进行媒体协商
    [self doStartCall];
}

- (void)full:(nonnull NSString *)room {
    NSLog(@"the room(%@) is full notify!", room);
    [self addLogToScreen: @"the room(%@) is full notify!", room];
    self.myState = @"leaved";
    if (self.peerConnection) {
        [self.peerConnection close];
        self.peerConnection = nil;
    }
    //弹出提醒添加成功
    MBProgressHUD *hud= [[MBProgressHUD alloc] initWithView:self.view];
    [hud setRemoveFromSuperViewOnHide:YES];
    hud.label.text = @"Room is full";
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, 50, 50)];
    [hud setCustomView:view];
    [hud setMode:MBProgressHUDModeCustomView];
    [self.view addSubview:hud];
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1.0]; //设置1秒钟后自动消失
    if(self.localVideoView) {
        //[self.localVideoView removeFromSuperview];
        //self.localVideoView = nil;
    }
    
    if(self.remoteVideoView) {
        //[self.localVideoView removeFromSuperview];
        //self.remoteVideoView = nil;
    }
    
    if(self.capture) {
        [self.capture stopCapture];
        self.capture = nil;
    }
    
    if(self.factory) {
        self.factory = nil;
    }
}

- (void)answer:(nonnull NSString *)room message:(nonnull NSDictionary *)dict {
    NSLog(@"have received a answer message %@", dict);
    NSString *remoteAnswerSdp = dict[@"sdp"];
    RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc]
                                        initWithType:RTCSdpTypeAnswer
                                        sdp: remoteAnswerSdp];
    [self.peerConnection setRemoteDescription:remoteSdp
                            completionHandler:^(NSError * _Nullable error) {
        if(!error){
            NSLog(@"Success to set remote Answer SDP");
        }else{
            NSLog(@"Failure to set remote Answer SDP, err=%@", error);
        }
    }];
}

- (void)offer:(nonnull NSString *)room message:(nonnull NSDictionary *)dict {
    NSLog(@"have received a offer message %@", dict);
    NSString* remoteOfferSdp = dict[@"sdp"];
    
    RTCSessionDescription* remoteSdp = [[RTCSessionDescription alloc]
                                        initWithType:RTCSdpTypeOffer
                                        sdp: remoteOfferSdp];
    if(!self.peerConnection){
        self.peerConnection = [self createPeerConnection];
    }
    
    __weak RTCPeerConnection* weakPeerConnection = self.peerConnection;
    [weakPeerConnection setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
        if(!error){
            [self getAnswer: weakPeerConnection];
        }else{
            NSLog(@"Failure to set remote offer SDP, err=%@", error);
        }
    }];
}

- (void)candidate:(nonnull NSString *)room message:(nonnull NSDictionary *)dict {
    NSLog(@"have received a message %@", dict);
    NSString* desc = dict[@"sdp"];
    NSString* sdpMLineIndex = dict[@"label"];
    int index = [sdpMLineIndex intValue];
    NSString* sdpMid = dict[@"id"];
    
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:desc
                                                        sdpMLineIndex:index
                                                               sdpMid:sdpMid];;
    [self.peerConnection addIceCandidate:candidate];
}

- (void)connected {
    [[SignalClient getInstance] joinRoom:self.myRoom];
    [self addLogToScreen: @"socket connect success!"];
    [self addLogToScreen: @"joinRoom: %@", self.myRoom];
}

- (void)byeFrom:(nonnull NSString *)room user:(nonnull NSString *)uid {
    NSLog(@"the user(%@) has leaved from room(%@) notify!", uid, room);
    [self addLogToScreen: @"the user(%@) has leaved from room(%@) notify!", uid, room];
    self.myState = @"joined_unbind";
    
    [self.peerConnection close];
    self.peerConnection = nil;
}

- (void)connectError {
    //todo: notfiy UI
    [self addLogToScreen: @"socket connect_error!"];
}

- (void)connectTimeout {
    //todo: notfiy UI
    [self addLogToScreen: @"socket connect_timeout!"];
}


- (void)reconectAttempt {
    [self addLogToScreen: @"socket reconnectAttempt!"];
}

#pragma mark RTCPeerConnectionDelegate
/** Called when the SignalingState changed. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSLog(@"%s",__func__);
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"%s",__func__);
}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"%s",__func__);
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    NSLog(@"%s",__func__);
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"%s",__func__);
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    NSLog(@"%s",__func__);
}

/** New ice candidate has been found. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didGenerateIceCandidate:(nonnull RTCIceCandidate *)candidate {
    NSLog(@"%s",__func__);
    NSString* weakMyRoom = self.myRoom;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary* dict = [[NSDictionary alloc] initWithObjects:@[@"candidate",
                                                                     [NSString stringWithFormat:@"%d", candidate.sdpMLineIndex],
                                                                     candidate.sdpMid,
                                                                     candidate.sdp]
                                                           forKeys:@[@"type", @"label", @"id", @"candidate"]];
        
        [[SignalClient getInstance] sendMessage: weakMyRoom
                                        withMsg:dict];
    });
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"%s",__func__);
}

/** New data channel has been opened. */
- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didOpenDataChannel:(nonnull RTCDataChannel *)dataChannel {
    NSLog(@"%s",__func__);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddReceiver:(RTCRtpReceiver *)rtpReceiver streams:(NSArray<RTCMediaStream *> *)mediaStreams{
    NSLog(@"%s",__func__);
    
    RTCMediaStreamTrack* track = rtpReceiver.track;
    if([track.kind isEqualToString:kRTCMediaStreamTrackKindVideo]){
        
        if(!self.remoteVideoView){
            NSLog(@"error:remoteVideoView have not been created!");
            return;
        }
        self.remoteVideoTrack = (RTCVideoTrack*)track;
        [self.remoteVideoTrack addRenderer: self.remoteVideoView];
    }
}



#pragma mark - RTCEAGLVideoViewDelegate
- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size {
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//当数据缓冲区(data buffer)一有数据时，AVFoundation就调用该方法。在该代理方法中，我们可以获取视频帧、处理视频帧、显示视频帧。实时滤镜就是在这里进行处理的。在这个方法中将缓冲区中的视频数据（就是帧图片）输出到要显示的layer上。
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    NSLog(@"output = %@,sampleBuffer = %@ ",output,sampleBuffer);
    
}

#pragma mark initlayout
- (void)initLayout {
    [self.localVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.view).with.offset(0);
    }];
    [self.remoteVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).with.offset(40);
        make.right.equalTo(self.view).with.offset(-10);
        make.width.equalTo(@120);
        make.height.equalTo(@160);
    }];
    
    [self.leaveButton setFrame:CGRectMake(self.view.bounds.size.width/2-40,
                                          self.view.bounds.size.height-140,
                                          80,
                                          80)];
    
    [self.leaveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.width.equalTo(@80);
        make.height.equalTo(@80);
        make.bottom.equalTo(self.view).with.offset(-40);
    }];
    
}

#pragma mark setter and getter
- (RTCCameraPreviewView *)localVideoView {
    if (!_localVideoView) {
        _localVideoView = [[RTCCameraPreviewView alloc] init];
    }
    return _localVideoView;
}

- (RTCEAGLVideoView *)remoteVideoView {
    if (!_remoteVideoView) {
        _remoteVideoView = [[RTCEAGLVideoView alloc] init];
    }
    return _remoteVideoView;
}

- (UIButton *)leaveButton {
    if (!_leaveButton) {
        _leaveButton = [[UIButton alloc] init];
        [_leaveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_leaveButton setTintColor:[UIColor whiteColor]];
        [_leaveButton setTitle:@"leave" forState:UIControlStateNormal];
        [_leaveButton setBackgroundColor:[UIColor greenColor]];
        [_leaveButton setShowsTouchWhenHighlighted:YES];
        [_leaveButton.layer setCornerRadius:40];
        [_leaveButton.layer setBorderWidth:1];
        [_leaveButton setClipsToBounds:FALSE];
    }
    return _leaveButton;
}




@end
