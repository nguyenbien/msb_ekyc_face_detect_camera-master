part of '../../msb_ekyc_face_detect_camera.dart';

///
/// FaceDetectWidget
///
/// Supported android and ios platform face detect
// ignore: must_be_immutable
class FaceDetectWidget extends StatefulWidget {
  ///
  /// Controller.
  FaceDetectController _faceDetectController;

  ///
  /// UnsupportedDescription
  String _unsupportedDescription;

  ///
  /// Constructor.
  FaceDetectWidget({
    @required FaceDetectController faceDetectController,
    String unsupportedDescription,
  }) {
    _faceDetectController = faceDetectController;
    _unsupportedDescription = unsupportedDescription;
  }

  @override
  State<StatefulWidget> createState() {
    return _FaceDetectWidgetState();
  }
}

///
/// _FaceDetectWidgetState
class _FaceDetectWidgetState
    extends State<FaceDetectWidget> {

  @override
  void initState() {
    super.initState();
    //Create
    MSBEkycCameraFaceDetectPlatform.instance.addListener(_widgetCreatedListener);
    MSBEkycCameraFaceDetectPlatform.instance.unsupportedPlatformDescription =
        widget._unsupportedDescription;
  }

  ///
  /// CreatedListener.
  _widgetCreatedListener() {
    if (widget._faceDetectController != null) {
      if (widget._faceDetectController._faceDetectViewCreated != null) {
        widget._faceDetectController._faceDetectViewCreated();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    //Release
    MSBEkycCameraFaceDetectPlatform.instance.removeListener(_widgetCreatedListener);
    widget._faceDetectController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MSBEkycCameraFaceDetectPlatform.instance.buildFaceDetectView(context);
  }
}
