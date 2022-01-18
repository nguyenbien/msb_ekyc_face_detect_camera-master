package com.lib.ekyc.core.ekyc;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.util.Size;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.view.SurfaceHolder.Callback;
import java.io.IOException;

public class CameraSourcePreview extends ViewGroup {
   private static final String TAG = "MIDemoApp:Preview";
   private final Context context;
   private final SurfaceView surfaceView;
   private boolean startRequested;
   private boolean surfaceAvailable;
   private CameraSource cameraSource;
   private GraphicOverlay overlay;

   public CameraSourcePreview(Context context, AttributeSet attrs) {
      super(context, attrs);
      this.context = context;
      this.startRequested = false;
      this.surfaceAvailable = false;
      this.surfaceView = new SurfaceView(context);
      this.surfaceView.getHolder().addCallback(new CameraSourcePreview.SurfaceCallback());
      this.addView(this.surfaceView);
   }

   private void start(CameraSource cameraSource) throws IOException {
      if (cameraSource == null) {
         this.stop();
      }

      this.cameraSource = cameraSource;
      if (this.cameraSource != null) {
         this.startRequested = true;
         this.startIfReady();
      }

   }

   public void start(CameraSource cameraSource, GraphicOverlay overlay) throws IOException {
      this.overlay = overlay;
      this.start(cameraSource);
   }

   public void stop() {
      if (this.cameraSource != null) {
         this.cameraSource.stop();
      }

   }

   public void release() {
      if (this.cameraSource != null) {
         this.cameraSource.release();
         this.cameraSource = null;
      }

      this.surfaceView.getHolder().getSurface().release();
   }

   @SuppressLint({"MissingPermission"})
   private void startIfReady() throws IOException {
      if (this.startRequested && this.surfaceAvailable) {
         this.cameraSource.start(this.surfaceView.getHolder());
         this.requestLayout();
         if (this.overlay != null) {
            Size size = this.cameraSource.getPreviewSize();
            int min = Math.min(size.getWidth(), size.getHeight());
            int max = Math.max(size.getWidth(), size.getHeight());
            if (this.isPortraitMode()) {
               this.overlay.setCameraInfo(min, max, this.cameraSource.getCameraFacing());
            } else {
               this.overlay.setCameraInfo(max, min, this.cameraSource.getCameraFacing());
            }

            this.overlay.clear();
         }

         this.startRequested = false;
      }

   }

   protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
      int width = 320;
      int height = 240;
      if (this.cameraSource != null) {
         Size size = this.cameraSource.getPreviewSize();
         if (size != null) {
            width = size.getWidth();
            height = size.getHeight();
         }
      }

      int layoutWidth;
      if (this.isPortraitMode()) {
         layoutWidth = width;
         width = height;
         height = layoutWidth;
      }

      layoutWidth = right - left;
      int layoutHeight = bottom - top;
      int childWidth = layoutWidth;
      int childHeight = (int)((float)layoutWidth / (float)width * (float)height);
      if (childHeight > layoutHeight) {
         childHeight = layoutHeight;
         childWidth = (int)((float)layoutHeight / (float)height * (float)width);
      }

      for(int i = 0; i < this.getChildCount(); ++i) {
         this.getChildAt(i).layout(0, 0, childWidth, childHeight);
         Log.d("MIDemoApp:Preview", "Assigned view: " + i);
      }

      try {
         this.startIfReady();
      } catch (IOException var13) {
         Log.e("MIDemoApp:Preview", "Could not start camera source.", var13);
      }

   }

   private boolean isPortraitMode() {
      int orientation = this.context.getResources().getConfiguration().orientation;
      if (orientation == 2) {
         return false;
      } else if (orientation == 1) {
         return true;
      } else {
         Log.d("MIDemoApp:Preview", "isPortraitMode returning false by default");
         return false;
      }
   }

   private class SurfaceCallback implements Callback {
      private SurfaceCallback() {
      }

      public void surfaceCreated(SurfaceHolder surface) {
         CameraSourcePreview.this.surfaceAvailable = true;

         try {
            CameraSourcePreview.this.startIfReady();
         } catch (IOException var3) {
            Log.e("MIDemoApp:Preview", "Could not start camera source.", var3);
         }

      }

      public void surfaceDestroyed(SurfaceHolder surface) {
         CameraSourcePreview.this.surfaceAvailable = false;
      }

      public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
      }

      // $FF: synthetic method
      SurfaceCallback(Object x1) {
         this();
      }
   }
}
