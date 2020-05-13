package com.example.webrtcandroid.presenter;

import com.cbl.base.inter.RxBasePresenterImpl;
import com.example.webrtcandroid.Contract.HomeContract;

public class HomePresenter extends RxBasePresenterImpl<HomeContract.View> implements HomeContract.Presenter {


    public HomePresenter(HomeContract.View view) {
        super(view);
    }
}
