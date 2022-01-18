package com.lib.ekyc.core.ekyc;

import android.app.Activity;
import android.os.CountDownTimer;
import android.util.Log;
import com.lib.ekyc.core.record.EKYCLogger;
import com.lib.ekyc.entity.DetectionParams;
import com.lib.ekyc.entity.Gesture;
import com.lib.ekyc.events.OnEKYCEvernts;
import java.io.File;
import java.io.IOException;

public class EKYCManager implements EKYCInterface {
   private static final String TAG = "EKYCManager";
   private Activity activity = null;
   private CameraSource cameraSource = null;
   private FaceDetectionProcessor faceDetectionProcessor = null;
   private EKYCMAnagerHelper ekycmAnagerHelper = null;
   private OnEKYCEvernts onEKYCEvernts = null;

   public EKYCManager(Activity activity, OnEKYCEvernts onEKYCEvernts) {
      this.activity = activity;
      this.onEKYCEvernts = onEKYCEvernts;
   }

   public void startDetection(CameraSourcePreview preview, GraphicOverlay graphicOverlay, DetectionParams detectionParams) {
      if (preview == null) {
         throw new IllegalArgumentException("You should provide CameraSourcePreview");
      } else if (graphicOverlay == null) {
         throw new IllegalArgumentException("You should provide GraphicOverlay");
      } else {
         this.cameraSource = new CameraSource(this.activity, graphicOverlay);
         this.cameraSource.setFacing(1);
         detectionParams.setCameraSource(this.cameraSource);
         this.faceDetectionProcessor = new FaceDetectionProcessor(this.activity, detectionParams, this.onEKYCEvernts);
         this.cameraSource.setMachineLearningFrameProcessor(this.faceDetectionProcessor);
         this.cameraSource.setOnRecorderEvents(this.faceDetectionProcessor);
         this.startCameraSource(this.cameraSource, preview, graphicOverlay);
         this.ekycmAnagerHelper = new EKYCMAnagerHelper(this.activity, this.onEKYCEvernts);
         this.initDetection(detectionParams, this.faceDetectionProcessor);
      }
   }

   public CountDownTimer detectGesture(Gesture gesture) {
      return this.ekycmAnagerHelper != null ? this.ekycmAnagerHelper.detectGesture(gesture) : null;
   }

   public void onPause() {
   }

   public void onResume() {
   }

   public void onDestroy() {
   }

   public void stopDetection() {
      if (this.cameraSource != null) {
         try {
            this.cameraSource.stop();
            this.cameraSource.release();
            this.deleteFile(this.cameraSource.getVideoFilePath());
            this.deleteFile(this.faceDetectionProcessor.getSmileImagePath());
         } catch (Exception var2) {
            var2.printStackTrace();
         }
      }

   }

   public void deleteFile(String path) {
      File file = new File(path);
      file.delete();
      if (file.exists()) {
         try {
            file.getCanonicalFile().delete();
         } catch (IOException var4) {
            var4.printStackTrace();
            EKYCLogger.print("EKYCManager", "file deletion failed");
         }

         if (file.exists()) {
            this.activity.deleteFile(file.getName());
            EKYCLogger.print("EKYCManager", "file deleted ! " + path);
         }
      }

   }

   private void initDetection(DetectionParams detectionParams, FaceDetectionProcessor faceDetectionProcessor) {
      this.ekycmAnagerHelper.initDetection(detectionParams, faceDetectionProcessor);
   }

   private void startCameraSource(CameraSource cameraSource, CameraSourcePreview preview, GraphicOverlay graphicOverlay) {
      if (cameraSource != null) {
         try {
            preview.start(cameraSource, graphicOverlay);
         } catch (IOException var5) {
            Log.e("EKYCManager", "Unable to start camera source.", var5);
            cameraSource.release();
            cameraSource = null;
         }
      }

   }
}
