package com.lib.ekyc.core.ekyc;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.os.Handler;
import android.os.Looper;
import android.preference.PreferenceManager;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.tasks.Task;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.face.Face;
import com.google.mlkit.vision.face.FaceDetection;
import com.google.mlkit.vision.face.FaceDetector;
import com.google.mlkit.vision.face.FaceDetectorOptions;
import com.lib.ekyc.core.record.EKYCLogger;
import com.lib.ekyc.core.record.SaveImageUtil;
import com.lib.ekyc.core.utils.Constants;
import com.lib.ekyc.entity.DetectionParams;
import com.lib.ekyc.entity.Gesture;
import com.lib.ekyc.entity.GestureData;
import com.lib.ekyc.events.OnEKYCEvernts;
import com.lib.ekyc.misc.DetectionEvent;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

class FaceDetectionProcessor extends VisionProcessorBase<List<Face>> implements OnRecorderEvents {
   private static final String TAG = "FaceDetectionProcessor";
   private final FaceDetector detector;
   private DetectionParams detectionParams = null;
   private OnEKYCEvernts onEKYCEvernts = null;
   private Activity activity = null;
   private GestureData gestureData = null;
   private List<Gesture> gesturesMetaData = new ArrayList();
   private CameraSource cameraSource = null;
   private boolean eyeBlinkDetectionSuccess = false;
   private boolean smileDetectionSuccess = false;
   private boolean leftTurnDetectionSuccess = false;
   private boolean rightTurnDetectionSuccess = false;
   boolean gestreDetectionStatus = false;
   private String smileImagePath = "";
   private boolean isStarted = false;
   private String detectionType;

   public FaceDetectionProcessor(Activity activity, DetectionParams detectionParams, OnEKYCEvernts onEKYCEvernts) {
      FaceDetectorOptions options = new FaceDetectorOptions.Builder()
              .setLandmarkMode(1)
              .setClassificationMode(2).build();
      this.detectionParams = detectionParams;
      this.cameraSource = detectionParams.getCameraSource();
      this.onEKYCEvernts = onEKYCEvernts;
      this.activity = activity;
      this.detector = FaceDetection.getClient(options);
      this.gestureData = new GestureData();
      this.gestureData.setMeta_data(this.gesturesMetaData);
   }

   public void stop() {
      this.detector.close();
   }

   @Override
   protected Task<List<Face>> detectInImage(InputImage image) {
      return detector.process(image);
   }

   protected void onSuccess(@Nullable Bitmap originalCameraImage, @NonNull List<Face> faces, @NonNull FrameMetadata frameMetadata, @NonNull GraphicOverlay graphicOverlay) {
      if (this.gestreDetectionStatus) {
         EKYCLogger.print("FaceDetectionProcessor", "facedetection success");
      } else {
         Iterator var5 = faces.iterator();

         while(var5.hasNext()) {
            Face face = (Face)var5.next();
            EKYCLogger.print("FaceDetectionProcessor", "Face angle side wise" + face.getHeadEulerAngleY());
         }

         EKYCLogger.print("FaceDetectionProcessor", "\n\n");
         if (faces.size() != 0) {
            this.isStarted = true;
         }

         String var7 = this.detectionType;
         byte var8 = -1;
         switch(var7.hashCode()) {
         case -124477815:
            if (var7.equals("turn_left")) {
               var8 = 2;
            }
            break;
         case 109556488:
            if (var7.equals("smile")) {
               var8 = 0;
            }
            break;
         case 157637326:
            if (var7.equals("blink_eye")) {
               var8 = 1;
            }
            break;
         case 441816026:
            if (var7.equals("turn_right")) {
               var8 = 3;
            }
         }

         switch(var8) {
         case 0:
            EKYCLogger.print("FaceDetectionProcessor", "detecting SMILE ...");
            if (!this.smileDetectionSuccess) {
               this.smileDetectionSuccess = this.detectSmile(originalCameraImage, faces);
            }
            break;
         case 1:
            EKYCLogger.print("FaceDetectionProcessor", "detecting BLINK_EYE ...");
            if (!this.eyeBlinkDetectionSuccess) {
               this.eyeBlinkDetectionSuccess = this.detectBlinkEye(faces);
            }
            break;
         case 2:
            EKYCLogger.print("FaceDetectionProcessor", "detecting TURN_LEFT ...");
            if (!this.leftTurnDetectionSuccess) {
               this.leftTurnDetectionSuccess = this.detectFaceTurn(this.detectionType, faces);
            }
            break;
         case 3:
            EKYCLogger.print("FaceDetectionProcessor", "detecting TURN_RIGHT ...");
            if (!this.rightTurnDetectionSuccess) {
               this.rightTurnDetectionSuccess = this.detectFaceTurn(this.detectionType, faces);
            }
         }

         graphicOverlay.postInvalidate();
      }
   }

   private boolean detectFaceTurn(String type, List<Face> faces) {
      boolean success = false;
      if (faces.size() > 1) {
         return this.handleMultipleFaces();
      } else if (faces.size() == 0 && this.isStarted) {
         return this.handleNoFace();
      } else {
         Iterator var4 = faces.iterator();

         while(true) {
            while(var4.hasNext()) {
               Face face = (Face)var4.next();
               float turnAngle = face.getHeadEulerAngleY();
               float probConstant = (float)this.detectionParams.getGestureConstants().getMinAngle();
               if (type.equals("turn_right")) {
                  probConstant *= -1.0F;
               }

               if (type.equals("turn_right") && turnAngle <= probConstant) {
                  success = true;
                  this.activity.runOnUiThread(() -> {
                     String gestureString = this.createGestureMetaData();
                     EKYCLogger.print("FaceDetectionProcessor", type + " detection sccessful ,sending event success adata " + gestureString);
                  });
               } else if (type.equals("turn_left") && turnAngle >= probConstant) {
                  success = true;
                  this.activity.runOnUiThread(() -> {
                     String gestureString = this.createGestureMetaData();
                     EKYCLogger.print("FaceDetectionProcessor", type + " detection sccessful ,sending event success adata " + gestureString);
                  });
               }
            }

            return success;
         }
      }
   }

   private boolean detectSmile(Bitmap originalCameraImage, List<Face> faces) {
      if (faces.size() > 1) {
         return this.handleMultipleFaces();
      } else if (faces.size() == 0 && this.isStarted) {
         return this.handleNoFace();
      } else {
         Iterator var3 = faces.iterator();

         while(var3.hasNext()) {
            Face face = (Face)var3.next();
            float smilingProbability = face.getSmilingProbability();
            float probConstant = this.detectionParams.getGestureConstants().getMouthOpenProbability();
            if (smilingProbability >= probConstant && this.checkFaceisStraight(face)) {
               this.smileDetectionSuccess = true;
               this.activity.runOnUiThread(() -> {
                  File file = SaveImageUtil.saveBitmap(this.activity, originalCameraImage);
                  String gestureString;
                  if (file != null) {
                     gestureString = file.getAbsolutePath();
                     this.setSmileImagePath(gestureString);
                     this.gestureData.setImage_file(gestureString);
                  }

                  gestureString = this.createGestureMetaData();
                  EKYCLogger.print("FaceDetectionProcessor", "Smile detection sccessful ,sending event success adata " + gestureString);
               });
            }
         }

         return this.smileDetectionSuccess;
      }
   }

   private String createGestureMetaData() {
      int lastIndex = this.gesturesMetaData.size() - 1;
      ((Gesture)this.gesturesMetaData.get(lastIndex)).setStatus(this.eyeBlinkDetectionSuccess);
      ((Gesture)this.gesturesMetaData.get(lastIndex)).setEnd_time(System.currentTimeMillis());
      Gesture gesture = (Gesture)this.gesturesMetaData.get(lastIndex);
      String gestureString = Constants.GSON.toJson(gesture);
      int remainingGestures = this.detectionParams.getGestureList().size();
      if (remainingGestures > 0) {
         this.onEKYCEvernts.detectionEvents(DetectionEvent.SUCCESS, gestureString);
      } else {
         if (this.cameraSource != null) {
            this.cameraSource.stop();
            this.cameraSource.release();
         }

         this.gestreDetectionStatus = this.leftTurnDetectionSuccess && this.rightTurnDetectionSuccess && this.smileDetectionSuccess && this.eyeBlinkDetectionSuccess;
         this.onEKYCEvernts.detectionEvents(DetectionEvent.SUCCESS, gestureString);
         this.gestureData.setVideo_file(this.cameraSource.getVideoFilePath());
      }

      return gestureString;
   }

   private boolean detectBlinkEye(List<Face> faces) {
      if (faces.size() > 1) {
         return this.handleMultipleFaces();
      } else if (faces.size() == 0 && this.isStarted) {
         return this.handleNoFace();
      } else {
         Iterator var2 = faces.iterator();

         while(var2.hasNext()) {
            Face face = (Face)var2.next();
            float leftEye = face.getLeftEyeOpenProbability();
            float rightEye = face.getRightEyeOpenProbability();
            float probConstant = this.detectionParams.getGestureConstants().getEyeOpenProbability();
            if (leftEye <= probConstant && rightEye <= probConstant) {
               EKYCLogger.print("FaceDetectionProcessor", "Eye detection sccessful ,sending event success");
               this.eyeBlinkDetectionSuccess = true;
               this.activity.runOnUiThread(() -> {
                  String gestureString = this.createGestureMetaData();
                  EKYCLogger.print("FaceDetectionProcessor", "Eye detection sccessful ,sending event success adata " + gestureString);
               });
            }
         }

         return this.eyeBlinkDetectionSuccess;
      }
   }

   protected void onFailure(@NonNull Exception e) {
      Log.e("FaceDetectionProcessor", "Face detection failed " + e);
   }

   public synchronized void setDetectionType(String detectionType) {
      Gesture gesture = new Gesture();
      gesture.setName(detectionType);
      this.detectionType = detectionType;
      gesture.setStart_time(System.currentTimeMillis());
      gesture.setStatus(false);
      this.gesturesMetaData.add(gesture);
      EKYCLogger.print("FaceDetectionProcessor", "Started detection '" + detectionType + "'");
   }

   public void onRecorderCleanerd() {
      Handler handler = new Handler(Looper.getMainLooper());
      handler.post(() -> {
         String gestureMetaData = Constants.GSON.toJson(this.gestureData);
         this.onEKYCEvernts.onGestreDetectinCompleted(this.gestreDetectionStatus, gestureMetaData);
      });
   }

   private boolean handleMultipleFaces() {
      this.onEKYCEvernts.detectionEvents(DetectionEvent.FAILED, "multiple face found");
      return false;
   }

   private boolean handleNoFace() {
      this.onEKYCEvernts.detectionEvents(DetectionEvent.FAILED, "no face found");
      return false;
   }

   public boolean checkFaceisStraight(Face face) {
      boolean isFaceStraight = false;
      float y = face.getHeadEulerAngleY();
      if ((int)y <= 15 && (int)y >= 0) {
         isFaceStraight = true;
      }

      return isFaceStraight;
   }

   public String getSmileImagePath() {
      return this.smileImagePath;
   }

   public void setSmileImagePath(String smileImagePath) {
      this.smileImagePath = smileImagePath;
   }
}
