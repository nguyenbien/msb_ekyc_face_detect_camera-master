//
//  KYCIdDetectionView.swift
//  eKYC Test
//
//  Created by Joy Sebastian on 25/06/20.
//  Copyright © 2020 techgentsia. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

public class KYCIdDetectionView: UIView {

    // AVCapture variables
    fileprivate var session: AVCaptureSession?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate let videoDataOutput = AVCaptureVideoDataOutput()
    fileprivate var captureDevice: AVCaptureDevice?
    fileprivate var captureDeviceResolution: CGSize = CGSize()
    
    fileprivate var maskLayer = CAShapeLayer()
    fileprivate var capture = false
    fileprivate var stillImage: UIImage?
    
    public var cameraDelegate: KYCCameraDelegate?
//    public var enableFlash = false
    
    fileprivate var cropSize: CGSize!
    fileprivate var cropRect: CGRect!
    fileprivate let idFillLayer = CAShapeLayer()
    
//    fileprivate var cardFace: CardFace!
//    fileprivate var cardType: CardType = .unknown
    /**
    Start camera preview
    */
    public func startPreview() {
        if session == nil {
            self.session = self.setupAVCaptureSession()
            setCameraOutput()
        }
        self.session?.startRunning()
    }
    
    /**
    Stop camera preview
    */
    public func stopPreview() {
        self.session?.stopRunning()
        self.teardownAVCapture()
    }
    
    /**
     Capture the current image from preview
     */
    public func capturePhoto() {
//        cardFace = face
        capture = true
    }
    
    public func flash(enable: Bool) {
        if session != nil && session!.isRunning {
            if (captureDevice!.hasTorch) {
                do {
                    try captureDevice!.lockForConfiguration()
                    if !enable {
                        captureDevice!.torchMode = AVCaptureDevice.TorchMode.off
                    } else {
                        do {
                            try captureDevice!.setTorchModeOn(level: 1.0)
                        } catch {
                            print(error)
                        }
                    }
                    captureDevice!.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
        
    }
    
}

// MARK: - AVCapture
extension KYCIdDetectionView {
    
    /**
     Request camera permisson
     - Parameter completionHandler return true if autherized else return false
     */
    public func requestCameraPermisson(_ completionHandler: @escaping (_ granted: Bool) -> Void) {
            
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            //already authorized
            completionHandler(true)
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    //access allowed
                    completionHandler(true)
                } else {
                    //access denied
                    completionHandler(false)
                }
            })
        }
    }
        
    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        do {
            let inputDevice = try self.configureCamera(for: captureSession)
            
            self.captureDevice = inputDevice.device
            self.captureDeviceResolution = inputDevice.resolution
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let executionError as NSError {
            print(executionError.localizedDescription)
        } catch {
//            self.presentErrorAlert(message: "An unexpected failure has occured")
        }
        
        self.teardownAVCapture()
        
        return nil
    }
    
    /// - Tag: ConfigureCapturePhotoOutput
    fileprivate func configureCapturePhotoOutput() -> AVCapturePhotoOutput {
        
        let photoOutput = AVCapturePhotoOutput()
        return photoOutput
    }
        
    /// - Tag: ConfigureCamera
    private func configureCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                let formatDescription = device.activeFormat.formatDescription
                let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                let resolution = CGSize(width: CGFloat(dimensions.height), height: CGFloat(dimensions.width))
                return (device, resolution)
            }
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer
        
        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        
        let previewRootLayer = self.layer
            
        previewRootLayer.masksToBounds = true
        videoPreviewLayer.frame = previewRootLayer.bounds
        previewRootLayer.addSublayer(videoPreviewLayer)
    
        addIdLayer()
    }
    
    /// - Tag: TeardownCapture
    fileprivate func teardownAVCapture() {
        session?.removeOutput(videoDataOutput)
        session = nil
        idFillLayer.removeFromSuperlayer()
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
    /// - Tag: SetCameraOutput
    private func setCameraOutput() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        
        session?.beginConfiguration()
        session?.addOutput(self.videoDataOutput)
        session?.commitConfiguration()
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
        
    }
    
}

// MARK: -AVCaptureVideoDataOutputSampleBufferDelegate
extension KYCIdDetectionView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            
//            guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//                debugPrint("unable to get image from sample buffer")
//                return
//            }
//
//            self.detectRectangle(in: frame)
        
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
//        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer, options: [kCGImagePropertyDPIWidth: 300,
                                                                    kCGImagePropertyDPIHeight: 300] as [CIImageOption : Any])
                
//                kCGImagePropertyTIFFXResolution: 300,
//                                                                    kCGImagePropertyTIFFYResolution: 300] as [CIImageOption : Any])
        
//        print(ciImage.)

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
        
//        print("Brightness :: \(cgImage.brightness)")
        
        let image = UIImage(cgImage: cgImage)
        
//        print("Brightness -> \(image.brightness)")

        cropId(image: image)
    }
    
//    private func detectRectangle(in image: CVPixelBuffer) {
//
//        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
//            DispatchQueue.main.async {
//
//                guard let results = request.results as? [VNRectangleObservation] else { return }
//
//                self.maskLayer.removeFromSuperlayer()
//
//                guard let rect = results.first else{ return }
//                    self.drawBoundingBox(rect: rect)
//
//                    if self.capture{
//                        self.capture = false
//                        self.doPerspectiveCorrection(rect, from: image)
//                    }
//            }
//        })
//
//        request.minimumAspectRatio = VNAspectRatio(1.3)
//        request.maximumAspectRatio = VNAspectRatio(1.6)
//        request.minimumSize = Float(0.5)
//        request.maximumObservations = 1
//
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
//        try? imageRequestHandler.perform([request])
//    }
    
//    func drawBoundingBox(rect : VNRectangleObservation) {
//
//        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewLayer!.frame.height)
//        let scale = CGAffineTransform.identity.scaledBy(x: self.previewLayer!.frame.width, y: self.previewLayer!.frame.height)
//
//        let bounds = rect.boundingBox.applying(scale).applying(transform)
//        createLayer(in: bounds)
//    }
    
//    private func createLayer(in rect: CGRect) {
//        maskLayer = CAShapeLayer()
//        maskLayer.frame = rect
//        maskLayer.cornerRadius = 10
//        maskLayer.opacity = 0.75
//        maskLayer.borderColor = UIColor.white.cgColor
//        maskLayer.borderWidth = 2.0
//
//        previewLayer?.insertSublayer(maskLayer, at: 1)
//    }
    
//    func doPerspectiveCorrection(_ observation: VNRectangleObservation, from buffer: CVImageBuffer) {
//
//            var ciImage = CIImage(cvImageBuffer: buffer)
//
//            let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
//            let topRight = observation.topRight.scaled(to: ciImage.extent.size)
//            let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
//            let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)
//
//            ciImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
//                "inputTopLeft": CIVector(cgPoint: topLeft),
//                "inputTopRight": CIVector(cgPoint: topRight),
//                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
//                "inputBottomRight": CIVector(cgPoint: bottomRight),
//            ])
//
//            let context = CIContext()
//            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
//            let output = UIImage(cgImage: cgImage!)
//
////            UIImageWriteToSavedPhotosAlbum(output, nil, nil, nil)
//        cameraDelegate?.capturedImage(output)
//    }
}

extension KYCIdDetectionView {
    func addIdLayer() {
        
        let width: CGFloat = self.bounds.width * (9/10)
        let height: CGFloat = width * (10/16)
                   
        cropSize = CGSize(width: width, height: height)
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height), cornerRadius: 0)
        let sqPath = UIBezierPath(roundedRect:  CGRect(x: (self.bounds.size.width - cropSize.width)/2, y: (self.bounds.size.height - cropSize.height)/2, width: cropSize.width, height: cropSize.height), cornerRadius: 10)
        
        /// save croping rectangle
        cropRect = CGRect(x: ((self.bounds.size.width - cropSize.width)/2) - 15, y: ((self.bounds.size.height - cropSize.height)/2) - 15, width: cropSize.width + 30, height: cropSize.height + 30)
        
        path.append(sqPath)
        path.usesEvenOddFillRule = true

        
        idFillLayer.path = path.cgPath
        idFillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        idFillLayer.fillColor = UIColor.black.cgColor
        idFillLayer.opacity = 0.5
        self.layer.addSublayer(idFillLayer)
    }
    
    func cropId(image: UIImage) {

        DispatchQueue.main.async {

            let imgHeight = image.size.height
            let imgWidth = image.size.width

            let previewHeight: CGFloat = (self.bounds.width * imgHeight)/imgWidth

            let yPadding = (self.bounds.height - previewHeight)/2

            let scale: CGFloat = imgWidth/self.bounds.width

            let icX: CGFloat = ((self.bounds.size.width - self.cropSize.width)/2) * scale

            let icY: CGFloat = (((self.bounds.size.height - self.cropSize.height)/2) - yPadding) * scale

            let cropRect = CGRect(x: icX, y: icY, width: self.cropSize.width * scale, height: self.cropSize.height * scale)

            let cardImage = image.cropImage(cropRect: cropRect)

            if self.capture {
                self.capture = false
//                switch self.cardFace {
//                case .front:
//                    TextExtraction.extractCardFront(from: cardImage, completionHandler: { (result) in
//                        self.cardType = result.cardType
//                        self.cameraDelegate?.cardCaptured(with: result)
//
//                    })
//                case .back:
//                    TextExtraction.extractCardBack(from: cardImage, and: self.cardType, completionHandler: { (result) in
//                        self.cameraDelegate?.cardCaptured(with: result)
//                    })
//                case .none:
//                    print("No card face selected")
//                }
                
                self.cameraDelegate?.capturedId(cardImage)
            }

        }

    }
}

// MARK: - CGPoint
extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: self.x * size.width,
                      y: self.y * size.height)
   }
}

// MARK: - UIImage
extension UIImage {
    func cropImage( cropRect: CGRect) -> UIImage {
        let cgImage = self.cgImage! // better to write "guard" in realm app
        let croppedCGImage = cgImage.cropping(to: cropRect)
        return UIImage(cgImage: croppedCGImage!)
    }
}


extension CGImage {
    var brightness: Double {
        get {
            let imageData = self.dataProvider?.data
            let ptr = CFDataGetBytePtr(imageData)
            var x = 0
            var result: Double = 0
            for _ in 0..<self.height {
                for _ in 0..<self.width {
                    let r = ptr![0]
                    let g = ptr![1]
                    let b = ptr![2]
                    result += (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                    x += 1
                }
            }
            let bright = result / Double (x)
            return bright
        }
    }
}
extension UIImage {
    var brightness: Double {
        get {
            return (self.cgImage?.brightness)!
        }
    }
}
