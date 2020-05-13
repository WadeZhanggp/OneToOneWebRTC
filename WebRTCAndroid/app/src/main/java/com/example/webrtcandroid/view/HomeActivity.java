package com.example.webrtcandroid.view;

import android.os.Bundle;

import com.cbl.base.activity.RxMvpBaseActivity;
import com.example.webrtcandroid.Contract.HomeContract;
import com.example.webrtcandroid.R;
import com.example.webrtcandroid.presenter.HomePresenter;

public class HomeActivity extends RxMvpBaseActivity<HomeContract.Presenter> implements HomeContract.View {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);
    }

    @Override
    public HomeContract.Presenter createPresenter() {
        return new HomePresenter(this);
    }
}
