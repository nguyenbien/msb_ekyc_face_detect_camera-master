//
//  IOSIdCardDetectViewFactory.swift
//  ai_barcode
//
//  Created by TuyenTopebox on 2020/9/91.
//

import Foundation

class IOSIdCardDetectViewFactory:NSObject,FlutterPlatformViewFactory{
    
    var binaryMessenger:FlutterBinaryMessenger;
    
    init(flutterBinaryMessenger : FlutterBinaryMessenger) {
    
        binaryMessenger = flutterBinaryMessenger;
    
    }
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return IOSIdCardDetectView(frame: frame, binaryMessenger:binaryMessenger, viewId: viewId);
    }
}
