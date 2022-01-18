package com.lib.ekyc.core.ekyc;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.hardware.Camera.CameraInfo;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.PreviewCallback;
import android.util.Log;
import android.util.Size;
import android.view.SurfaceHolder;
import android.view.WindowManager;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresPermission;
import com.lib.ekyc.core.record.MediaRecordManager;
import java.io.IOException;
import java.lang.Thread.State;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.IdentityHashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

@SuppressLint({"MissingPermission"})
public class CameraSource {
   @SuppressLint({"InlinedApi"})
   public static final int CAMERA_FACING_BACK = 0;
   @SuppressLint({"InlinedApi"})
   public static final int CAMERA_FACING_FRONT = 1;
   public static final int IMAGE_FORMAT = 17;
   public static final int DEFAULT_REQUESTED_CAMERA_PREVIEW_WIDTH = 640;
   public static final int DEFAULT_REQUESTED_CAMERA_PREVIEW_HEIGHT = 480;
   private static final String TAG = "MIDemoApp:CameraSource";
   private static final int DUMMY_TEXTURE_NAME = 100;
   private static final float ASPECT_RATIO_TOLERANCE = 0.01F;
   protected Activity activity;
   private Camera camera;
   private int facing = 0;
   private int rotation;
   private Size previewSize;
   private final float requestedFps = 30.0F;
   private final boolean requestedAutoFocus = true;
   private SurfaceTexture dummySurfaceTexture;
   private final GraphicOverlay graphicOverlay;
   private boolean usingSurfaceTexture;
   private Thread processingThread;
   private final CameraSource.FrameProcessingRunnable processingRunnable;
   private final Object processorLock = new Object();
   private VisionImageProcessor frameProcessor;
   private final Map<byte[], ByteBuffer> bytesToByteBuffer = new IdentityHashMap();
   MediaRecordManager mediaRecordManager = null;
   private OnRecorderEvents onRecorderEvents;

   public Camera getCamera() {
      return this.camera;
   }

   public CameraSource(Activity activity, GraphicOverlay overlay) {
      this.activity = activity;
      this.graphicOverlay = overlay;
      this.graphicOverlay.clear();
      this.processingRunnable = new CameraSource.FrameProcessingRunnable();
   }

   public void release() {
      synchronized(this.processorLock) {
         this.stop();
         this.processingRunnable.release();
         this.cleanScreen();
         if (this.frameProcessor != null) {
            this.frameProcessor.stop();
         }

      }
   }

   @SuppressLint({"MissingPermission"})
   @RequiresPermission("android.permission.CAMERA")
   public synchronized CameraSource start() throws IOException {
      if (this.camera != null) {
         return this;
      } else {
         this.camera = this.createCamera();
         this.dummySurfaceTexture = new SurfaceTexture(100);
         this.camera.setPreviewTexture(this.dummySurfaceTexture);
         this.usingSurfaceTexture = true;
         this.camera.startPreview();
         this.processingThread = new Thread(this.processingRunnable);
         this.processingRunnable.setActive(true);
         this.processingThread.start();
         return this;
      }
   }

   @RequiresPermission("android.permission.CAMERA")
   public synchronized CameraSource start(SurfaceHolder surfaceHolder) throws IOException {
      if (this.camera != null) {
         return this;
      } else {
         this.camera = this.createCamera();
         this.camera.setPreviewDisplay(surfaceHolder);
         this.camera.startPreview();
         this.mediaRecordManager = new MediaRecordManager();
         this.mediaRecordManager.initRecorder(this.activity);
         this.mediaRecordManager.startRecording();
         this.processingThread = new Thread(this.processingRunnable);
         this.processingRunnable.setActive(true);
         this.processingThread.start();
         this.usingSurfaceTexture = false;
         return this;
      }
   }

   public synchronized void stop() {
      this.processingRunnable.setActive(false);
      if (this.processingThread != null) {
         try {
            this.processingThread.join();
         } catch (InterruptedException var3) {
            Log.d("MIDemoApp:CameraSource", "Frame processing thread interrupted on release.");
         }

         this.processingThread = null;
      }

      if (this.camera != null) {
         this.camera.stopPreview();
         this.camera.setPreviewCallbackWithBuffer((PreviewCallback)null);

         try {
            if (this.usingSurfaceTexture) {
               this.camera.setPreviewTexture((SurfaceTexture)null);
            } else {
               this.camera.setPreviewDisplay((SurfaceHolder)null);
            }
         } catch (Exception var2) {
            Log.e("MIDemoApp:CameraSource", "Failed to clear camera preview: " + var2);
         }

         this.camera.release();
         this.camera = null;
         if (this.mediaRecordManager != null) {
            this.mediaRecordManager.stopRecording(this.onRecorderEvents);
         }
      }

      this.bytesToByteBuffer.clear();
   }

   public void setOnRecorderEvents(OnRecorderEvents onRecorderEvents) {
      this.onRecorderEvents = onRecorderEvents;
   }

   public synchronized void setFacing(int facing) {
      if (facing != 0 && facing != 1) {
         throw new IllegalArgumentException("Invalid camera: " + facing);
      } else {
         this.facing = facing;
      }
   }

   public Size getPreviewSize() {
      return this.previewSize;
   }

   public int getCameraFacing() {
      return this.facing;
   }

   @SuppressLint({"InlinedApi"})
   private Camera createCamera() throws IOException {
      int requestedCameraId = getIdForRequestedCamera(this.facing);
      if (requestedCameraId == -1) {
         throw new IOException("Could not find requested camera.");
      } else {
         Camera camera = Camera.open(requestedCameraId);
         CameraSource.SizePair sizePair = null;
         if (sizePair == null) {
            sizePair = selectSizePair(camera, 640, 480);
         }

         if (sizePair == null) {
            throw new IOException("Could not find suitable preview size.");
         } else {
            this.previewSize = sizePair.preview;
            Log.v("MIDemoApp:CameraSource", "Camera preview size: " + this.previewSize);
            int[] previewFpsRange = selectPreviewFpsRange(camera, 30.0F);
            if (previewFpsRange == null) {
               throw new IOException("Could not find suitable preview frames per second range.");
            } else {
               Parameters parameters = camera.getParameters();
               Size pictureSize = sizePair.picture;
               if (pictureSize != null) {
                  Log.v("MIDemoApp:CameraSource", "Camera picture size: " + pictureSize);
                  parameters.setPictureSize(pictureSize.getWidth(), pictureSize.getHeight());
               }

               parameters.setPreviewSize(this.previewSize.getWidth(), this.previewSize.getHeight());
               parameters.setPreviewFpsRange(previewFpsRange[0], previewFpsRange[1]);
               parameters.setPreviewFormat(17);
               this.setRotation(camera, parameters, requestedCameraId);
               if (parameters.getSupportedFocusModes().contains("continuous-video")) {
                  parameters.setFocusMode("continuous-video");
               } else {
                  Log.i("MIDemoApp:CameraSource", "Camera auto focus is not supported on this device.");
               }

               camera.setParameters(parameters);
               camera.setPreviewCallbackWithBuffer(new CameraSource.CameraPreviewCallback());
               camera.addCallbackBuffer(this.createPreviewBuffer(this.previewSize));
               camera.addCallbackBuffer(this.createPreviewBuffer(this.previewSize));
               camera.addCallbackBuffer(this.createPreviewBuffer(this.previewSize));
               camera.addCallbackBuffer(this.createPreviewBuffer(this.previewSize));
               return camera;
            }
         }
      }
   }

   private static int getIdForRequestedCamera(int facing) {
      CameraInfo cameraInfo = new CameraInfo();

      for(int i = 0; i < Camera.getNumberOfCameras(); ++i) {
         Camera.getCameraInfo(i, cameraInfo);
         if (cameraInfo.facing == facing) {
            return i;
         }
      }

      return -1;
   }

   public static CameraSource.SizePair selectSizePair(Camera camera, int desiredWidth, int desiredHeight) {
      List<CameraSource.SizePair> validPreviewSizes = generateValidPreviewSizeList(camera);
      CameraSource.SizePair selectedPair = null;
      int minDiff = Integer.MAX_VALUE;
      Iterator var6 = validPreviewSizes.iterator();

      while(var6.hasNext()) {
         CameraSource.SizePair sizePair = (CameraSource.SizePair)var6.next();
         Size size = sizePair.preview;
         int diff = Math.abs(size.getWidth() - desiredWidth) + Math.abs(size.getHeight() - desiredHeight);
         if (diff < minDiff) {
            selectedPair = sizePair;
            minDiff = diff;
         }
      }

      return selectedPair;
   }

   public String getVideoFilePath() {
      String path = "";
      if (this.mediaRecordManager != null) {
         path = this.mediaRecordManager.getVideoFilePath();
      }

      return path;
   }

   public static List<CameraSource.SizePair> generateValidPreviewSizeList(Camera camera) {
      Parameters parameters = camera.getParameters();
      List<android.hardware.Camera.Size> supportedPreviewSizes = parameters.getSupportedPreviewSizes();
      List<android.hardware.Camera.Size> supportedPictureSizes = parameters.getSupportedPictureSizes();
      List<CameraSource.SizePair> validPreviewSizes = new ArrayList();
      Iterator var5 = supportedPreviewSizes.iterator();

      while(true) {
         android.hardware.Camera.Size previewSize;
         while(var5.hasNext()) {
            previewSize = (android.hardware.Camera.Size)var5.next();
            float previewAspectRatio = (float)previewSize.width / (float)previewSize.height;
            Iterator var8 = supportedPictureSizes.iterator();

            while(var8.hasNext()) {
               android.hardware.Camera.Size pictureSize = (android.hardware.Camera.Size)var8.next();
               float pictureAspectRatio = (float)pictureSize.width / (float)pictureSize.height;
               if (Math.abs(previewAspectRatio - pictureAspectRatio) < 0.01F) {
                  validPreviewSizes.add(new CameraSource.SizePair(previewSize, pictureSize));
                  break;
               }
            }
         }

         if (validPreviewSizes.size() == 0) {
            Log.w("MIDemoApp:CameraSource", "No preview sizes have a corresponding same-aspect-ratio picture size");
            var5 = supportedPreviewSizes.iterator();

            while(var5.hasNext()) {
               previewSize = (android.hardware.Camera.Size)var5.next();
               validPreviewSizes.add(new CameraSource.SizePair(previewSize, (android.hardware.Camera.Size)null));
            }
         }

         return validPreviewSizes;
      }
   }

   @SuppressLint({"InlinedApi"})
   private static int[] selectPreviewFpsRange(Camera camera, float desiredPreviewFps) {
      int desiredPreviewFpsScaled = (int)(desiredPreviewFps * 1000.0F);
      int[] selectedFpsRange = null;
      int minDiff = Integer.MAX_VALUE;
      List<int[]> previewFpsRangeList = camera.getParameters().getSupportedPreviewFpsRange();
      Iterator var6 = previewFpsRangeList.iterator();

      while(var6.hasNext()) {
         int[] range = (int[])var6.next();
         int deltaMin = desiredPreviewFpsScaled - range[0];
         int deltaMax = desiredPreviewFpsScaled - range[1];
         int diff = Math.abs(deltaMin) + Math.abs(deltaMax);
         if (diff < minDiff) {
            selectedFpsRange = range;
            minDiff = diff;
         }
      }

      return selectedFpsRange;
   }

   private void setRotation(Camera camera, Parameters parameters, int cameraId) {
      WindowManager windowManager = (WindowManager)this.activity.getSystemService("window");
      int degrees = 0;
      int rotation = windowManager.getDefaultDisplay().getRotation();
      switch(rotation) {
      case 0:
         degrees = 0;
         break;
      case 1:
         degrees = 90;
         break;
      case 2:
         degrees = 180;
         break;
      case 3:
         degrees = 270;
         break;
      default:
         Log.e("MIDemoApp:CameraSource", "Bad rotation value: " + rotation);
      }

      CameraInfo cameraInfo = new CameraInfo();
      Camera.getCameraInfo(cameraId, cameraInfo);
      int angle;
      int displayAngle;
      if (cameraInfo.facing == 1) {
         angle = (cameraInfo.orientation + degrees) % 360;
         displayAngle = (360 - angle) % 360;
      } else {
         angle = (cameraInfo.orientation - degrees + 360) % 360;
         displayAngle = angle;
      }

      this.rotation = angle / 90;
      Log.d("MIDemoApp:CameraSource", "Display rotation is: " + rotation);
      Log.d("MIDemoApp:CameraSource", "Camera face is: " + cameraInfo.facing);
      Log.d("MIDemoApp:CameraSource", "Camera rotation is: " + cameraInfo.orientation);
      Log.d("MIDemoApp:CameraSource", "Rotation is: " + this.rotation);
      camera.setDisplayOrientation(displayAngle);
      parameters.setRotation(angle);
   }

   @SuppressLint({"InlinedApi"})
   private byte[] createPreviewBuffer(Size previewSize) {
      int bitsPerPixel = ImageFormat.getBitsPerPixel(17);
      long sizeInBits = (long)previewSize.getHeight() * (long)previewSize.getWidth() * (long)bitsPerPixel;
      int bufferSize = (int)Math.ceil((double)sizeInBits / 8.0D) + 1;
      byte[] byteArray = new byte[bufferSize];
      ByteBuffer buffer = ByteBuffer.wrap(byteArray);
      if (buffer.hasArray() && buffer.array() == byteArray) {
         this.bytesToByteBuffer.put(byteArray, buffer);
         return byteArray;
      } else {
         throw new IllegalStateException("Failed to create valid buffer for camera source.");
      }
   }

   public void setMachineLearningFrameProcessor(VisionImageProcessor processor) {
      synchronized(this.processorLock) {
         this.cleanScreen();
         if (this.frameProcessor != null) {
            this.frameProcessor.stop();
         }

         this.frameProcessor = processor;
      }
   }

   private void cleanScreen() {
      this.graphicOverlay.clear();
   }

   private class FrameProcessingRunnable implements Runnable {
      private final Object lock = new Object();
      private boolean active = true;
      private ByteBuffer pendingFrameData;

      FrameProcessingRunnable() {
      }

      @SuppressLint({"Assert"})
      void release() {
         assert CameraSource.this.processingThread == null || CameraSource.this.processingThread.getState() == State.TERMINATED;
      }

      void setActive(boolean active) {
         synchronized(this.lock) {
            this.active = active;
            this.lock.notifyAll();
         }
      }

      void setNextFrame(byte[] data, Camera camera) {
         synchronized(this.lock) {
            if (this.pendingFrameData != null) {
               camera.addCallbackBuffer(this.pendingFrameData.array());
               this.pendingFrameData = null;
            }

            if (!CameraSource.this.bytesToByteBuffer.containsKey(data)) {
               Log.d("MIDemoApp:CameraSource", "Skipping frame. Could not find ByteBuffer associated with the image data from the camera.");
            } else {
               this.pendingFrameData = (ByteBuffer)CameraSource.this.bytesToByteBuffer.get(data);
               this.lock.notifyAll();
            }
         }
      }

      @SuppressLint({"InlinedApi"})
      public void run() {
         while(true) {
            ByteBuffer data;
            synchronized(this.lock) {
               while(this.active && this.pendingFrameData == null) {
                  try {
                     this.lock.wait();
                  } catch (InterruptedException var15) {
                     Log.d("MIDemoApp:CameraSource", "Frame processing loop terminated.", var15);
                     return;
                  }
               }

               if (!this.active) {
                  return;
               }

               data = this.pendingFrameData;
               this.pendingFrameData = null;
            }

            try {
               synchronized(CameraSource.this.processorLock) {
                  Log.d("MIDemoApp:CameraSource", "Process an image");
                  CameraSource.this.frameProcessor.process(data, (new FrameMetadata.Builder()).setWidth(CameraSource.this.previewSize.getWidth()).setHeight(CameraSource.this.previewSize.getHeight()).setRotation(CameraSource.this.rotation).setCameraFacing(CameraSource.this.facing).build(), CameraSource.this.graphicOverlay);
               }
            } catch (Exception var13) {
               Log.e("MIDemoApp:CameraSource", "Exception thrown from receiver.", var13);
            } finally {
               CameraSource.this.camera.addCallbackBuffer(data.array());
            }
         }
      }
   }

   private class CameraPreviewCallback implements PreviewCallback {
      private CameraPreviewCallback() {
      }

      public void onPreviewFrame(byte[] data, Camera camera) {
         CameraSource.this.processingRunnable.setNextFrame(data, camera);
         if (CameraSource.this.mediaRecordManager != null) {
            CameraSource.this.mediaRecordManager.onFrame(data, 17, CameraSource.this.previewSize.getWidth(), CameraSource.this.previewSize.getHeight());
         }

      }

      // $FF: synthetic method
      CameraPreviewCallback(Object x1) {
         this();
      }
   }

   public static class SizePair {
      public final Size preview;
      @Nullable
      public final Size picture;

      SizePair(android.hardware.Camera.Size previewSize, @Nullable android.hardware.Camera.Size pictureSize) {
         this.preview = new Size(previewSize.width, previewSize.height);
         this.picture = pictureSize != null ? new Size(pictureSize.width, pictureSize.height) : null;
      }

      public SizePair(Size previewSize, @Nullable Size pictureSize) {
         this.preview = previewSize;
         this.picture = pictureSize;
      }
   }
}
