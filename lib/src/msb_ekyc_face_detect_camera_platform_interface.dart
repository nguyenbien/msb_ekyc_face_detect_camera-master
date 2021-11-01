import 'package:flutter/services.dart';

///
/// Channel
const MethodChannel _methodChannelFaceDetect =
    MethodChannel("face_detect_view_method_channel");
const MethodChannel _methodChannelIdCardDetect =
    MethodChannel("id_card_detect_view_method_channel");

const EventChannel _eventChannelFaceDetect =
      EventChannel("face_detect_view_event_channel");
const EventChannel _eventChannelIdCardDetect =
      EventChannel("id_card_detect_view_event_channel");

/// View id widget
const String _viewIdOfFaceDetect= "face_detect_view";
const String _viewIdOfIdCardDetect= "id_card_detect_view";


///MSBEkycCameraPlatform
///
abstract class MSBEkycCameraPlatform {
  ///
  /// MethodChannel
  static MethodChannel get methodChannelFaceDetect => _methodChannelFaceDetect;
  static MethodChannel get methodChannelIdCardDetect => _methodChannelIdCardDetect;

  ///
  /// EventChannel
  static EventChannel get eventChannelFaceDetect => _eventChannelFaceDetect;
  static EventChannel get eventChannelIdCardDetect => _eventChannelIdCardDetect;

  ///
  /// ViewId detect widget
  static String get viewIdOfFaceDetect => _viewIdOfFaceDetect;
  static String get viewIdOfIdCardDetect => _viewIdOfIdCardDetect;
}
