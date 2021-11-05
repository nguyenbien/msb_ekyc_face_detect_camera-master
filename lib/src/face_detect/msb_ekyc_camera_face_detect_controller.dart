part of '../../msb_ekyc_face_detect_camera.dart';

///
/// FaceDetectController
class FaceDetectController extends ValueNotifier<FaceDetectControllerValue> {
  ///
  /// Event
  Function(dynamic event) _faceDetectEventHandler;
  Function() _faceDetectViewCreated;

  BuildContext _context;
  StreamSubscription<dynamic> _eventSubscription;

  String _viewId;
  List<dynamic> _expectedGestures;

  ///
  /// Constructor.
  FaceDetectController(BuildContext context, {
    List<dynamic> expectedGestures,
    faceDetectEventHandler(dynamic event),
    faceDetectViewCreated(),
  }) : super(const FaceDetectControllerValue.uninitialized()) {
    _context = context;
    _expectedGestures = expectedGestures;
    _faceDetectEventHandler = faceDetectEventHandler??eventHandler;
    _faceDetectViewCreated = faceDetectViewCreated??viewCreated;
  }

  Function() get faceDetectViewCreated => _faceDetectViewCreated;

  bool get isStartCamera => MSBEkycCameraFaceDetectPlatform.instance.isStartCamera;
  bool get isStartCameraPreview =>
      MSBEkycCameraFaceDetectPlatform.instance.isStartCameraPreview;

  bool get isOpenFlash => MSBEkycCameraFaceDetectPlatform.instance.isOpenFlash;

  eventHandler (dynamic event) {
    final Map<dynamic, dynamic> map = event;
    print('face_detect_view_event_channel event receive: ' + event.toString());
    switch (map['eventType']) {
      case 'initSuccess':
        value = value.copyWith(
            isInitialized: true,
            gestures: map["eventData"] != null ?
            List<Gesture>.from(
                json.decode(map["eventData"]).map((x) =>
                    Gesture.fromJson(x))) : null,
            currentGestureIndex: map["eventData"] != null ? 0 : -1
        );
    TargetPlatform platform = Theme
            .of(_context)
            .platform;
        if (TargetPlatform.iOS == platform) {
          Future.delayed(Duration(seconds: 2), () {
            startCamera();
            startCameraPreview();
          });
        } else {
          Future.delayed(Duration(seconds: 1), () {
            startCamera();
            startCameraPreview();
          });
        }
        break;
      case 'face_detect_event':
        print('Dart Face Detect event recieved: ${event['eventData']}');
        Map <String, dynamic> eventData = json.decode(event['eventData']);
        /*if (eventData['status'] != null && eventData['status'])*/ {
          if (value.gestures != null && value.gestures.length > 0) {
            int length = value.gestures.length;
            for (int i = 0; i < length; i++) {
              if (value.gestures[i].name == eventData['name']) {
                value = value.copyWith(successDetectData: eventData, currentGestureIndex: i + 1);
                break;
              }
            }
          }
        } /*else {
          value = value.copyWith(currentGestureIndex: -1);
        }*/
        break;
      case 'face_detect_success':
        print('Dart face_detect_success event recieved: ${event['eventData']}');
        Map <String, dynamic> eventData = json.decode(event['eventData']);
        if (eventData != null) {
          value = value.copyWith(successDetectData: eventData);
        }
        break;
      case "face_detect_event_failed":
        print('Dart face_detect_event_failed event recieved: ${event['eventData']}');
        Map <String, dynamic> eventData = {'image_file': '', 'video_file': ''};

        value = value.copyWith(successDetectData: eventData, errorDescription: getErrorString(event['eventData']));
        break;
    }
  }

  getErrorString(String errorCode) {
    if (errorCode == null || errorCode == "") return null;
    String errorMsg = "Chưa nhận diện được khuôn mặt, vui lòng thử lại sau";
    switch (errorCode) {
      case "permissonDenied":
        errorMsg = "permissonDenied";
        break;
      case "sessonFailure":
        errorMsg = "Có lỗi khi nhận diện khuôn mặt, vui lòng thử lại";
        break;
      case "lostFaceTrack":
        errorMsg = "Vui lòng đưa khuôn mặt bạn vào khung hình";
        break;
      case "multipleFaces":
        errorMsg = "Vui lòng tránh xuất hiện nhiều khuôn mặt trong khung hình.";
        break;
      case "timeout":
        errorMsg =
        "Đã quá thời gian thực hiện thao tác. Vui lòng thực hiện lại.";
        break;
    }
    return errorMsg;
  }

  viewCreated () {
    print ('Dart FaceDetectController: View created!!!');
    initCamera();
  }

  dispose() {
    _eventSubscription.cancel();
    stopCamera();
    stopCameraPreview();
    super.dispose();
  }

  ///
  /// Init camera without open face detect.
  initCamera() async {
    _viewId = await MSBEkycCameraFaceDetectPlatform.instance.initCamera(
        expectedGestures: _expectedGestures);
    print('Dart Face Detect Controller InitCamera respsone: ${_viewId}');
    if (_viewId.isNotEmpty) {
      _eventSubscription =
          EventChannel('face_detect_view_event_channel_$_viewId')
              .receiveBroadcastStream()
              .listen(_faceDetectEventHandler);
    }
  }

  ///
  /// Start camera without open face detect,this is just open camera.
  startCamera() {
    MSBEkycCameraFaceDetectPlatform.instance.startCamera();
  }

  restartDetect () {
    value = value.copyWith(currentGestureIndex: 0, successDetectData: {});
    MSBEkycCameraFaceDetectPlatform.instance.startCamera();
  }

  ///
  /// Stop camera.
  stopCamera() async {
    MSBEkycCameraFaceDetectPlatform.instance.stopCamera();
  }

  ///
  /// Start camera preview with open Face detect,this is open code scanner.
  startCameraPreview() async {
    MSBEkycCameraFaceDetectPlatform.instance.startCameraPreview();
  }

  ///
  /// Stop camera preview.
  stopCameraPreview() async {
    MSBEkycCameraFaceDetectPlatform.instance.stopCameraPreview();
  }

  ///
  /// Open camera flash.
  openFlash() async {
    MSBEkycCameraFaceDetectPlatform.instance.openFlash();
  }

  ///
  /// Close camera flash.
  closeFlash() async {
    MSBEkycCameraFaceDetectPlatform.instance.closeFlash();
  }

  ///
  /// Toggle camera flash.
  toggleFlash() async {
    MSBEkycCameraFaceDetectPlatform.instance.toggleFlash();
  }
}

/// The state of a [FaceDetectController].
class FaceDetectControllerValue {
  const FaceDetectControllerValue({
    this.isInitialized,
    this.errorDescription,
    this.previewSize,
    this.gestures,
    this.currentGestureIndex,
    this.successDetectData
  });

  const FaceDetectControllerValue.uninitialized()
      : this(
    isInitialized: false,
    gestures: null,
    currentGestureIndex: -1,
    successDetectData: const {}
  );

  /// True after [FaceDetectController.initialize] has completed successfully.
  final bool isInitialized;

  final String errorDescription;

  /// The size of the preview in pixels.
  ///
  /// Is `null` until  [isInitialized] is `true`.
  final Size previewSize;

  /// Convenience getter for `previewSize.height / previewSize.width`.
  ///
  /// Can only be called when [initialize] is done.
  double get aspectRatio => previewSize.height / previewSize.width;

  bool get hasError => errorDescription != null;

  final List <Gesture> gestures;
  final int currentGestureIndex;

  final Map<String, dynamic> successDetectData;

  FaceDetectControllerValue copyWith({
    bool isInitialized,
    String errorDescription,
    Size previewSize,
    List <Gesture> gestures,
    int currentGestureIndex,
    Map<String, dynamic> successDetectData
  }) {
    return FaceDetectControllerValue(
        isInitialized: isInitialized ?? this.isInitialized,
        errorDescription: errorDescription,
        previewSize: previewSize ?? this.previewSize,
        gestures: gestures ?? this.gestures,
        currentGestureIndex: currentGestureIndex ?? this.currentGestureIndex,
        successDetectData:successDetectData ?? this.successDetectData
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription, '
        'previewSize: $previewSize, '
        'gestures: $gestures,'
        'currentGestureIndex: $currentGestureIndex,'
        'successDetectData: ${successDetectData.toString()})';
  }
}

class Gesture {
  Gesture({
    this.endTime,
    this.name,
    this.startTime,
    this.status,
    this.time,
  });

  int endTime;
  String name;
  int startTime;
  bool status;
  int time;

  Gesture copyWith({
    int endTime,
    String name,
    int startTime,
    bool status,
    int time,
  }) =>
      Gesture(
        endTime: endTime ?? this.endTime,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        status: status ?? this.status,
        time: time ?? this.time,
      );

  factory Gesture.fromRawJson(String str) => Gesture.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Gesture.fromJson(Map<String, dynamic> json) => Gesture(
    endTime: json["end_time"] == null ? null : json["end_time"],
    name: json["name"] == null ? null : json["name"],
    startTime: json["start_time"] == null ? null : json["start_time"],
    status: json["status"] == null ? null : json["status"],
    time: json["time"] == null ? null : json["time"],
  );

  Map<String, dynamic> toJson() => {
    "end_time": endTime == null ? null : endTime,
    "name": name == null ? null : name,
    "start_time": startTime == null ? null : startTime,
    "status": status == null ? null : status,
    "time": time == null ? null : time,
  };
}