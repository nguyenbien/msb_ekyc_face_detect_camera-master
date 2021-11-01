package com.msb.msb_ekyc_face_detect_camera;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import android.app.Activity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.plugin.common.BinaryMessenger;

/** MSBEkycFaceDetectCameraPlugin */
public final class MSBEkycFaceDetectCameraPlugin implements FlutterPlugin, ActivityAware{
    private @Nullable FlutterPluginBinding flutterPluginBinding;

    public MSBEkycFaceDetectCameraPlugin() {}

    public static void registerWith(Registrar registrar) {
        MSBEkycFaceDetectCameraPlugin plugin = new MSBEkycFaceDetectCameraPlugin();
        plugin.maybeStartCreatePlatformView(registrar.activity(),
                registrar.messenger(),
                registrar.platformViewRegistry());
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = binding;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        maybeStartCreatePlatformView(
                binding.getActivity(),
                flutterPluginBinding.getBinaryMessenger(),
                flutterPluginBinding.getPlatformViewRegistry());
    }

    @Override
    public void onDetachedFromActivity() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    private void maybeStartCreatePlatformView(
            Activity activity,
            BinaryMessenger messenger,
            PlatformViewRegistry platformViewRegistry) {
        platformViewRegistry
                .registerViewFactory(
                        "face_detect_view", new AndroidFaceDetectViewFactory(activity, messenger));
    }
}
