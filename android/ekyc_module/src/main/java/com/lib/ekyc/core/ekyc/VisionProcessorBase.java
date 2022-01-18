package com.lib.ekyc.core.ekyc;

import android.graphics.Bitmap;
import androidx.annotation.GuardedBy;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import java.nio.ByteBuffer;

import com.google.android.odml.image.BitmapMlImageBuilder;
import com.google.android.odml.image.MlImage;
import com.google.mlkit.vision.common.InputImage;

abstract class VisionProcessorBase<T> implements VisionImageProcessor {
   @GuardedBy("this")
   private ByteBuffer latestImage;
   @GuardedBy("this")
   private FrameMetadata latestImageMetaData;
   @GuardedBy("this")
   private ByteBuffer processingImage;
   @GuardedBy("this")
   private FrameMetadata processingMetaData;

   public VisionProcessorBase() {
   }

   public synchronized void process(ByteBuffer data, FrameMetadata frameMetadata, GraphicOverlay graphicOverlay) {
      this.latestImage = data;
      this.latestImageMetaData = frameMetadata;
      if (this.processingImage == null && this.processingMetaData == null) {
         this.processLatestImage(graphicOverlay);
      }

   }

   public void process(Bitmap bitmap, GraphicOverlay graphicOverlay) {
      this.detectInVisionImage((Bitmap)null, InputImage.fromBitmap(bitmap, 0), (FrameMetadata)null, graphicOverlay);
   }

   private synchronized void processLatestImage(GraphicOverlay graphicOverlay) {
      this.processingImage = this.latestImage;
      this.processingMetaData = this.latestImageMetaData;
      this.latestImage = null;
      this.latestImageMetaData = null;
      if (this.processingImage != null && this.processingMetaData != null) {
         this.processImage(this.processingImage, this.processingMetaData, graphicOverlay);
      }

   }

   private void processImage(ByteBuffer data, FrameMetadata frameMetadata, GraphicOverlay graphicOverlay) {
      Bitmap bitmap = BitmapUtils.getBitmap(data, frameMetadata);
      this.detectInVisionImage(bitmap, InputImage.fromByteBuffer(
              data,
              frameMetadata.getWidth(),
              frameMetadata.getHeight(),
              frameMetadata.getRotation(),
              InputImage.IMAGE_FORMAT_NV21), frameMetadata, graphicOverlay);
   }

   private void detectInVisionImage(final Bitmap originalCameraImage, InputImage image, final FrameMetadata metadata, final GraphicOverlay graphicOverlay) {
      this.detectInImage(image).addOnSuccessListener(new OnSuccessListener<T>() {
         public void onSuccess(T results) {
            VisionProcessorBase.this.onSuccess(originalCameraImage, results, metadata, graphicOverlay);
            VisionProcessorBase.this.processLatestImage(graphicOverlay);
         }
      }).addOnFailureListener(new OnFailureListener() {
         public void onFailure(@NonNull Exception e) {
            VisionProcessorBase.this.onFailure(e);
         }
      });
   }

   public void stop() {
   }

   protected abstract Task<T> detectInImage(InputImage var1);

   protected abstract void onSuccess(@Nullable Bitmap var1, @NonNull T var2, @NonNull FrameMetadata var3, @NonNull GraphicOverlay var4);

   protected abstract void onFailure(@NonNull Exception var1);
}
