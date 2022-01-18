package com.lib.ekyc.core.ekyc;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.util.Log;
import androidx.annotation.Nullable;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;

class BitmapUtils {
   @Nullable
   public static Bitmap getBitmap(ByteBuffer data, FrameMetadata metadata) {
      data.rewind();
      byte[] imageInBuffer = new byte[data.limit()];
      data.get(imageInBuffer, 0, imageInBuffer.length);

      try {
         YuvImage image = new YuvImage(imageInBuffer, 17, metadata.getWidth(), metadata.getHeight(), (int[])null);
         if (image != null) {
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            image.compressToJpeg(new Rect(0, 0, metadata.getWidth(), metadata.getHeight()), 80, stream);
            Bitmap bmp = BitmapFactory.decodeByteArray(stream.toByteArray(), 0, stream.size());
            stream.close();
            return rotateBitmap(bmp, metadata.getRotation(), metadata.getCameraFacing());
         }
      } catch (Exception var6) {
         Log.e("VisionProcessorBase", "Error: " + var6.getMessage());
      }

      return null;
   }

   private static Bitmap rotateBitmap(Bitmap bitmap, int rotation, int facing) {
      Matrix matrix = new Matrix();
      int rotationDegree = 0;
      switch(rotation) {
      case 1:
         rotationDegree = 90;
         break;
      case 2:
         rotationDegree = 180;
         break;
      case 3:
         rotationDegree = 270;
      }

      matrix.postRotate((float)rotationDegree);
      if (facing == 0) {
         return Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
      } else {
         matrix.postScale(-1.0F, 1.0F);
         return Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
      }
   }
}
