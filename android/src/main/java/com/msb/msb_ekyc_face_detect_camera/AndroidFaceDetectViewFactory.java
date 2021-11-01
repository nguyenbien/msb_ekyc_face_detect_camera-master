package com.msb.msb_ekyc_face_detect_camera;

import android.content.Context;
import android.app.Activity;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class AndroidFaceDetectViewFactory extends PlatformViewFactory {

    private final Activity activity;
    private final BinaryMessenger binaryMessenger;

    public AndroidFaceDetectViewFactory(Activity activity, BinaryMessenger binaryMessenger) {
        super(StandardMessageCodec.INSTANCE);
        this.activity = activity;
        this.binaryMessenger = binaryMessenger;
    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
        return new AndroidFaceDetectView(context, activity, binaryMessenger, i);
    }
}