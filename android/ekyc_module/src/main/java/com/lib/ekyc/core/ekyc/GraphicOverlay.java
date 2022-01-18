package com.lib.ekyc.core.ekyc;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.view.View;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class GraphicOverlay extends View {
   private final Object lock = new Object();
   private int previewWidth;
   private float widthScaleFactor = 1.0F;
   private int previewHeight;
   private float heightScaleFactor = 1.0F;
   private int facing = 0;
   private final List<GraphicOverlay.Graphic> graphics = new ArrayList();

   public GraphicOverlay(Context context, AttributeSet attrs) {
      super(context, attrs);
   }

   public void clear() {
      synchronized(this.lock) {
         this.graphics.clear();
      }

      this.postInvalidate();
   }

   public void add(GraphicOverlay.Graphic graphic) {
      synchronized(this.lock) {
         this.graphics.add(graphic);
      }
   }

   public void remove(GraphicOverlay.Graphic graphic) {
      synchronized(this.lock) {
         this.graphics.remove(graphic);
      }

      this.postInvalidate();
   }

   public void setCameraInfo(int previewWidth, int previewHeight, int facing) {
      synchronized(this.lock) {
         this.previewWidth = previewWidth;
         this.previewHeight = previewHeight;
         this.facing = facing;
      }

      this.postInvalidate();
   }

   protected void onDraw(Canvas canvas) {
      super.onDraw(canvas);
      synchronized(this.lock) {
         if (this.previewWidth != 0 && this.previewHeight != 0) {
            this.widthScaleFactor = (float)this.getWidth() / (float)this.previewWidth;
            this.heightScaleFactor = (float)this.getHeight() / (float)this.previewHeight;
         }

         Iterator var3 = this.graphics.iterator();

         while(var3.hasNext()) {
            GraphicOverlay.Graphic graphic = (GraphicOverlay.Graphic)var3.next();
            graphic.draw(canvas);
         }

      }
   }

   public abstract static class Graphic {
      private GraphicOverlay overlay;

      public Graphic(GraphicOverlay overlay) {
         this.overlay = overlay;
      }

      public abstract void draw(Canvas var1);

      public float scaleX(float horizontal) {
         return horizontal * this.overlay.widthScaleFactor;
      }

      public float scaleY(float vertical) {
         return vertical * this.overlay.heightScaleFactor;
      }

      public Context getApplicationContext() {
         return this.overlay.getContext().getApplicationContext();
      }

      public float translateX(float x) {
         return this.overlay.facing == 1 ? (float)this.overlay.getWidth() - this.scaleX(x) : this.scaleX(x);
      }

      public float translateY(float y) {
         return this.scaleY(y);
      }

      public void postInvalidate() {
         this.overlay.postInvalidate();
      }
   }
}
