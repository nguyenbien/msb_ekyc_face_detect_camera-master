# msb_ekyc_face_detect_camera
## LICENSE
    BSD 3-Clause License
    
    Copyright (c) 2020, topebox
    All rights reserved.
	
Step 1: Add dependence to flutter pubspec.yaml:   
	...
	msb_ekyc_face_detect_camera:
		path: ./msb_ekyc_face_detect_camera
	...
Step 2: Import package: import 'package:msb_ekyc_face_detect_camera/msb_ekyc_face_detect_camera.dart';

Step 3: Declare controller: FaceDetectController _faceDetectController;

Step 4: Init camera with gesture detect received from server + listening events
          Future<void> _initializeCamera() async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String gesturesJsonString = await prefs.getString('gestures');
            List <dynamic> expectedGestures;
            if (gesturesJsonString != null && gesturesJsonString.isNotEmpty) {
              debugPrint('gesturesJsonString : ' + gesturesJsonString);
              expectedGestures = jsonDecode(gesturesJsonString);
            }
            _faceDetectController = FaceDetectController(context, expectedGestures: expectedGestures);
            _faceDetectController.addListener(() {
              if (_faceDetectController.value.hasError) {
                debugPrint('Camera error ${_faceDetectController.value.errorDescription}');
              }
              if (_faceDetectController.value.currentGestureIndex != -1 &&
                  _faceDetectController.value.currentGestureIndex != currentSelectedEmotionIcon) {
                _onSelectEmotionIconChanged (_faceDetectController.value.currentGestureIndex);
                debugPrint('Ekyc detect face index changed: index = $currentSelectedEmotionIcon');
              }
              if ((_currentListEmotion == null || _currentListEmotion.length <= 0) &&
                  _faceDetectController.value.gestures != null &&
                  _faceDetectController.value.gestures.length > 0) {
                setState(() {
                  _currentListEmotion = EmotionData.mapListEmotionData(_faceDetectController.value.gestures);
                });
              }
              if (!_onSendingData) {
                if (_faceDetectController.value.successDetectData.isNotEmpty) {
                  String imagePath = _faceDetectController.value
                      .successDetectData['image_file'];
                  String videoPath = _faceDetectController.value
                      .successDetectData['video_file'];
                  if (imagePath != null && imagePath.isNotEmpty &&
                      videoPath != null && videoPath.isNotEmpty) {
                    debugPrint(
                        "facedetect success: imagePath = $imagePath; videoPath = $videoPath");
                    if (accountInfo == null) {
                      accountInfo = new OnboardingAccountInfo();
                    }

                    accountInfo.faceImagePathOne = imagePath;
                    accountInfo.faceImagePathTwo = videoPath;
                    ///////
                    onFaceDetectSuccess();
                  }
                  else {
                    faceDetectFailed();
                  }
                  _faceDetectController.value =
                      _faceDetectController.value.copyWith(successDetectData: {});
                }
              }
            });
          }

Step 5:  Using widget FaceDetectWidget with controller to draw to screen
        ...
        FaceDetectWidget(faceDetectController: _faceDetectController)
        ...

*** NOTE: + Need CAMERA_PERMISSION + AUDIO_PERMISSION granted before calling FaceDetectWidget

