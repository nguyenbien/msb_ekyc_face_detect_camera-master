package com.lib.ekyc.core.record;

import android.content.Context;
import android.media.CamcorderProfile;
import android.media.MediaRecorder;
import android.os.Handler;
import android.util.Log;
import android.view.Surface;
import com.lib.ekyc.core.ekyc.OnRecorderEvents;
import java.io.File;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MediaRecordManager implements MediaRecorderInterface {
   private static final String TAG = "MediaRecordManager";
   ExecutorService executorService = Executors.newSingleThreadExecutor();
   Context context = null;
   MediaRecorder mediaRecorder = null;
   Surface surface = null;
   Handler handler = new Handler();
   private String videoFilePath = "";
   private VideoGrabber videoGrabber = null;
   private boolean recordingStarted = false;

   public void initRecorder(Context context) {
      this.context = context;
   }

   public void startRecording() {
      this.mediaRecorder = new MediaRecorder();
      this.mediaRecorder.setAudioSource(1);
      this.mediaRecorder.setVideoSource(2);
      CamcorderProfile cpHigh = CamcorderProfile.get(5);
      this.mediaRecorder.setProfile(cpHigh);
      this.mediaRecorder.setOutputFile(this.createFile().getAbsolutePath());
      this.mediaRecorder.setOrientationHint(270);
      this.handler.postDelayed(() -> {
         this.prepareMediaGrabber();
         EKYCLogger.print("MediaRecordManager", "preparing recorder");
      }, 1000L);
   }

   private void startRecorderInternal() {
      EKYCLogger.print("MediaRecordManager", "startRecorderInternal");

      try {
         this.handler.postDelayed(() -> {
            this.mediaRecorder.start();
            this.recordingStarted = true;
         }, 1500L);
      } catch (Exception var2) {
         var2.printStackTrace();
      }

   }

   private void prepareMediaGrabber() {
      try {
         this.mediaRecorder.prepare();
         this.surface = this.mediaRecorder.getSurface();
         this.videoGrabber = new VideoGrabber(this.surface);
         this.startRecorderInternal();
      } catch (Exception var2) {
         var2.printStackTrace();
      }

   }

   public void stopRecording(OnRecorderEvents onRecorderEvents) {
      EKYCLogger.print("MediaRecordManager", "stopRecording");
      if (!this.recordingStarted) {
         EKYCLogger.print("MediaRecordManager", "recording not started, returning");
      } else {
         this.stopInternal(onRecorderEvents);
      }
   }

   private void stopInternal(OnRecorderEvents onRecorderEvents) {
      try {
         this.recordingStarted = false;
         this.handler.postDelayed(() -> {
            this.surface.release();
            this.mediaRecorder.stop();
            EKYCLogger.print("MediaRecordManager", "stoped");
            this.mediaRecorder.release();
            onRecorderEvents.onRecorderCleanerd();
         }, 1500L);
      } catch (Exception var3) {
         var3.printStackTrace();
      }

   }

   public void onFrame(byte[] frameData, int format, int width, int height) {
      if (!this.recordingStarted && this.videoGrabber == null) {
         EKYCLogger.print("MediaRecordManager", "recording stoped state/video grabber null");
      } else {
         this.executorService.execute(() -> {
            Log.d("MediaRecordManager", "onFrame: Frames receving");
            this.videoGrabber.drawFrameToCanvas(frameData, format, width, height);
         });
      }
   }

   private File createFile() {
      File file = null;

      try {
         String sdcardroot = this.context.getFilesDir().getAbsolutePath();
         Log.d("MediaRecordManager", "createFile: video path " + sdcardroot);
         String mFileName = System.currentTimeMillis() + ".mp4";
         file = new File(sdcardroot, mFileName);
         this.videoFilePath = file.getAbsolutePath();
      } catch (Exception var4) {
         var4.printStackTrace();
      }

      return file;
   }

   public String getVideoFilePath() {
      return this.videoFilePath;
   }
}
