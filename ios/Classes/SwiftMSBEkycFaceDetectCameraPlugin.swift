import Flutter
import UIKit

public class SwiftMSBEkycFaceDetectCameraPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "msb_ekyc_face_detect_camera_method_channel", binaryMessenger: registrar.messenger())
    let instance = SwiftMSBEkycFaceDetectCameraPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)   

    registrar.register(IOSFaceDetectViewFactory(flutterBinaryMessenger: registrar.messenger()), withId: "face_detect_view")
    registrar.register(IOSIdCardDetectViewFactory(flutterBinaryMessenger: registrar.messenger()), withId: "id_card_detect_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
