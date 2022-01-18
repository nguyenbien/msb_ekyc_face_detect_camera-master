package com.lib.ekyc.core.ekyc;

import android.app.Activity;
import android.os.CountDownTimer;
import com.lib.ekyc.core.record.EKYCLogger;
import com.lib.ekyc.core.utils.Constants;
import com.lib.ekyc.entity.DetectionParams;
import com.lib.ekyc.entity.Gesture;
import com.lib.ekyc.events.OnEKYCEvernts;
import com.lib.ekyc.misc.DetectionEvent;
import java.util.List;

class EKYCMAnagerHelper {
   private static final String TAG = "EKYCMAnagerHelper";
   private DetectionParams detectionParams = null;
   private FaceDetectionProcessor faceDetectionProcessor = null;
   private long detectionTime = 0L;
   private List<Gesture> gestures = null;
   private int currentGesturePos = 0;
   private OnEKYCEvernts onEKYCEvernts = null;
   private long DETECTION_TIME_INTERVAL = 30L;
   private Gesture currentGesture = null;
   private Activity activity;

   public EKYCMAnagerHelper(Activity activity, OnEKYCEvernts onEKYCEvernts) {
      this.activity = activity;
      this.onEKYCEvernts = onEKYCEvernts;
   }

   protected void initDetection(DetectionParams detectionParams, FaceDetectionProcessor faceDetectionProcessor) {
      this.detectionParams = detectionParams;
      this.faceDetectionProcessor = faceDetectionProcessor;
      this.gestures = detectionParams.getGestureList();
      int gestureCount = this.gestures.size();
      this.detectionTime = (long)gestureCount * detectionParams.getMinGestureDetectionTime();
      Gesture gesture = (Gesture)this.gestures.get(this.currentGesturePos);
   }

   protected CountDownTimer detectGesture(Gesture gesture) {
      this.currentGesture = gesture;
      CountDownTimer countDownTimer = null;
      String type = this.getDetectionType(this.currentGesturePos);
      if (!type.equals(Constants.DETECTION_COMPLETED)) {
         this.faceDetectionProcessor.setDetectionType(type);
         String gestureString = Constants.GSON.toJson(gesture);
         this.onEKYCEvernts.detectionEvents(DetectionEvent.STARTED, gestureString);
         countDownTimer = this.startCountTimer(gesture.getTime());
         EKYCLogger.print("EKYCMAnagerHelper", "timer object " + countDownTimer.toString() + " detect gesture " + gestureString);
         countDownTimer.start();
      }

      return countDownTimer;
   }

   private CountDownTimer startCountTimer(long totalTime) {
      EKYCLogger.print("EKYCMAnagerHelper", "Coundown " + totalTime);
      CountDownTimer timer = new CountDownTimer(totalTime, 1000L) {
         public void onTick(long millisUntilFinished) {
            EKYCLogger.print("EKYCMAnagerHelper", "timer ontick " + this);
         }

         public void onFinish() {
            String gestureString = Constants.GSON.toJson(EKYCMAnagerHelper.this.currentGesture);
            EKYCLogger.print("EKYCMAnagerHelper", "timer object : " + this + "detection failed ,time lapsed " + gestureString);
            EKYCMAnagerHelper.this.onEKYCEvernts.detectionEvents(DetectionEvent.FAILED, gestureString);
         }
      };
      return timer;
   }

   private String getDetectionType(int position) {
      String type = "completed";
      if (this.gestures.size() > 0) {
         Gesture gesture = (Gesture)this.gestures.get(position);
         type = gesture.getName();
         this.gestures.remove(position);
      }

      EKYCLogger.print("EKYCMAnagerHelper", "getDetectionType remaining " + this.gestures.size() + " pos " + position);
      return type;
   }
}
