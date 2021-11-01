//
//  KYCVideoPreview.swift
//  eKYC
//
//  Created by Joy Sebastian on 27/04/20.
//  Copyright © 2020 techgentsia. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

public protocol KYCVideoDelegate {
    
    /**
     VideoRecording completed
     - Parameter location video file location url
     - Parameter userImage image of the user captured during detection
     - parameter params gesture detection times
     */
    func videoRecorded(atFile location: URL, With userImage: UIImage?, and params: [[String:Any]])
    
    /**
      Next gesture going to validate
     - Parameter gesture validating
     */
    func willValidate(gesture: Detection)
    
    /**
     Gesture did  validated
    - Parameter gesture validating, value will become '.Complete' if all gestures validated
    */
    func didValidate(gesture: Detection)
    
    
    /**
    Error occured
    */
    func didGet(_ error: DetectionError)

    
    /**
     Detect a face in camera
     */
    func faceSearchCompleted()
}

public class KYCVideoPreview: UIView {
    
    // Detection params
    fileprivate var currentDetection: Detection = .NotReady
    public var detections = detectionList
    fileprivate var index = 0
    
    fileprivate var rightAngle: CGFloat = 45.0
    fileprivate var leftAngle: CGFloat = 315.0
    
    fileprivate var cameraSession: AVCaptureSession!
    fileprivate lazy var videoDataOutput = AVCaptureVideoDataOutput()
    fileprivate lazy var audioDataOutput = AVCaptureAudioDataOutput()
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    //...
    fileprivate(set) lazy var isRecording = false
    fileprivate var videoWriter: AVAssetWriter!
    fileprivate var videoWriterInput: AVAssetWriterInput!
    fileprivate var audioWriterInput: AVAssetWriterInput!
    fileprivate var sessionAtSourceTime: CMTime?
    fileprivate var captureDeviceResolution: CGSize = CGSize()
    //...
    
    let imageOptions: [String: Any] = [CIDetectorSmile: true,
                                       CIDetectorEyeBlink: true,
                                       CIDetectorImageOrientation : 6]
    
    let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    var faceDetector: CIDetector!
    
    
    private var writeQueue = DispatchQueue(label: "videowrite.queue", attributes: .concurrent)
    fileprivate var movieTime = 0.0
    fileprivate var movieTimer: Timer?
    fileprivate var detectionTimer: Timer?
    fileprivate var outputFileLocation: URL?
    fileprivate var faceBoundBox = UIView()
    fileprivate var potraitImage: UIImage?
    fileprivate var captureImage = false
    
    public var enableFaceBounds = false
    public var videoDelegate: KYCVideoDelegate?
    public var detectionTime = 20.0
    private var detectFace = false
    
    var detectionParamsArray: [Dictionary<String,Any>] = []
    var currentDetectionParam = Dictionary<String,Any>()
    
    public var faceBox: CGRect!
    public var previewBgColor = UIColor.black
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureView()
    }
    
    
    func configureView() {
        if #available(iOS 13.0, *), AVCaptureMultiCamSession.isMultiCamSupported == true {
            (rightAngle, leftAngle) = (leftAngle, rightAngle)
        }
//        initCaptureSession()
        
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        
        faceBoundBox.layer.borderWidth = 2
        faceBoundBox.backgroundColor = UIColor.clear
        self.addSubview(faceBoundBox)
    }
    
    /**
     Start video preview
     */
    public func startPreview() {
//        designatePreviewLayer(for: cameraSession)
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            self.setupPreview()
        
        case .notDetermined: // The user has not yet been asked for camera access.
//            AVCaptureDevice.requestAccess(for: .video) { granted in
//                if granted {
//                    self.setupPreview()
//                }
//            }
            
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    //access allowed
                    self.setupPreview()
                } else {
                    //access denied
                    self.videoDelegate?.didGet(.permissonDenied)
                }
            })

        case .denied: // The user has previously denied access.
            videoDelegate?.didGet(.permissonDenied)
            return

        case .restricted: // The user can't grant access due to restrictions.
            videoDelegate?.didGet(.permissonDenied)
            return
        @unknown default:
            videoDelegate?.didGet(.permissonDenied)
            return
        }
        
    }
    
    private func setupPreview() {
        if cameraSession == nil {
            guard let session = initCaptureSession() else {
                return
            }
            cameraSession = session
        }
        
        self.bringSubviewToFront(faceBoundBox)
        cameraSession.startRunning()
    }
    
    /**
     Stop video preview
     */
    public func stopPreview() {
        if cameraSession != nil && cameraSession.isRunning {
            cameraSession.stopRunning()
//            teardownCapture()
        }
    }
    
    /**
     Starts gesture detection
     */
    public func startDetections() {
        startRecording()
        verifiedDetection()
    }
    
    /**
     Stops gesture detection and reset index
     */
    public func stopDetections() {
        stopRecording()
        index = 0
    }
    
    /**
     Reset detetection and start again
     */
    public func resetDetections() {
        cancelRecording()
        index = 0
        startDetections()
    }
    
    /**
     Delete recorded video from file location
     - Parameter location of the file
     */
    public func removeFile(at location: URL) {
        if FileManager.default.fileExists(atPath: location.path) {
            try? FileManager.default.removeItem(at: location)
            print("file removed")
        }
    }
    
    /**
     Detect for a face available in preview
     */
    public func searchFaceAvailable() {
        detectFace = true
    }

}

// MARK: AVCapture

extension KYCVideoPreview {
    
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
    
    fileprivate func initCaptureSession() -> AVCaptureSession? {
        
        let session = AVCaptureSession()
      //The size of output video will be 720x1280
        session.sessionPreset = AVCaptureSession.Preset.vga640x480 //hd1280x720
      
      //Setup your camera
      //Detect which type of camera should be used via `isUsingFrontFacingCamera`
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        if let captureDevice = deviceDiscoverySession.devices.first,
            let audioDevice = AVCaptureDevice.default(for: .audio){
            
            do {
                session.beginConfiguration()
              
                // Add camera to your session
                let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
                if session.canAddInput(deviceInput) {
                    session.addInput(deviceInput)
                }
            
                // Add microphone to session
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
                
                // Get Camera resolution
                let formatDescription = captureDevice.activeFormat.formatDescription
                let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                captureDeviceResolution = CGSize(width: CGFloat(dimensions.height), height: CGFloat(dimensions.width))
                
                
                // Define output data
                let queue = DispatchQueue(label: "com.techgentsia.ekyc.queue.record-video.data-output")
                
                // Define video output
                videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                ]
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                if session.canAddOutput(videoDataOutput) {
                    videoDataOutput.setSampleBufferDelegate(self, queue: queue)
                    session.addOutput(videoDataOutput)
                }
                
                //Define audio output
                if session.canAddOutput(audioDataOutput) {
                    audioDataOutput.setSampleBufferDelegate(self, queue: queue)
                    session.addOutput(audioDataOutput)
                }
                
                session.commitConfiguration()
                
                // Setup metadata object
                let metadataOutput = AVCaptureMetadataOutput()
                let metaQueue = DispatchQueue(label: "MetaDataSession")
                metadataOutput.setMetadataObjectsDelegate(self, queue: metaQueue)
                if session.canAddOutput(metadataOutput) {
                    session.addOutput(metadataOutput)
                } else {
                    print("Meta data output can not be added.")
                }
                   
                if !metadataOutput.metadataObjectTypes.contains(.face) {
                    metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
                }
                
                
                
                //Present the preview of video
                designatePreviewLayer(for: session)
                 
//                cameraSession.startRunning()
                
                return session
            }
            catch let error {
                videoDelegate?.didGet(.sessonFailure)
                debugPrint(error.localizedDescription)
                
                return nil
            }
            
        }
        return nil
    }
    
    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer
        
        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = previewBgColor.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            
        self.layer.masksToBounds = true
        videoPreviewLayer.frame = self.layer.bounds
        self.layer.addSublayer(videoPreviewLayer)
        
//        let w: CGFloat = self.bounds.width + 50
//        let h: CGFloat = self.bounds.width + 100
        
//        faceBox = CGRect(x: self.center.x - (w/2) , y: self.center.y - (h/2), width: w, height: h)
        
//        let v = UIView(frame: faceBox)
//        v.backgroundColor = UIColor.green
//        v.center = self.center
//        self.addSubview(v)

    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownCapture() {
      
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
}

// MARK: - Video Recording

extension KYCVideoPreview: AVCaptureVideoDataOutputSampleBufferDelegate,
                      AVCaptureAudioDataOutputSampleBufferDelegate {
  //There is only one same method for both of these delegates
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//        // Gesture detection
//
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
//        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//
//        let context = CIContext()
//        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
        
        
//        detectImage(cgImage)
        
        // Gesture detection
        
//        DispatchQueue.main.async {
        if currentDetection != .HeadLeft || currentDetection != .HeadRight {
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent){
                    self.detectImage(cgImage)
                }
            }
        }
            
//        }
        
        // Video recording options
        writeQueue.sync(flags: .barrier, execute: {
            let writable = canWrite()
            
            if writable,
                 sessionAtSourceTime == nil {
                //Start writing
                sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
              }

            if output == videoDataOutput {
                
                connection.videoOrientation = .portrait

                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
                
                if writable,
                    videoWriterInput.isReadyForMoreMediaData {
                    //Write video buffer
                    videoWriterInput.append(sampleBuffer)
                }
            } else if writable,
                output == audioDataOutput,
                audioWriterInput.isReadyForMoreMediaData {
                //Write audio buffer
                audioWriterInput.append(sampleBuffer)
            }
        })
        
    }
    
    //video file location method
    fileprivate func videoFileLocation() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("videoFile")).appendingPathExtension("mp4")
        do {
        if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
            try FileManager.default.removeItem(at: videoOutputUrl)
            print("file removed")
        }
        } catch {
            print(error)
        }

        return videoOutputUrl
    }
    
    
    fileprivate func setupWriter() {
        do {
            outputFileLocation = videoFileLocation()
            videoWriter = try AVAssetWriter(url: outputFileLocation!, fileType: AVFileType.mp4)
          
            //Add video input
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video,
                                                  outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264,
                                                                   AVVideoWidthKey: captureDeviceResolution.width,
                                                                   AVVideoHeightKey: captureDeviceResolution.height,
                                                                   AVVideoCompressionPropertiesKey: [
                                                                    AVVideoAverageBitRateKey: 2300000,],])
            
            videoWriterInput.expectsMediaDataInRealTime = true // Exporting data at realtime
            
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
            }
          
            //Add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio,
                                                  outputSettings: [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                                                   AVNumberOfChannelsKey: 1,
                                                                   AVSampleRateKey: 44100,
                                                                   AVEncoderBitRateKey: 64000,])
            
            audioWriterInput.expectsMediaDataInRealTime = true // Exporting data at realtime
            
            if videoWriter.canAdd(audioWriterInput) {
                videoWriter.add(audioWriterInput)
            }
          
            videoWriter.startWriting() // Ready to write down the file
        }
        catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    fileprivate func canWrite() -> Bool {
        return isRecording
            && videoWriter != nil
            && videoWriter.status == .writing
    }
    
    
    fileprivate func startRecording() {
        startMovieTimer()
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        setupWriter()
        print("Recording")
    }
    
    fileprivate func stopRecording() {
        print("Stop Recording")
        stopMovieTimer()
        guard isRecording else { return }
        isRecording = false
        videoWriter.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
            guard let url = self?.videoWriter.outputURL else { return }
            print("Deligate call")
            self!.videoDelegate?.videoRecorded(atFile: url, With: self?.potraitImage, and: self!.detectionParamsArray)
        }
    }
    
    fileprivate func cancelRecording() {
        print("Recording cancelled")
        stopMovieTimer()
        guard isRecording else { return }
        isRecording = false
        videoWriter.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
        }
    }
}

// MARK: - AVCaptureMetadataOutput

extension KYCVideoPreview: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        DispatchQueue.main.async {
            self.faceBoundBox.layer.borderColor = UIColor.clear.cgColor
        }
        
        for metadataObject in metadataObjects as! [AVMetadataFaceObject] {
            

            // Right & Left head movement identification
            if metadataObject.hasYawAngle {

                if metadataObject.yawAngle == self.rightAngle && self.currentDetection == .HeadRight {
                    print("Look right")
                    self.verifiedDetection()
                }
                else if metadataObject.yawAngle == self.leftAngle && self.currentDetection == .HeadLeft{
                    print("Look left")
                    self.verifiedDetection()
                }
                else if metadataObject.yawAngle == 0.0 && self.currentDetection == .Portrait{
                    print("Look direct")
                    captureImage = true
//                    self.verifiedDetection()
                }
                else {
                    captureImage = false
                }
            }
            
            // Bounding box over face
            if (metadataObject as AnyObject).type == AVMetadataObject.ObjectType.face && enableFaceBounds {
                
                guard let meta = previewLayer?.transformedMetadataObject(for: metadataObject) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.faceBoundBox.frame = meta.bounds //facePreviewBounds
                    self.faceBoundBox.layer.borderColor = UIColor.white.cgColor
                    self.bringSubviewToFront(self.faceBoundBox)
                }
            }
        }
    }
    
    fileprivate func detectImage(_ buffImage: CGImage) {

//        let imageOptions: [String: Any] = [CIDetectorSmile: true,
//                                           CIDetectorEyeBlink: true,
//                                           CIDetectorImageOrientation : 6]
        
        let personciImage = CIImage(cgImage: buffImage)
        
//        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
//        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage, options: imageOptions)
        
        if faces!.count > 1 &&
            currentDetection != .NotReady &&
            currentDetection != .Complete { // Multiple faces
            index = 0
            currentDetection = .NotReady
            invalidateDetectionTimer()
            cancelRecording()
            videoDelegate?.didGet(.multipleFaces)
        }
        
        if let face = faces?.first as? CIFaceFeature {
            
            // Search for a face
            if detectFace {
                detectFace = false
                videoDelegate?.faceSearchCompleted()
            }

            // Blink identification
            if face.leftEyeClosed && face.rightEyeClosed && self.currentDetection == .Blink{
                print("Blinking");
                self.verifiedDetection()
            }
            
            // Smile identification
            else if face.hasSmile && self.currentDetection == .Smile{
                print("face is smiling");
                let personcImage = UIImage(cgImage: buffImage)
                potraitImage = personcImage
                self.verifiedDetection()
            }
            else if captureImage && (!face.leftEyeClosed && !face.rightEyeClosed){
                captureImage = false
                potraitImage = UIImage(cgImage: buffImage)
                self.verifiedDetection()
            }
            
        } else { // Lost face from feed
            
            if currentDetection != .NotReady &&
            currentDetection != .Complete{
                index = 0
                currentDetection = .NotReady
                invalidateDetectionTimer()
//                stopRecording()
                cancelRecording()
                videoDelegate?.didGet(.lostFaceTrack)
//                videoDelegate?.lostFaceTrack()
            }
            
        }
    }
}

extension KYCVideoPreview {
    
    fileprivate func verifiedDetection() {
        
//        if sessionAtSourceTime != nil {
//            print("Source time:: \(CMTimeGetSeconds(sessionAtSourceTime!))")
//        }
        
        if index == 0 {  // Detection started
            detectionParamsArray.removeAll()
            currentDetection = detections.first!
            videoDelegate?.willValidate(gesture: currentDetection)
            startDetectionTimer()
            index = index + 1
            currentDetectionParam.updateValue(currentDetection.rawValue, forKey: "name")
            currentDetectionParam.updateValue(movieTime, forKey: "start_time")
            return
        }
        currentDetectionParam.updateValue(movieTime, forKey: "end_time")
        videoDelegate?.didValidate(gesture: currentDetection)
        if index < detections.count {
            videoDelegate?.willValidate(gesture: detections[index])
            startDetectionTimer()
            detectionParamsArray.append(currentDetectionParam)
            
            if detections[index] == .Portrait {
                currentDetection = .Waiting
                // wait for some time
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.currentDetection = .Portrait
                    self.currentDetectionParam.updateValue(self.currentDetection.rawValue, forKey: "name")
                }
            }
            else {
                currentDetection = detections[index]
                currentDetectionParam.updateValue(movieTime, forKey: "start_time")
                currentDetectionParam.updateValue(currentDetection.rawValue, forKey: "name")
            }
            index = index + 1
        }
        else {
            invalidateDetectionTimer()
            detectionParamsArray.append(currentDetectionParam)
            currentDetection = .NotReady
            index = 0
            print("Verification Complete")
            
            // wait for some time
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.stopRecording()
            }
            
            videoDelegate?.willValidate(gesture: .Complete)
        }
        
    }
    
    fileprivate func startDetectionTimer() {
        invalidateDetectionTimer()
        DispatchQueue.main.async {
            self.detectionTimer = Timer.scheduledTimer(timeInterval: self.detectionTime, target: self, selector: #selector(self.timeout), userInfo: nil, repeats: false)
        }
    }
    
    fileprivate func invalidateDetectionTimer(){
        if (detectionTimer != nil) {
            detectionTimer?.invalidate()
        }
    }
    
    @objc fileprivate func timeout() {
//        stopDetections()
        print("Time Out")
        index = 0
        currentDetection = .NotReady
        cancelRecording()
        videoDelegate?.didGet(.timeout)
//        videoDelegate?.detectionTimeout(for: currentDetection)
//        index = 0
    }
    
    fileprivate func startMovieTimer(){
        movieTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (t) in
            self.movieTime = self.movieTime + 0.1
//            print("time : \(self.movieTime)")
        }
    }
    fileprivate func stopMovieTimer() {
        if movieTimer != nil {
            movieTimer?.invalidate()
            movieTime = 0.0
        }
    }
}
