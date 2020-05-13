package com.example.webrtcandroid.presenter;

import com.cbl.base.inter.RxBasePresenterImpl;
import com.example.webrtcandroid.Contract.WelcomeContract;

public class WelcomePresenter extends RxBasePresenterImpl<WelcomeContract.View> implements WelcomeContract.Presenter  {

    public WelcomePresenter(WelcomeContract.View view) {
        super(view);
    }
}

