package com.example.webrtcandroid.Contract;

import com.cbl.base.inter.HexBaseView;
import com.cbl.base.inter.RxBasePresenter;

public interface HomeContract {

    interface Presenter extends RxBasePresenter {
        void joinRoom(String url, String roomId);
    }

    interface View extends HexBaseView {
        void showJoinResult(boolean isSuccess, String msg);
    }

}
