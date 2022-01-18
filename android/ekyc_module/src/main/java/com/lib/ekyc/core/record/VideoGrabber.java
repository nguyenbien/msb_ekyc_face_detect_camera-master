package com.lib.ekyc.core.record;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.graphics.PorterDuff.Mode;
import android.util.Log;
import android.view.Surface;
import java.io.ByteArrayOutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class VideoGrabber {
   private static final String TAG = "VideoGrabber";
   private Surface surface;
   private Bitmap mCacheBitmap;
   protected float mScale = 0.0F;
   private final Matrix mMatrix = new Matrix();
   ExecutorService executorService = Executors.newSingleThreadExecutor();

   public VideoGrabber(Surface surface) {
      this.surface = surface;
   }

   protected void drawFrameToCanvas(byte[] data, int format, int width, int height) {
      EKYCLogger.print("VideoGrabber", "drawFrameToCanvas: video width x height  " + width + "x" + height);
      Bitmap bitmap = this.convertToBitmap(data, format, width, height);
      this.drawOnSurface(bitmap, this.surface);
   }

   protected void release() {
   }

   private Bitmap convertToBitmap(byte[] data, int format, int width, int height) {
      YuvImage yuvImage = new YuvImage(data, format, width, height, (int[])null);
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      yuvImage.compressToJpeg(new Rect(0, 0, width, height), 50, out);
      byte[] imageBytes = out.toByteArray();
      Bitmap image = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
      Matrix matrix = new Matrix();
      matrix.preScale(1.0F, -1.0F);
      Bitmap newImage = Bitmap.createBitmap(image, 0, 0, image.getWidth(), image.getHeight(), matrix, true);
      return newImage;
   }

   private void drawOnSurface(Bitmap mCacheBitmap, Surface surface) {
      synchronized(this) {
         if (surface != null && surface.isValid() && mCacheBitmap != null) {
            Canvas canvas = null;

            try {
               canvas = surface.lockCanvas((Rect)null);
               if (canvas != null) {
                  canvas.drawColor(0, Mode.CLEAR);
                  Log.d("VideoGrabber", "mStretch value: " + this.mScale);
                  canvas.drawBitmap(mCacheBitmap, new Rect(0, 0, mCacheBitmap.getWidth(), mCacheBitmap.getHeight()), new Rect((canvas.getWidth() - mCacheBitmap.getWidth()) / 2, (canvas.getHeight() - mCacheBitmap.getHeight()) / 2, (canvas.getWidth() - mCacheBitmap.getWidth()) / 2 + mCacheBitmap.getWidth(), (canvas.getHeight() - mCacheBitmap.getHeight()) / 2 + mCacheBitmap.getHeight()), (Paint)null);
               }
            } catch (Exception var16) {
               Log.e("surfaceRender", var16.toString());
            } finally {
               try {
                  if (canvas != null) {
                     surface.unlockCanvasAndPost(canvas);
                  }
               } catch (Exception var15) {
                  var15.printStackTrace();
               }

            }

         }
      }
   }
}
