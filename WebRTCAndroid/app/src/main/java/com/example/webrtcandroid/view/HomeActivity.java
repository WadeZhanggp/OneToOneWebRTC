package com.example.webrtcandroid.view;

import android.Manifest;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.cbl.base.activity.RxMvpBaseActivity;
import com.cbl.base.tools.ToastUtils;
import com.cbl.base.view.FindViewById;
import com.example.webrtcandroid.App;
import com.example.webrtcandroid.Contract.HomeContract;
import com.example.webrtcandroid.R;
import com.example.webrtcandroid.presenter.HomePresenter;

import pub.devrel.easypermissions.EasyPermissions;

public class HomeActivity extends RxMvpBaseActivity<HomeContract.Presenter> implements HomeContract.View {

    private
    @FindViewById(id = R.id.tvJoin)
    TextView tvJoin;
    private
    @FindViewById(id = R.id.tvSetting)
    TextView tvSetting;
    private
    @FindViewById(id = R.id.editRoomId)
    EditText editRoom;

    private String rtcUrl = "";


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);

        String[] perms = {Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO};
        if (!EasyPermissions.hasPermissions(this, perms)) {
            EasyPermissions.requestPermissions(this, "Need permissions for camera & microphone", 0, perms);
        }
    }

    @Override
    public void initView() {
        super.initView();

        //加入房间
        tvJoin.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mvpPresenter.joinRoom(rtcUrl, editRoom.getText().toString());
            }
        });

        tvSetting.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

            }
        });
    }

    @Override
    public HomeContract.Presenter createPresenter() {
        return new HomePresenter(this);
    }


    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void showJoinResult(boolean isSuccess, String msg) {
        if (isSuccess) {
            Bundle bundle = new Bundle();
            bundle.putString("roomId",msg);
            toActivity(CallActivity.class, bundle);
            return;
        }
        ToastUtils.showToast(App.getInstance().getContext(), msg);
    }
}
