package com.example.webrtcandroid.view;

import android.content.Context;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import com.cbl.base.activity.RxMvpBaseActivity;
import com.cbl.base.view.FindViewById;
import com.example.webrtcandroid.Contract.CallContract;
import com.example.webrtcandroid.R;
import com.example.webrtcandroid.presenter.CallPresenter;

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
import org.webrtc.RendererCommon;
import org.webrtc.RtpReceiver;
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


public class CallActivity extends RxMvpBaseActivity<CallContract.Presenter> implements CallContract.View  {

    private
    @FindViewById(id = R.id.LogcatView)
    TextView mLogcatView;
    //继承 surface view
    private
    @FindViewById(id = R.id.LocalSurfaceView)
    SurfaceViewRenderer mLocalSurfaceView;
    private
    @FindViewById(id = R.id.RemoteSurfaceView)
    SurfaceViewRenderer mRemoteSurfaceView;


    private String mState = "init";
    private static final String TAG = "CallActivity";
    //Opengl ES
    private EglBase mRootEglBase;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_call);
    }

    @Override
    public void initView() {
        super.initView();
        mRootEglBase = EglBase.create();
        //初始化surface
        mLocalSurfaceView.init(mRootEglBase.getEglBaseContext(),null);
        mLocalSurfaceView.setScalingType(RendererCommon.ScalingType.SCALE_ASPECT_FILL);
        mLocalSurfaceView.setMirror(true);
        mLocalSurfaceView.setEnableHardwareScaler(false/*enabled*/);

        mRemoteSurfaceView.init(mRootEglBase.getEglBaseContext(), null);
        mRemoteSurfaceView.setScalingType(RendererCommon.ScalingType.SCALE_ASPECT_FILL);
        mRemoteSurfaceView.setMirror(true);
        mRemoteSurfaceView.setEnableHardwareScaler(true /* enabled */);
        mRemoteSurfaceView.setZOrderMediaOverlay(true);

        mvpPresenter.initRtc(mRootEglBase,mLocalSurfaceView,mRemoteSurfaceView);
        Bundle bundle = getBundle();
        String roomId = bundle.getString("roomId");
        mvpPresenter.joinRoom("https://www.wadezhanggp.xyz",roomId);

    }

    @Override
    protected void onResume() {
        super.onResume();
        mvpPresenter.videoCaptureStart();
    }

    @Override
    protected void onPause() {
        super.onPause();
        mvpPresenter.videoCaptureStop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mLocalSurfaceView.release();
        mRemoteSurfaceView.release();
        mvpPresenter.rtcDestory();

    }

    @Override
    public CallContract.Presenter createPresenter() {
        return new CallPresenter(this);
    }

    @Override
    public void showjoinRoomResult() {

    }

    @Override
    public void logcatOnUI(String msg) {
        Log.i(TAG, msg);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                String output = mLogcatView.getText() + "\n" + msg;
                mLogcatView.setText(output);
            }
        });
    }

    @Override
    public void updateCallView(boolean status) {
        if (status) {
            mRemoteSurfaceView.setVisibility(View.GONE);
        } else {
            mRemoteSurfaceView.setVisibility(View.VISIBLE);
        }
    }

    @Override
    public void releaseView() {
        if(mLocalSurfaceView != null) {
                mLocalSurfaceView.release();
                mLocalSurfaceView = null;
        }

        if(mRemoteSurfaceView != null) {
                mRemoteSurfaceView.release();
                mRemoteSurfaceView = null;
        }
        finish();
    }


}
