package com.example.webrtcandroid.presenter;

import android.Manifest;

import com.cbl.base.inter.RxBasePresenterImpl;
import com.example.webrtcandroid.App;
import com.example.webrtcandroid.Contract.HomeContract;
import com.example.webrtcandroid.R;

import pub.devrel.easypermissions.EasyPermissions;

public class HomePresenter extends RxBasePresenterImpl<HomeContract.View> implements HomeContract.Presenter {


    public HomePresenter(HomeContract.View view) {
        super(view);
    }

    @Override
    public void joinRoom(String url, String roomId) {

        if (roomId.equals("") || roomId == null){
            getView().showJoinResult(false, App.getInstance().getResources().getString(R.string.home_room_id_hint));
            return;
        }
        getView().showJoinResult(true, roomId);

    }
}
