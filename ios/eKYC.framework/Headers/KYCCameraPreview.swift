//
//  KYCCameraPreview.swift
//  eKYC
//
//  Created by Joy Sebastian on 27/04/20.
//  Copyright © 2020 techgentsia. All rights reserved.
//

import UIKit
import AVFoundation

public protocol KYCCameraDelegate {
    
    /**
     Called after success fully captured a image
     - Parameter image is the captured image
     */
    func capturedImage(_ image: UIImage)
    
    /// Called after Id card captured and data extracted
    /// - Parameter result: extracted results with card
//    func cardCaptured(with result: ExtractionResult)
    
    /// Called after Id card captured
    /// - Parameter image: is the captured image
    func capturedId(_ image: UIImage)
}

public class KYCCameraPreview: UIView {

    // AVCapture variables
    fileprivate var session: AVCaptureSession?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    fileprivate var stillImageOutput: AVCapturePhotoOutput?
    fileprivate var captureDevice: AVCaptureDevice?
    fileprivate var captureDeviceResolution: CGSize = CGSize()
    
    fileprivate var stillImage: UIImage?
    
    public var cameraDelegate: KYCCameraDelegate?
    public var enableFlash = false
    
    /**
    Start camera preview
    */
    public func startPreview() {
        
        self.session = self.setupAVCaptureSession()
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
        
        guard (stillImageOutput != nil) else {
            return
        }
        let photoSettings: AVCapturePhotoSettings

        if (stillImageOutput?.availablePhotoCodecTypes.contains(.jpeg))! {
            photoSettings = AVCapturePhotoSettings(format:
               [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.isAutoStillImageStabilizationEnabled =
            stillImageOutput!.isStillImageStabilizationSupported
        if enableFlash {
            photoSettings.flashMode = .on
        }else {
            photoSettings.flashMode = .off
        }

        stillImageOutput!.capturePhoto(with: photoSettings, delegate: self)
    }
}

// MARK: AVCapture

extension KYCCameraPreview {
    
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
        
        captureSession.beginConfiguration()

        stillImageOutput = configureCapturePhotoOutput()
        stillImageOutput?.isHighResolutionCaptureEnabled = true
        stillImageOutput?.isLivePhotoCaptureEnabled = false

        guard captureSession.canAddOutput(stillImageOutput!) else { return nil}
        captureSession.sessionPreset = .photo
        captureSession.addOutput(stillImageOutput!)
        captureSession.commitConfiguration()
        
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
        
    fileprivate func configureCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
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
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        let previewRootLayer = self.layer
            
        previewRootLayer.masksToBounds = true
        videoPreviewLayer.frame = previewRootLayer.bounds
        previewRootLayer.addSublayer(videoPreviewLayer)
    
    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.stillImageOutput = nil
        
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
}

// MARK: AVCapturePhotoCaptureDelegate
extension KYCCameraPreview: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let data = photo.fileDataRepresentation(),
              let image =  UIImage(data: data) else {
                return
        }
        print("Image out")
        cameraDelegate?.capturedImage(image)

    }
    
}

