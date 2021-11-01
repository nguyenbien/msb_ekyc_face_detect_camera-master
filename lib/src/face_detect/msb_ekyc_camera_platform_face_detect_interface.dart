import 'package:msb_ekyc_face_detect_camera/src/msb_ekyc_face_detect_camera_platform_interface.dart';
import 'package:flutter/material.dart';

import 'msb_ekyc_camera_face_detect_plugin.dart';

/// MSBEkycCameraFaceDetectPlatform
abstract class MSBEkycCameraFaceDetectPlatform extends ChangeNotifier
    with MSBEkycCameraPlatform {
  /// Only mock implementations should set this to true.
  ///
  /// Mockito mocks are implementing this class with `implements` which is forbidden for anything
  /// other than mocks (see class docs). This property provides a backdoor for mockito mocks to
  /// skip the verification that the class isn't implemented with `implements`.
  @visibleForTesting
  bool get isMock => false;

  static MSBEkycCameraFaceDetectPlatform _instance = MSBEkycCameraFaceDetectPlugin();

  bool _isStartCamera = false;
  bool _isStartCameraPreview = false;
  bool _isOpenFlash = false;

  /// The default instance of [MSBEkycCameraFaceDetectPlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [MSBEkycCameraFaceDetectPlatform] when they
  /// register themselves.
  ///
  static MSBEkycCameraFaceDetectPlatform get instance => _instance;

  ///
  /// Whether start camera
  bool get isStartCamera => _isStartCamera;

  ///
  /// Whether start camera preview or start to recognize
  bool get isStartCameraPreview => _isStartCameraPreview;

  ///
  /// Whether open the flash
  bool get isOpenFlash => _isOpenFlash;

  String _unsupportedPlatformDescription =
      "Unsupported platforms, working hard to support";

  String get unsupportedPlatformDescription => _unsupportedPlatformDescription;

  set unsupportedPlatformDescription(String text) {
    if (text == null || text.isEmpty) {
      return;
    }
    _unsupportedPlatformDescription = text;
  }

  ///
  /// Instance update
  static set instance(MSBEkycCameraFaceDetectPlatform instance) {
    if (!instance.isMock) {
      try {
        instance._verifyProvidesDefaultImplementations();
      } on NoSuchMethodError catch (_) {
        throw AssertionError(
            'Platform interfaces must not be implemented with `implements`');
      }
    }
    _instance = instance;
  }

  /// Returns a widget displaying.
  Widget buildFaceDetectView(BuildContext context) {
    throw UnimplementedError('buildView() has not been implemented.');
  }

  ///
  /// View created of face detect widget
  onPlatformFaceDetectViewCreated(int id) {
    notifyListeners();
  }

  ///
  /// Init camera without open Face Detect camera.
  initCamera({List<dynamic> expectedGestures}) async {
    if (expectedGestures != null && expectedGestures.length > 0)
      return await MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("initCamera",
          <String, dynamic>{
            'expectedGestures': expectedGestures,
          });
    return await MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("initCamera");
  }

  ///
  /// Start camera without open Face Detect camera,this is just open camera.
  startCamera() async {
    _isStartCamera = true;
    MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("startCamera");
  }

  ///
  /// Stop camera.
  stopCamera() async {
    _isStartCamera = false;
    MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("stopCamera");
  }

  ///
  /// Start camera preview with open Face Detect camera,this is open code scanner.
  Future<String> startCameraPreview() async {
    _isStartCameraPreview = true;
    return await MSBEkycCameraPlatform.methodChannelFaceDetect
        .invokeMethod("resumeCameraPreview");
  }

  ///
  /// Stop camera preview.
  stopCameraPreview() async {
    _isStartCameraPreview = false;
    MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("stopCameraPreview");
  }

  ///
  /// Open camera flash.
  openFlash() async {
    _isOpenFlash = true;
    MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("openFlash");
  }

  ///
  /// Close camera flash.
  closeFlash() async {
    _isOpenFlash = false;
    MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("closeFlash");
  }

  ///
  /// Toggle camera flash.
  toggleFlash() async {
    bool flash = isOpenFlash;
    _isOpenFlash = !flash;
    MSBEkycCameraPlatform.methodChannelFaceDetect.invokeMethod("toggleFlash");
  }

  // This method makes sure that MSBEkycCamera isn't implemented with `implements`.
  //
  // See class doc for more details on why implementing this class is forbidden.
  //
  // This private method is called by the instance setter, which fails if the class is
  // implemented with `implements`.
  void _verifyProvidesDefaultImplementations() {}
}
