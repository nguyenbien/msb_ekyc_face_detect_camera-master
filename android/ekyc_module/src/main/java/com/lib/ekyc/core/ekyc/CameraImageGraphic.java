package com.lib.ekyc.core.ekyc;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;

class CameraImageGraphic extends GraphicOverlay.Graphic {
   private final Bitmap bitmap;

   public CameraImageGraphic(GraphicOverlay overlay, Bitmap bitmap) {
      super(overlay);
      this.bitmap = bitmap;
   }

   public void draw(Canvas canvas) {
      canvas.drawBitmap(this.bitmap, (Rect)null, new Rect(0, 0, canvas.getWidth(), canvas.getHeight()), (Paint)null);
   }
}
