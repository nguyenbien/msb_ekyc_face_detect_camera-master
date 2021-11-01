import 'package:msb_ekyc_face_detect_camera/src/face_detect/msb_ekyc_camera_platform_face_detect_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../msb_ekyc_face_detect_camera_platform_interface.dart';
import 'msb_ekyc_camera_platform_face_detect_interface.dart';

///
/// MSBEkycCameraFaceDetectPlugin
class MSBEkycCameraFaceDetectPlugin extends MSBEkycCameraFaceDetectPlatform {
  @override
  Widget buildFaceDetectView(BuildContext context) {
    return _cameraView(context);
  }

  /// Face Detect widget
  ///
  /// Support android and ios platform face detect
  Widget _cameraView(BuildContext context) {
    TargetPlatform targetPlatform = Theme.of(context).platform;

    if (targetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: MSBEkycCameraPlatform.viewIdOfFaceDetect,
        onPlatformViewCreated: (int id) {
          onPlatformFaceDetectViewCreated(id);
        },
        creationParams: <String, dynamic>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (targetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: MSBEkycCameraPlatform.viewIdOfFaceDetect,
        onPlatformViewCreated: (int id) {
          onPlatformFaceDetectViewCreated(id);
        },
        creationParams: <String, dynamic>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      return Center(
        child: Text(
          "$unsupportedPlatformDescription",
        ),
      );
    }
  }
}
