package com.example.webrtcandroid.presenter;

import android.content.Context;
import android.util.Log;
import android.view.View;

import com.cbl.base.inter.RxBasePresenterImpl;
import com.example.webrtcandroid.App;
import com.example.webrtcandroid.Contract.CallContract;
import com.example.webrtcandroid.Contract.WelcomeContract;

import org.json.JSONException;
import org.json.JSONObject;
import org.webrtc.AudioSource;
import org.webrtc.AudioTrack;
import org.webrtc.Camera1Enumerator;
import org.webrtc.Camera2Enumerator;
import org.webrtc.CameraEnumerator;
import org.webrtc.DataChannel;
import org.webrtc.DefaultVideoDecoderFactory;
import org.webrtc.DefaultVideoEncoderFactory;
import org.webrtc.EglBase;
import org.webrtc.IceCandidate;
import org.webrtc.Logging;
import org.webrtc.MediaConstraints;
import org.webrtc.MediaStream;
import org.webrtc.MediaStreamTrack;
import org.webrtc.PeerConnection;
import org.webrtc.PeerConnectionFactory;
import org.webrtc.RtpReceiver;
import org.webrtc.SdpObserver;
import org.webrtc.SessionDescription;
import org.webrtc.SurfaceTextureHelper;
import org.webrtc.SurfaceViewRenderer;
import org.webrtc.VideoCapturer;
import org.webrtc.VideoDecoderFactory;
import org.webrtc.VideoEncoderFactory;
import org.webrtc.VideoSource;
import org.webrtc.VideoTrack;

import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

import utils.Constant;
import utils.signal.OnSignalEventListener;
import utils.signal.SignalClient;

public class CallPresenter extends RxBasePresenterImpl<CallContract.View> implements CallContract.Presenter  {

    public CallPresenter(CallContract.View view) {
        super(view);
    }
    private static final String TAG = "CallActivity";
    private String mState = "init";

    private PeerConnectionFactory mPeerConnectionFactory;
    //Opengl ES
    private EglBase mRootEglBase;
    //用户数数据传输
    private PeerConnection mPeerConnection;


    //纹理渲染
    private SurfaceTextureHelper mSurfaceTextureHelper;

    private VideoTrack mVideoTrack;
    private AudioTrack mAudioTrack;
    private VideoCapturer mVideoCapturer;

    SurfaceViewRenderer mLocalSurfaceView;
    SurfaceViewRenderer mRemoteSurfaceView;

    @Override
    public void initRtc(EglBase eglBase, SurfaceViewRenderer localSurfaceView, SurfaceViewRenderer remoteSurfaceView) {
        mLocalSurfaceView = localSurfaceView;
        mRemoteSurfaceView = remoteSurfaceView;
        //创建 factory， pc是从factory里获得的
        mRootEglBase = eglBase;
        mPeerConnectionFactory = createPeerConnectionFactory(App.getInstance().getContext());
        // NOTE: this _must_ happen while PeerConnectionFactory is alive!
        Logging.enableLogToDebugOutput(Logging.Severity.LS_VERBOSE);

        mVideoCapturer = createVideoCapturer();

        mSurfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", mRootEglBase.getEglBaseContext());
        VideoSource videoSource = mPeerConnectionFactory.createVideoSource(false);
        mVideoCapturer.initialize(mSurfaceTextureHelper, App.getInstance().getContext(), videoSource.getCapturerObserver());

        mVideoTrack = mPeerConnectionFactory.createVideoTrack(Constant.VIDEO_TRACK_ID, videoSource);
        mVideoTrack.setEnabled(true);
        mVideoTrack.addSink(mLocalSurfaceView);

        AudioSource audioSource = mPeerConnectionFactory.createAudioSource(new MediaConstraints());
        mAudioTrack = mPeerConnectionFactory.createAudioTrack(Constant.AUDIO_TRACK_ID, audioSource);
        mAudioTrack.setEnabled(true);

        SignalClient.getInstance().setSignalEventListener(mOnSignalEventListener);
    }

    @Override
    public void joinRoom(String url, String roomId) {
        SignalClient.getInstance().joinRoom(url, roomId);
    }

    @Override
    public void videoCaptureStart() {
        mVideoCapturer.startCapture(Constant.VIDEO_RESOLUTION_WIDTH, Constant.VIDEO_RESOLUTION_HEIGHT, Constant.VIDEO_FPS);
    }

    @Override
    public void videoCaptureStop() {
        try {
            mVideoCapturer.stopCapture();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void rtcDestory() {
        getView().logcatOnUI("Leave room, Wait ...");
        hangup();
        SignalClient.getInstance().leaveRoom();
        mVideoCapturer.dispose();
        mSurfaceTextureHelper.dispose();
        PeerConnectionFactory.stopInternalTracingCapture();
        PeerConnectionFactory.shutdownInternalTracer();
        mPeerConnectionFactory.dispose();
    }

    private void updateCallState(boolean idle) {
        getView().updateCallView(idle);
    }

    //sdp监听
    public static class SimpleSdpObserver implements SdpObserver {
        @Override
        public void onCreateSuccess(SessionDescription sessionDescription) {
            Log.i(TAG, "SdpObserver: onCreateSuccess !");
        }

        @Override
        public void onSetSuccess() {
            Log.i(TAG, "SdpObserver: onSetSuccess");
        }

        @Override
        public void onCreateFailure(String msg) {
            Log.e(TAG, "SdpObserver onCreateFailure: " + msg);
        }

        @Override
        public void onSetFailure(String msg) {

            Log.e(TAG, "SdpObserver onSetFailure: " + msg);
        }
    }

    //挂断
    public void hangup() {
        getView().logcatOnUI("Hangup Call, Wait ...");
        if (mPeerConnection == null) {
            return;
        }
        mPeerConnection.close();
        mPeerConnection = null;
        getView().logcatOnUI("Hangup Done.");
        updateCallState(true);
    }

    //回复通话
    public void doAnswerCall() {
        getView().logcatOnUI("Answer Call, Wait ...");

        if (mPeerConnection == null) {
            mPeerConnection = createPeerConnection();
        }

        MediaConstraints sdpMediaConstraints = new MediaConstraints();
        Log.i(TAG, "Create answer ...");
        mPeerConnection.createAnswer(new SimpleSdpObserver() {
            @Override
            public void onCreateSuccess(SessionDescription sessionDescription) {
                Log.i(TAG, "Create answer success !");
                mPeerConnection.setLocalDescription(new SimpleSdpObserver(),
                        sessionDescription);

                JSONObject message = new JSONObject();
                try {
                    message.put("type", "answer");
                    message.put("sdp", sessionDescription.description);
                    SignalClient.getInstance().sendMessage(message);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }, sdpMediaConstraints);
        updateCallState(false);
    }

    //发起通话
    public void doStartCall() {
        getView().logcatOnUI("Start Call, Wait ...");
        if (mPeerConnection == null) {
            mPeerConnection = createPeerConnection();
        }
        MediaConstraints mediaConstraints = new MediaConstraints();
        mediaConstraints.mandatory.add(new MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"));
        mediaConstraints.mandatory.add(new MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"));
        mediaConstraints.optional.add(new MediaConstraints.KeyValuePair("DtlsSrtpKeyAgreement", "true"));
        mPeerConnection.createOffer(new SimpleSdpObserver() {
            @Override
            public void onCreateSuccess(SessionDescription sessionDescription) {
                Log.i(TAG, "Create local offer success: \n" + sessionDescription.description);
                mPeerConnection.setLocalDescription(new SimpleSdpObserver(), sessionDescription);
                JSONObject message = new JSONObject();
                try {
                    message.put("type", "offer");
                    message.put("sdp", sessionDescription.description);
                    SignalClient.getInstance().sendMessage(message);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }, mediaConstraints);
    }

    //创建 PeerConnectionFactory
    public PeerConnectionFactory createPeerConnectionFactory(Context context) {
        final VideoEncoderFactory encoderFactory;
        final VideoDecoderFactory decoderFactory;

        encoderFactory = new DefaultVideoEncoderFactory(
                mRootEglBase.getEglBaseContext(),
                false /* enableIntelVp8Encoder */,
                true);
        decoderFactory = new DefaultVideoDecoderFactory(mRootEglBase.getEglBaseContext());

        PeerConnectionFactory.initialize(PeerConnectionFactory.InitializationOptions.builder(context)
                .setEnableInternalTracer(true)
                .createInitializationOptions());

        PeerConnectionFactory.Builder builder = PeerConnectionFactory.builder()
                .setVideoEncoderFactory(encoderFactory)
                .setVideoDecoderFactory(decoderFactory);
        builder.setOptions(null);

        return builder.createPeerConnectionFactory();
    }

    /*
     * Read more about Camera2 here
     * https://developer.android.com/reference/android/hardware/camera2/package-summary.html
     **/
    private VideoCapturer createVideoCapturer() {
        if (Camera2Enumerator.isSupported(App.getInstance().getContext())) {
            return createCameraCapturer(new Camera2Enumerator(App.getInstance().getContext()));
        } else {
            return createCameraCapturer(new Camera1Enumerator(true));
        }
    }

    private VideoCapturer createCameraCapturer(CameraEnumerator enumerator) {
        final String[] deviceNames = enumerator.getDeviceNames();

        // First, try to find front facing camera
        Log.d(TAG, "Looking for front facing cameras.");
        for (String deviceName : deviceNames) {
            if (enumerator.isFrontFacing(deviceName)) {
                Logging.d(TAG, "Creating front facing camera capturer.");
                VideoCapturer videoCapturer = enumerator.createCapturer(deviceName, null);
                if (videoCapturer != null) {
                    return videoCapturer;
                }
            }
        }

        // Front facing camera not found, try something else
        Log.d(TAG, "Looking for other cameras.");
        for (String deviceName : deviceNames) {
            if (!enumerator.isFrontFacing(deviceName)) {
                Logging.d(TAG, "Creating other camera capturer.");
                VideoCapturer videoCapturer = enumerator.createCapturer(deviceName, null);
                if (videoCapturer != null) {
                    return videoCapturer;
                }
            }
        }
        return null;
    }

    private PeerConnection.Observer mPeerConnectionObserver = new PeerConnection.Observer() {
        @Override
        public void onSignalingChange(PeerConnection.SignalingState signalingState) {
            Log.i(TAG, "onSignalingChange: " + signalingState);
        }

        @Override
        public void onIceConnectionChange(PeerConnection.IceConnectionState iceConnectionState) {
            Log.i(TAG, "onIceConnectionChange: " + iceConnectionState);
        }

        @Override
        public void onIceConnectionReceivingChange(boolean b) {
            Log.i(TAG, "onIceConnectionChange: " + b);
        }

        @Override
        public void onIceGatheringChange(PeerConnection.IceGatheringState iceGatheringState) {
            Log.i(TAG, "onIceGatheringChange: " + iceGatheringState);
        }

        @Override
        public void onIceCandidate(IceCandidate iceCandidate) {
            Log.i(TAG, "onIceCandidate: " + iceCandidate);

            try {
                JSONObject message = new JSONObject();
                //message.put("userId", RTCSignalClient.getInstance().getUserId());
                message.put("type", "candidate");
                message.put("label", iceCandidate.sdpMLineIndex);
                message.put("id", iceCandidate.sdpMid);
                message.put("candidate", iceCandidate.sdp);
                SignalClient.getInstance().sendMessage(message);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        @Override
        public void onIceCandidatesRemoved(IceCandidate[] iceCandidates) {
            for (int i = 0; i < iceCandidates.length; i++) {
                Log.i(TAG, "onIceCandidatesRemoved: " + iceCandidates[i]);
            }
            mPeerConnection.removeIceCandidates(iceCandidates);
        }

        @Override
        public void onAddStream(MediaStream mediaStream) {
            Log.i(TAG, "onAddStream: " + mediaStream.videoTracks.size());
        }

        @Override
        public void onRemoveStream(MediaStream mediaStream) {
            Log.i(TAG, "onRemoveStream");
        }

        @Override
        public void onDataChannel(DataChannel dataChannel) {
            Log.i(TAG, "onDataChannel");
        }

        @Override
        public void onRenegotiationNeeded() {
            Log.i(TAG, "onRenegotiationNeeded");
        }

        @Override
        public void onAddTrack(RtpReceiver rtpReceiver, MediaStream[] mediaStreams) {
            MediaStreamTrack track = rtpReceiver.track();
            if (track instanceof VideoTrack) {
                Log.i(TAG, "onAddVideoTrack");
                VideoTrack remoteVideoTrack = (VideoTrack) track;
                remoteVideoTrack.setEnabled(true);
                remoteVideoTrack.addSink(mRemoteSurfaceView);
            }
        }
    };

    //创建peerconnect
    public PeerConnection createPeerConnection() {
        Log.i(TAG, "Create PeerConnection ...");

        LinkedList<PeerConnection.IceServer> iceServers = new LinkedList<PeerConnection.IceServer>();

        PeerConnection.IceServer ice_server =
                PeerConnection.IceServer.builder("turn:xxxx:3478")
                        .setPassword("xxx")
                        .setUsername("xxx")
                        .createIceServer();

        iceServers.add(ice_server);

        PeerConnection.RTCConfiguration rtcConfig = new PeerConnection.RTCConfiguration(iceServers);
        // TCP candidates are only useful when connecting to a server that supports
        // ICE-TCP.
        rtcConfig.tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED;
        //rtcConfig.bundlePolicy = PeerConnection.BundlePolicy.MAXBUNDLE;
        //rtcConfig.rtcpMuxPolicy = PeerConnection.RtcpMuxPolicy.REQUIRE;
        rtcConfig.continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY;
        // Use ECDSA encryption.
        //rtcConfig.keyType = PeerConnection.KeyType.ECDSA;
        // Enable DTLS for normal calls and disable for loopback calls.
        rtcConfig.enableDtlsSrtp = true;
        //rtcConfig.sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN;
        PeerConnection connection =
                mPeerConnectionFactory.createPeerConnection(rtcConfig,
                        mPeerConnectionObserver);
        if (connection == null) {
            Log.e(TAG, "Failed to createPeerConnection !");
            return null;
        }

        List<String> mediaStreamLabels = Collections.singletonList("ARDAMS");
        connection.addTrack(mVideoTrack, mediaStreamLabels);
        connection.addTrack(mAudioTrack, mediaStreamLabels);

        return connection;
    }

    //信号监听回调
    private OnSignalEventListener
            mOnSignalEventListener = new OnSignalEventListener() {

        @Override
        public void onConnected() {

            getView().logcatOnUI("Signal Server Connected !");
        }

        @Override
        public void onConnecting() {

            getView().logcatOnUI("Signal Server Connecting !");
        }

        @Override
        public void onDisconnected() {

            getView().logcatOnUI("Signal Server Disconnected!");
        }

        @Override
        public void onUserJoined(String roomName, String userID){

            getView().logcatOnUI("local user joined!");

            mState = "joined";

            //这里应该创建PeerConnection
            if (mPeerConnection == null) {
                mPeerConnection = createPeerConnection();
            }
        }

        @Override
        public void onUserLeaved(String roomName, String userID){
            getView().logcatOnUI("local user leaved!");

            mState = "leaved";
        }

        @Override
        public void onRemoteUserJoined(String roomName) {
            getView().logcatOnUI("Remote User Joined, room: " + roomName);

            if(mState.equals("joined_unbind")){
                if (mPeerConnection == null) {
                    mPeerConnection = createPeerConnection();
                }
            }

            mState = "joined_conn";
            //调用call， 进行媒体协商
            doStartCall();
        }

        @Override
        public void onRemoteUserLeaved(String roomName, String userID) {
            getView().logcatOnUI("Remote User Leaved, room: " + roomName + "uid:"  + userID);
            mState = "joined_unbind";

            if(mPeerConnection !=null ){
                mPeerConnection.close();
                mPeerConnection = null;
            }
        }

        @Override
        public void onRoomFull(String roomName, String userID){
            getView().logcatOnUI("The Room is Full, room: " + roomName + "uid:"  + userID);
            mState = "leaved";

            if(mVideoCapturer != null) {
                mVideoCapturer.dispose();
                mVideoCapturer = null;
            }

            if(mSurfaceTextureHelper != null) {
                mSurfaceTextureHelper.dispose();
                mSurfaceTextureHelper = null;

            }

            PeerConnectionFactory.stopInternalTracingCapture();
            PeerConnectionFactory.shutdownInternalTracer();

            if(mPeerConnectionFactory !=null) {
                mPeerConnectionFactory.dispose();
                mPeerConnectionFactory = null;
            }

            getView().releaseView();

        }

        @Override
        public void onMessage(JSONObject message) {

            Log.i(TAG, "onMessage: " + message);

            try {
                String type = message.getString("type");
                if (type.equals("offer")) {
                    onRemoteOfferReceived(message);
                }else if(type.equals("answer")) {
                    onRemoteAnswerReceived(message);
                }else if(type.equals("candidate")) {
                    onRemoteCandidateReceived(message);
                }else{
                    Log.w(TAG, "the type is invalid: " + type);
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        private void onRemoteOfferReceived(JSONObject message) {
            getView().logcatOnUI("Receive Remote Call ...");

            if (mPeerConnection == null) {
                mPeerConnection = createPeerConnection();
            }

            try {
                String description = message.getString("sdp");
                mPeerConnection.setRemoteDescription(
                        new SimpleSdpObserver(),
                        new SessionDescription(
                                SessionDescription.Type.OFFER,
                                description));
                doAnswerCall();
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        private void onRemoteAnswerReceived(JSONObject message) {
            getView().logcatOnUI("Receive Remote Answer ...");
            try {
                String description = message.getString("sdp");
                mPeerConnection.setRemoteDescription(
                        new SimpleSdpObserver(),
                        new SessionDescription(
                                SessionDescription.Type.ANSWER,
                                description));
            } catch (JSONException e) {
                e.printStackTrace();
            }
            updateCallState(false);
        }

        private void onRemoteCandidateReceived(JSONObject message) {
            getView().logcatOnUI("Receive Remote Candidate ...");
            try {
                IceCandidate remoteIceCandidate =
                        new IceCandidate(message.getString("id"),
                                message.getInt("label"),
                                message.getString("candidate"));

                mPeerConnection.addIceCandidate(remoteIceCandidate);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        private void onRemoteHangup() {
            getView().logcatOnUI("Receive Remote Hangup Event ...");
            hangup();
        }
    };


}

