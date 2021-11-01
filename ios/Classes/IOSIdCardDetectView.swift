//
//  IOSIdCardDetectView.swift
//  msb_ekyc_camera
//
//  Created by TuyenTopebox on 2020/9/19.
//

import Foundation
import Flutter
import eKYC


class IOSIdCardDetectView:NSObject,FlutterPlatformView{

    let idCardDetectView = KYCIdDetectionView()
    
    var methodChannel:FlutterMethodChannel?
    var eventSink: FlutterEventSink?
    var flutterResult:FlutterResult?
    var binaryMessenger:FlutterBinaryMessenger!
    var viewId:Int64!

    var onCapture: Bool = false
    var captureResult:FlutterResult?

    var cardFace = CardFace.front

    /*
     Constructor.
     */
    init(frame: CGRect, binaryMessenger: FlutterBinaryMessenger, viewId: Int64) {
        //Call parent init constructor.
        super.init()
        self.binaryMessenger = binaryMessenger
        self.viewId = viewId
        /*
         Method Channel
         */
        initMethodChannel()
        /*
         Id card detect
         */
        idCardDetectView.frame = frame
        idCardDetectView.cameraDelegate = self
    }
    
    func view() -> UIView {
        return idCardDetectView
    }
    
    func initMethodChannel(){
        /*
         MethodChannel.
         */
        methodChannel = FlutterMethodChannel.init(name: "id_card_detect_view_method_channel", binaryMessenger: binaryMessenger)
        methodChannel?.setMethodCallHandler { (call :FlutterMethodCall, result:@escaping FlutterResult)  in
            /*
             Save flutter result.
             */
            self.flutterResult = result;

            switch(call.method){
            case "initCamera":
                if let args = call.arguments as? Dictionary<String, Any>{
                    let arg = args["idCardFaceType"]
                    if arg != nil {
                        if arg as! String == "back_image" {
                            self.cardFace = CardFace.back
                        } else {
                            self.cardFace = CardFace.front
                        }
                    } else {
                        print ("Can't get list id card face type, use default front!")
                    }
                }
                self.initEventChannel()
                let stringValue = String(self.viewId)
                self.flutterResult?("\(stringValue)")
            break;
            case "startCamera":
                self.startCamera()
            break;
            case "stopCamera":
                self.stopCamera()
            break;
            case "resumeCameraPreview":
                self.resumeCameraPreview()
            break;
            case "stopCameraPreview":
                self.stopCameraPreview()
            break;
            case "openFlash":
                self.openFlash()
            break;
            case "closeFlash":
                self.closeFlash()
            break;
            case "toggleFlash":
                self.toggleFlash()
            break;
            case "captureImage":
                self.capture(result: result);
            break;
            default:
                self.flutterResult?("method:\(call.method) not implement")
            }
        }
    }

    func initEventChannel (){
        let eventChannel = FlutterEventChannel(name: "id_card_detect_view_event_channel_" + String(self.viewId),
        binaryMessenger: self.binaryMessenger)
        eventChannel.setStreamHandler(self)
    }

    func initSuccess (){
        sendEventToDart(eventType: "initSuccess", eventData: "")
    }

    func startCamera(){
        idCardDetectView.startPreview()
    }

    func stopCamera(){
        idCardDetectView.stopPreview()
    }

    func capture(result:@escaping FlutterResult) {
        print("IOSIdCardDetectView - capture - onCapture: " + String(onCapture));
        if (idCardDetectView != nil && !onCapture) {
            onCapture = true;
            captureResult = result;
            print("IOSIdCardDetectView - capture: call idCardDetectView.capture()");
            idCardDetectView.capturePhoto()
        }
    }

    func resumeCameraPreview(){

    }

    func stopCameraPreview(){

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
extension IOSIdCardDetectView: FlutterStreamHandler {

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

// MARK: - KYCCameraDelegate
extension IOSIdCardDetectView: KYCCameraDelegate {
    func capturedId(_ image: UIImage) {
        KYCExtraction.extractCardDetails(cardFace, and: image, completionHandler: { (extractionResult) in
            print("Card Type: \(extractionResult.cardType)")
            print("Card Validity: \(extractionResult.cardValidity)")
            print("Result: \(extractionResult.result)")

            let currentMiliseconds:Int = MSBEkycUtils.currentTimeInMiliseconds()
            var filePath: URL!
            if let data = image.jpegData(compressionQuality: 0.8) {
                filePath = MSBEkycUtils.getDocumentsDirectory().appendingPathComponent("id_card_image_\(self.cardFace)_\(currentMiliseconds).jpeg")
                print("Begin save id image to path: \(filePath.path)")
                try? data.write(to: filePath)
            }

            if filePath == nil {
                print("Can't save face image file")
                return
            }

            let resultDict: [String: Any] = [
                "idcard_image" : "\(filePath.path)",
                //"extract_data" : extractionResult,
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

            self.captureResult!(successDataJsonString)
            self.captureResult = nil
        })
        onCapture = false
    }

    func capturedImage(_ image: UIImage) {
        // Do nothing
    }

}
