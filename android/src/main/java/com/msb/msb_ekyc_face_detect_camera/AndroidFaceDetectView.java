package com.msb.msb_ekyc_face_detect_camera;

import android.content.Context;
import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.view.LayoutInflater;
import android.Manifest;
import android.os.CountDownTimer;
import android.util.Log;
import android.text.TextUtils;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.PermissionDeniedResponse;
import com.karumi.dexter.listener.PermissionGrantedResponse;
import com.karumi.dexter.listener.PermissionRequest;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import com.karumi.dexter.listener.single.PermissionListener;

import com.google.gson.Gson;
import com.lib.ekyc.core.ekyc.CameraSourcePreview;
import com.lib.ekyc.core.ekyc.EKYCManager;
import com.lib.ekyc.core.ekyc.GraphicOverlay;
import com.lib.ekyc.core.record.EKYCLogger;
import com.lib.ekyc.entity.DetectionParams;
import com.lib.ekyc.entity.Gesture;
import com.lib.ekyc.events.OnEKYCEvernts;
import com.lib.ekyc.misc.DetectionEvent;

import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import butterknife.BindView;
import butterknife.ButterKnife;

public class AndroidFaceDetectView implements PlatformView, MethodCallHandler, OnEKYCEvernts {

    private static final String TAG = "AndroidFaceDetectView";

    private int viewId;
    private Context context;

    private Activity activity;
    private BinaryMessenger binaryMessenger;
    private View view;
    private MethodChannel channel;
    private boolean channelReady = false;
    private boolean permisstionGranted = false;
    private boolean isInitSuccess = false;
    private boolean isInitTimerDone = false;

    private EKYCManager ekycManager = null;
    private DetectionParams detectionParams = null;
    @BindView(R2.id.fireFaceOverlay)
    GraphicOverlay graphicOverlay;

    @BindView(R2.id.firePreview)
    CameraSourcePreview cameraSourcePreview;
    private List<Gesture> gestures;
    List <Gesture> listExpectedGesture = new ArrayList<>();
    private static Gson gson  = new Gson();

    @Nullable private EventChannel.EventSink eventSink;

    AndroidFaceDetectView(Context context, Activity activity, BinaryMessenger binaryMessenger, int id) {
        this.context = context;
        this.activity = activity;
        this.binaryMessenger = binaryMessenger;
        this.viewId = id;
        this.view = LayoutInflater.from(activity).inflate(R.layout.ekyc_preview, null);
        this.channelReady = false;
        this.permisstionGranted = false;

        ButterKnife.bind(this, view);

        channel = new MethodChannel(binaryMessenger, "face_detect_view_method_channel");
        channel.setMethodCallHandler(this);

        HardwarePermissionCheck();

        // init ekyc params
        ekycManager = new EKYCManager(activity,this);
        detectionParams = new DetectionParams();
        gestures = new ArrayList<>();
        initGestures();
    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.i(TAG, "onMethodCall " + call.method);
        switch (call.method) {
            case "initCamera":
                List<Map<String, Object>> gestureListJson = call.argument("expectedGestures");
                listExpectedGesture.clear();
                long time = 30 * 1000;
                if (gestureListJson != null) {
                    for (int i = 0; i < gestureListJson.size(); i++) {
                        Map<String, Object> gesture = gestureListJson.get(i);
                        //do something with i
                        if (gesture != null) {
                            Log.i(TAG, gesture.toString());
                            String gestureName = gesture.get("name").toString();
                            if (gestureName != null && !gestureName.isEmpty()) {
                                listExpectedGesture.add(new Gesture(gestureName, time, 0, 0));
                            }
                        }
                    }
                }
                initGestures();
                init();
                result.success(String.valueOf(viewId));
                break;
            case "startCamera":
                startEkycModule(detectionParams);
                break;
            case "stopCamera":
                //ekycManager.stopDetection();
                break;
            case "resumeCameraPreview":
                break;
            case "stopCameraPreview":
                break;
            case "openFlash":
                break;
            case "closeFlash":
                break;
            case "toggleFlash":
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public void dispose() {
        channelReady = false;
        permisstionGranted = false;
    }

    /**
     * camera & audio permissions
     */
    private void HardwarePermissionCheck() {
        Dexter.withContext(context)
                .withPermissions(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
                .withListener(new MultiplePermissionsListener() {
                    @Override
                    public void onPermissionsChecked(MultiplePermissionsReport multiplePermissionsReport) {
                        if (multiplePermissionsReport.areAllPermissionsGranted()){
                            Log.i(TAG, "All permission granted!");
                            permisstionGranted = true;
                            if (!isInitSuccess && isInitTimerDone && channelReady) initSuccess();
                        }
                    }

                    @Override
                    public void onPermissionRationaleShouldBeShown(List<PermissionRequest> list, PermissionToken permissionToken) {

                    }
                }).check();
    }

    /**
     * waiting init event channel
     */
    private CountDownTimer initTimer;
    private void init() {
        isInitSuccess = false;
        isInitTimerDone = false;
        Log.i(TAG, "init() viewId: " + viewId);
        new EventChannel(binaryMessenger, "face_detect_view_event_channel_" + viewId)
                .setStreamHandler(
                        new EventChannel.StreamHandler() {
                            @Override
                            public void onListen(Object arguments, EventChannel.EventSink sink) {
                                eventSink = sink;
                                channelReady = true;
                                EKYCLogger.print(TAG, "Create event stream success! onListen");
                            }

                            @Override
                            public void onCancel(Object arguments) {
                                eventSink = null;
                            }
                        });
        initTimer = new CountDownTimer(5*1000, 1000L) {
            public void onTick(long millisUntilFinished) {
                Log.i(TAG, "initTimer Ontick" + channelReady + permisstionGranted);
                if (channelReady && permisstionGranted) {
                    initSuccess();
                }
            }

            public void onFinish() {
                isInitTimerDone = true;
            }
        };
        initTimer.start();
    }

    private void initSuccess () {
        isInitSuccess = true;
        initTimer.cancel();
        String jsonString = gson.toJson(detectionParams.getGestureList());
        EKYCLogger.print(TAG,"Gesture list json: " + jsonString);
        Map<String, Object> event = new HashMap<>();
        event.put("eventType", "initSuccess");
        event.put("eventData", jsonString);
        eventSink.success(event);
    }

    private void initGestures () {
        gestures.clear();
        if (listExpectedGesture == null || listExpectedGesture.size() <= 0) {
            long time = 30 * 1000;
            Gesture gesture0 = new Gesture("blink_eye", time, 0, 0);
            Gesture gesture1 = new Gesture("turn_right", time, 0, 0);
            Gesture gesture2 = new Gesture("turn_left", time, 0, 0);
            Gesture gesture3 = new Gesture("smile", time, 0, 0);
            gestures.add(gesture0);
            gestures.add(gesture1);
            gestures.add(gesture2);
            gestures.add(gesture3);
        } else {
            gestures.addAll(listExpectedGesture);
        }
        detectionParams.setGestureList(gestures);
    }

    /**
     *
     * @param detectionParams
     */
    private void startEkycModule(DetectionParams detectionParams){
        initGestures();
        ekycManager.startDetection(cameraSourcePreview,graphicOverlay,detectionParams);
        countDownTimer = detectNextGesture();
    }

    private CountDownTimer countDownTimer = null;
    private boolean onWaitingForStopDetection = false;
    private String errorString = "";
    @Override
    public void detectionEvents(DetectionEvent event, String gesture) {
        if(!event.equals(DetectionEvent.STARTED) && countDownTimer != null){
            countDownTimer.cancel();
            EKYCLogger.print(TAG,"Cancelled "+ gesture);
        }
        if(event.equals(DetectionEvent.SUCCESS)){
            countDownTimer = handleSuccess(gesture);
            sendEventToDart("face_detect_event", gesture.toString());
        } else if(event.equals(DetectionEvent.TIME_OUT)){
            handleFailure("timeout");
        }else if(event.equals(DetectionEvent.MULTIPLE_FACE)){
            handleFailure("multipleFaces");
        }else if(event.equals(DetectionEvent.LOST_FACE)){
            handleFailure("lostFaceTrack");
        }else if(event.equals(DetectionEvent.STARTED)){

        }
        //TODO we should directly send data back to web via java script interface
        EKYCLogger.print(TAG,"Detection event "+event+ " gesture " + gesture);
        //Toast.makeText(this, "Detection event "+event+ "gesture "+gesture, Toast.LENGTH_LONG).show();
    }

    private void handleFailure(String errorString) {
        /*if (onWaitingForStopDetection) return;
        onWaitingForStopDetection = true;
        errorString = gesture.toString();
        new CountDownTimer(1000, 1000) {
            public void onTick(long millisUntilFinished) {
            }
            public void onFinish() {
                try {
                    ekycManager.stopDetection();
                } catch (Exception e) {
                    // This will catch any exception, because they are all descended from Exception
                    EKYCLogger.print(TAG, "Stop camera fail with exception: " + e.getMessage());
                }

                sendEventToDart("face_detect_event_failed", errorString);
                onWaitingForStopDetection = false;
            }
        }.start();*/
        ekycManager.stopDetection();
        sendEventToDart("face_detect_event_failed", errorString);
    }

    /**
     * This will handle susses
     * remove
     * include check the remaining gestures
     * invoke next gestre
     * @param gesture
     */

    private CountDownTimer handleSuccess(String gesture) {
        CountDownTimer timer = null;
        if(gestures == null)
            return timer;
        if(gestures.size() <= 0)
            return timer;
        if(gesture == null)
            return timer;
        timer =detectNextGesture();
        return timer;
    }

    /**
     *
     */
    private CountDownTimer detectNextGesture() {
        CountDownTimer timer = null;
        if(gestures.size() <= 0){
            return timer;
        }
        Gesture nextGexture = gestures.get(0);
        if(nextGexture == null)
        {
            EKYCLogger.printe(TAG,"gesture is null");
            return  timer;
        }
        timer = ekycManager.detectGesture(nextGexture);
        return  timer;
    }

    @Override
    public void onGestreDetectinCompleted(boolean b, String s) {
        EKYCLogger.print(TAG,"Detection event "+b+ "gesture "+s);
        /*if (b)*/ {
            sendEventToDart("face_detect_success", s);
        }
        //TODO fire event to web
        //cleaning detector
        //Toast.makeText(this, "face detection completed.", Toast.LENGTH_LONG).show();
    }

    void sendEventToDart(String eventType, @Nullable String eventData) {
        if (eventSink == null) {
            Log.e(TAG,"Send event fail: eventType: " + eventType + " event channel not ready!");
            return;
        }

        Map<String, String> event = new HashMap<>();
        event.put("eventType", eventType);
        if (!TextUtils.isEmpty(eventData)) {
            event.put("eventData", eventData);
        }
        eventSink.success(event);
    }
}