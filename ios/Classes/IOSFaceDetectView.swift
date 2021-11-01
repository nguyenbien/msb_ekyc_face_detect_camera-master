//
//  IOSFaceDetectView.swift
//  msb_ekyc_camera
//
//  Created by TuyenTopebox on 2020/9/19.
//

import Foundation
import Flutter
import eKYC


class IOSFaceDetectView:NSObject, FlutterPlatformView{
    
    let faceDetectView = KYCVideoPreview()

    var methodChannel:FlutterMethodChannel?
    var eventSink: FlutterEventSink?
    var flutterResult:FlutterResult?
    var binaryMessenger:FlutterBinaryMessenger!
    var viewId:Int64!

    /*
     Constructor.
     */
    init(frame: CGRect, binaryMessenger: FlutterBinaryMessenger, viewId: Int64) {
        //Call parent init constructor.
        super.init();
        self.binaryMessenger = binaryMessenger;
        self.viewId = viewId;
        /*
         Method Channel
         */
        initMethodChannel();
        /*
         Face Detect
         */
        faceDetectView.frame = frame
        faceDetectView.videoDelegate = self
        faceDetectView.enableFaceBounds = true
        faceDetectView.previewBgColor = UIColor.black
        faceDetectView.detections = [.HeadRight, .HeadLeft, .Blink, .Smile]
    }
    
    func view() -> UIView {
        return faceDetectView;
    }
    
    func initMethodChannel(){
        /*
         MethodChannel.
         */
        methodChannel = FlutterMethodChannel.init(name: "face_detect_view_method_channel", binaryMessenger: binaryMessenger)
        methodChannel?.setMethodCallHandler { (call :FlutterMethodCall, result:@escaping FlutterResult)  in
            /*
             Save flutter result.
             */
            self.flutterResult = result;
            
            switch(call.method){
                case "initCamera":
                    if let args = call.arguments as? Dictionary<String, Any>{
                        let arg = args["expectedGestures"]
                        if arg != nil {
                            let listGesture = arg as? [Any];
                            if listGesture != nil {
                                self.setListGestures(gesturesListDict:listGesture!)
                            }
                        }
                    } else {
                        print ("Can't get list expectedGestures, use default!")
                    }

                    self.initEventChannel();
                    let stringValue = String(self.viewId);
                    self.flutterResult?("\(stringValue)");
                    break;
                case "startCamera":
                    self.startCamera();
                    break;
                case "stopCamera":
                    self.stopCamera();
                    break;
                case "resumeCameraPreview":
                    self.resumeCameraPreview();
                    break;
                case "stopCameraPreview":
                    self.stopCameraPreview();
                    break;
                case "openFlash":
                    self.openFlash();
                    break;
                case "closeFlash":
                    self.closeFlash();
                    break;
                case "toggleFlash":
                    self.toggleFlash();
                    break;
                default:
                    self.flutterResult?("method:\(call.method) not implement");
                }
        }
    }
    
    func initEventChannel (){
        let eventChannel = FlutterEventChannel(name: "face_detect_view_event_channel_" + String(self.viewId),
        binaryMessenger: self.binaryMessenger)
        eventChannel.setStreamHandler(self)
    }

    func setListGestures(gesturesListDict: [Any]) {
        faceDetectView.detections = []
        gesturesListDict.forEach { (arg) in
            let gesture = arg as? Dictionary<String, Any>
            let gestureName = gesture!["name"] as? String
            switch(gestureName){
                case "turn_left":
                    faceDetectView.detections.append(.HeadLeft)
                break;
                case "turn_right":
                    faceDetectView.detections.append(.HeadRight)
                break;
                case "smile":
                    faceDetectView.detections.append(.Smile)
                break;
                case "blink_eye":
                    faceDetectView.detections.append(.Blink)
                break;
                default:
                    print("Gesture not found for name: \(gestureName)")
                }
        }
    }

    func initSuccess (){
        var gesturesListDict: [Any] = []
        self.faceDetectView.detections.forEach { (arg) in
            let gestureDict: [String: Any] = [
                "name" : "\(arg.rawValue)",
                "startTime" : 0,//arg.startTime,
                "endTime" : 0,//arg.endTime,
                "status" : false,//arg.status,
                "time" : 0,//arg.time,
            ]
            gesturesListDict.append(gestureDict)
        }

        let gestureListJsonData: Data
        do {
            gestureListJsonData = try JSONSerialization.data(withJSONObject: gesturesListDict, options: .prettyPrinted)
        } catch {
            assertionFailure("Gesture list JSON data creation failed with error: \(error).")
            return
        }
        guard let gestureListJsonString = String.init(data: gestureListJsonData, encoding: String.Encoding.utf8) else {
            assertionFailure("Gesture list JSON string creation failed.")
            return
        }
        print("gestureListJsonString: \(gestureListJsonString)")

        sendEventToDart(eventType: "initSuccess", eventData: gestureListJsonString)
    }
    
    func startCamera(){
        faceDetectView.startPreview()
        faceDetectView.searchFaceAvailable()
    }

    func stopCamera(){
        faceDetectView.stopDetections();
    }

    func resumeCameraPreview(){

    }
    
    func stopCameraPreview(){
        faceDetectView.stopPreview();
    }

    func openFlash(){

    }

    func closeFlash(){

    }

    func toggleFlash(){

    }

    func sendEventToDart(eventType:String, eventData:String) {
        if (eventSink == nil) {
            print("Send event fail: eventType: " + eventType + " event channel not ready!");
            return;
        }

        let eventJsonObject: NSMutableDictionary = NSMutableDictionary()
        eventJsonObject.setValue(eventType, forKey: "eventType")
        if !eventData.isEmpty {
            eventJsonObject.setValue(eventData, forKey: "eventData")
        }

        // For debug only
        let eventJsonData: Data
        do {
            eventJsonData = try JSONSerialization.data(withJSONObject: eventJsonObject, options: .prettyPrinted)
        } catch {
            assertionFailure("Event JSON data creation failed with error: \(error).")
            return
        }
        guard let eventJsonString = String.init(data: eventJsonData, encoding: String.Encoding.utf8) else {
            assertionFailure("Event JSON string creation failed.")
            return
        }
        print("JSON string: \(eventJsonString)")
        /// End debug

        eventSink!(eventJsonObject);
    }
}

// MARK: - eventChannel handler
extension IOSFaceDetectView: FlutterStreamHandler {

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        initSuccess()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// MARK: - KYCVideoDelegate
extension IOSFaceDetectView: KYCVideoDelegate{

    func videoRecorded(atFile location: URL, With userImage: UIImage?, and params: [[String : Any]]) {
        print("File location: " + location.absoluteString)
        faceDetectView.stopPreview()
        let currentMiliseconds:Int = MSBEkycUtils.currentTimeInMiliseconds()

        var filePath: URL!
        if let data = userImage?.jpegData(compressionQuality: 0.8) {
            filePath = MSBEkycUtils.getDocumentsDirectory().appendingPathComponent("faceImage_\(currentMiliseconds).jpeg")
            print("Begin save face_image to path: \(filePath.path)")
            try? data.write(to: filePath)
        }

        if filePath == nil {
            print("Can't save face image file")
            return
        }

        let resultDict: [String: Any] = [
                                "image_file" : "\(filePath.path)",
                                "video_file" : "\(location.path)",
                                ]

        let successDataJsonData: Data
        do {
            successDataJsonData = try JSONSerialization.data(withJSONObject: resultDict, options: .prettyPrinted)
        } catch {
            assertionFailure("successData JSON data creation failed with error: \(error).")
            return
        }
        guard let successDataJsonString = String.init(data: successDataJsonData, encoding: String.Encoding.utf8) else {
            assertionFailure("successData JSON string creation failed.")
            return
        }
        print("successDataJsonString: \(successDataJsonString)")
        sendEventToDart(eventType: "face_detect_success", eventData: successDataJsonString)
    }

    func willValidate(gesture: Detection) {
        print("Will validate: \(gesture.rawValue)")
    }

    func didValidate(gesture: Detection) {
        print("Did validate: \(gesture.rawValue)")
        let gestureDict: [String: Any] = [
                        "name" : "\(gesture.rawValue)",
                        "startTime" : 0,//arg.startTime,
                        "endTime" : 0,//arg.endTime,
                        "status" : true,//arg.status,
                        "time" : 0,//arg.time,
                    ]
        let gestureJsonData: Data
        do {
            gestureJsonData = try JSONSerialization.data(withJSONObject: gestureDict, options: .prettyPrinted)
        } catch {
            assertionFailure("Gesture JSON data creation failed with error: \(error).")
            return
        }
        guard let gestureJsonString = String.init(data: gestureJsonData, encoding: String.Encoding.utf8) else {
            assertionFailure("Gesture JSON string creation failed.")
            return
        }
        print("gestureJsonString: \(gestureJsonString)")
        sendEventToDart(eventType: "face_detect_event", eventData: gestureJsonString);
    }

    func didGet(_ error: DetectionError) {
        var errorStr: String = "Unknown"
        switch error {
        case .permissonDenied:
            errorStr = "permissonDenied"
        case .sessonFailure:
            errorStr = "sessonFailure"
        case .lostFaceTrack:
            errorStr = "lostFaceTrack"
        case .multipleFaces:
            errorStr = "multipleFaces"
        case .timeout:
            errorStr = "timeout"
        }
        sendEventToDart(eventType: "face_detect_event_failed", eventData: errorStr);
    }

    func faceSearchCompleted() {
        // Starts gesture detection
        faceDetectView.startDetections()
    }
}
