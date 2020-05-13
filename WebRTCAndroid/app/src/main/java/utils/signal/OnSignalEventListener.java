package utils.signal;

import org.json.JSONObject;

public interface OnSignalEventListener {

    void onConnected();
    void onConnecting();
    void onDisconnected();
    void onUserJoined(String roomName, String userID);
    void onUserLeaved(String roomName, String userID);
    void onRemoteUserJoined(String roomName);
    void onRemoteUserLeaved(String roomName, String userID);
    void onRoomFull(String roomName, String userID);
    void onMessage(JSONObject message);

}
