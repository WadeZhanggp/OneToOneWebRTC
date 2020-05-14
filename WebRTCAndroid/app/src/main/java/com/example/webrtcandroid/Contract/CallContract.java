package com.example.webrtcandroid.Contract;

import com.cbl.base.inter.HexBaseView;
import com.cbl.base.inter.RxBasePresenter;

import org.webrtc.EglBase;
import org.webrtc.SurfaceViewRenderer;

public interface CallContract {
    interface Presenter extends RxBasePresenter {
        void initRtc(EglBase eglBase, SurfaceViewRenderer localSurfaceView, SurfaceViewRenderer remoteSurfaceView) ;
        void joinRoom(String url, String roomId);
        void videoCaptureStart();
        void videoCaptureStop();
        void rtcDestory();
    }

    interface View extends HexBaseView {
        void showjoinRoomResult();
        void logcatOnUI(String msg);
        void updateCallView(boolean status);
        void releaseView();
    }
}
