//
//  IOSFaceDetectViewFactory.swift
//  msb_ekyc_camera
//
//  Created by TuyenTopebox on 2020/9/19.
//

import Foundation

class IOSFaceDetectViewFactory:NSObject,FlutterPlatformViewFactory{
    
    var binaryMessenger:FlutterBinaryMessenger;
    
    init(flutterBinaryMessenger : FlutterBinaryMessenger) {
    
        binaryMessenger = flutterBinaryMessenger;
    
    }
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return IOSFaceDetectView(frame: frame, binaryMessenger:binaryMessenger, viewId: viewId);
    }
}
