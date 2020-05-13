package com.example.webrtcandroid.view;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;

import com.cbl.base.activity.RxMvpBaseActivity;
import com.cbl.base.cache.StringCache;
import com.example.webrtcandroid.Contract.WelcomeContract;
import com.example.webrtcandroid.R;
import com.example.webrtcandroid.presenter.WelcomePresenter;


public class WelcomeActivity extends RxMvpBaseActivity<WelcomeContract.Presenter> implements WelcomeContract.View  {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);
        toHomeActivity();
    }

    @Override
    public WelcomeContract.Presenter createPresenter() {
        return new WelcomePresenter(this);
    }

    private void toHomeActivity() {
        uiHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                toActivityWithFinish(HomeActivity.class,null);
            }
        },1500);

    }
}
